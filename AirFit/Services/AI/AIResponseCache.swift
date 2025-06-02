import Foundation
import CryptoKit

/// High-performance AI response cache with intelligent invalidation
actor AIResponseCache {
    // MARK: - Properties
    private var memoryCache: [String: CacheEntry] = [:]
    private var diskCachePath: URL
    private let maxMemoryCacheSize = 100
    private let maxDiskCacheSize = 1000
    private let defaultTTL: TimeInterval = 3600 // 1 hour
    
    // Cache statistics
    private var hitCount = 0
    private var missCount = 0
    private var evictionCount = 0
    
    struct CacheEntry {
        let key: String
        let response: Data
        let metadata: CacheMetadata
        let timestamp: Date
        let accessCount: Int
        
        var isExpired: Bool {
            Date().timeIntervalSince(timestamp) > metadata.ttl
        }
        
        var size: Int {
            response.count + MemoryLayout<CacheMetadata>.size
        }
    }
    
    struct CacheMetadata: Codable {
        let model: String
        let temperature: Double
        let tokenCount: Int
        let ttl: TimeInterval
        let tags: Set<String>
    }
    
    // MARK: - Initialization
    
    init() {
        // Setup disk cache directory
        let cacheDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        self.diskCachePath = cacheDir.appendingPathComponent("AIResponseCache")
        
        // Create directory if needed
        try? FileManager.default.createDirectory(at: diskCachePath, withIntermediateDirectories: true)
        
        // Load disk cache metadata
        Task {
            await loadDiskCacheMetadata()
        }
    }
    
    // MARK: - Public API
    
    /// Get cached response if available
    func get(request: LLMRequest) async -> LLMResponse? {
        let key = generateCacheKey(for: request)
        
        // Check memory cache first
        if let entry = memoryCache[key], !entry.isExpired {
            hitCount += 1
            
            // Update access count for LRU
            memoryCache[key] = CacheEntry(
                key: entry.key,
                response: entry.response,
                metadata: entry.metadata,
                timestamp: entry.timestamp,
                accessCount: entry.accessCount + 1
            )
            
            return try? decodeLLMResponse(from: entry.response)
        }
        
        // Check disk cache
        if let diskEntry = await loadFromDisk(key: key), !diskEntry.isExpired {
            hitCount += 1
            
            // Promote to memory cache
            await addToMemoryCache(diskEntry)
            
            return try? decodeLLMResponse(from: diskEntry.response)
        }
        
        missCount += 1
        return nil
    }
    
    /// Store response in cache
    func set(request: LLMRequest, response: LLMResponse, ttl: TimeInterval? = nil) async {
        let key = generateCacheKey(for: request)
        
        guard let responseData = try? encodeLLMResponse(response) else { return }
        
        let metadata = CacheMetadata(
            model: request.model,
            temperature: request.temperature,
            tokenCount: response.usage.totalTokens,
            ttl: ttl ?? defaultTTL,
            tags: extractTags(from: request)
        )
        
        let entry = CacheEntry(
            key: key,
            response: responseData,
            metadata: metadata,
            timestamp: Date(),
            accessCount: 0
        )
        
        // Add to memory cache
        await addToMemoryCache(entry)
        
        // Write to disk asynchronously
        Task.detached {
            await self.saveToDisk(entry: entry)
        }
        
        AppLogger.debug("Cached AI response: \(key) (size: \(entry.size) bytes)", category: .ai)
    }
    
    /// Invalidate cache entries by tag
    func invalidate(tag: String) async {
        var keysToRemove: [String] = []
        
        // Find entries with matching tag
        for (key, entry) in memoryCache {
            if entry.metadata.tags.contains(tag) {
                keysToRemove.append(key)
            }
        }
        
        // Remove from memory
        for key in keysToRemove {
            memoryCache.removeValue(forKey: key)
            await removeFromDisk(key: key)
        }
        
        AppLogger.info("Invalidated \(keysToRemove.count) cache entries with tag: \(tag)", category: .ai)
    }
    
    /// Clear entire cache
    func clear() async {
        memoryCache.removeAll()
        try? FileManager.default.removeItem(at: diskCachePath)
        try? FileManager.default.createDirectory(at: diskCachePath, withIntermediateDirectories: true)
        
        hitCount = 0
        missCount = 0
        evictionCount = 0
        
        AppLogger.info("Cleared AI response cache", category: .ai)
    }
    
    /// Get cache statistics
    func getStatistics() -> CacheStatistics {
        let hitRate = hitCount + missCount > 0 
            ? Double(hitCount) / Double(hitCount + missCount) 
            : 0
        
        let memorySize = memoryCache.values.reduce(0) { $0 + $1.size }
        
        return CacheStatistics(
            hitCount: hitCount,
            missCount: missCount,
            hitRate: hitRate,
            evictionCount: evictionCount,
            memoryEntries: memoryCache.count,
            memorySizeBytes: memorySize
        )
    }
    
    // MARK: - Private Methods
    
    private func generateCacheKey(for request: LLMRequest) -> String {
        // Create deterministic key from request parameters
        var hasher = SHA256()
        
        // Include all relevant parameters
        let keyComponents = [
            request.model,
            String(request.temperature),
            request.systemPrompt ?? "",
            request.messages.map { "\($0.role.rawValue):\($0.content)" }.joined(separator: "|")
        ]
        
        let keyString = keyComponents.joined(separator: "##")
        hasher.update(data: keyString.data(using: .utf8)!)
        
        let digest = hasher.finalize()
        return digest.map { String(format: "%02x", $0) }.joined()
    }
    
    private func extractTags(from request: LLMRequest) -> Set<String> {
        var tags: Set<String> = []
        
        // Add model as tag
        tags.insert("model:\(request.model)")
        
        // Add task type from metadata
        if let task = request.metadata["task"] as? String {
            tags.insert("task:\(task)")
        }
        
        // Add temperature range
        if request.temperature < 0.3 {
            tags.insert("temp:low")
        } else if request.temperature > 0.7 {
            tags.insert("temp:high")
        } else {
            tags.insert("temp:medium")
        }
        
        return tags
    }
    
    private func addToMemoryCache(_ entry: CacheEntry) async {
        // Evict if at capacity (LRU)
        if memoryCache.count >= maxMemoryCacheSize {
            await evictLRUEntry()
        }
        
        memoryCache[entry.key] = entry
    }
    
    private func evictLRUEntry() async {
        guard let lruEntry = memoryCache.values.min(by: { 
            $0.accessCount < $1.accessCount || 
            ($0.accessCount == $1.accessCount && $0.timestamp < $1.timestamp)
        }) else { return }
        
        memoryCache.removeValue(forKey: lruEntry.key)
        evictionCount += 1
    }
    
    // MARK: - Disk Cache Methods
    
    private func saveToDisk(entry: CacheEntry) async {
        let fileURL = diskCachePath.appendingPathComponent(entry.key)
        
        do {
            let container = DiskCacheContainer(
                response: entry.response,
                metadata: entry.metadata,
                timestamp: entry.timestamp
            )
            
            let data = try JSONEncoder().encode(container)
            try data.write(to: fileURL)
        } catch {
            AppLogger.error("Failed to save cache to disk", error: error, category: .ai)
        }
    }
    
    private func loadFromDisk(key: String) async -> CacheEntry? {
        let fileURL = diskCachePath.appendingPathComponent(key)
        
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return nil }
        
        do {
            let data = try Data(contentsOf: fileURL)
            let container = try JSONDecoder().decode(DiskCacheContainer.self, from: data)
            
            return CacheEntry(
                key: key,
                response: container.response,
                metadata: container.metadata,
                timestamp: container.timestamp,
                accessCount: 0
            )
        } catch {
            AppLogger.error("Failed to load cache from disk", error: error, category: .ai)
            return nil
        }
    }
    
    private func removeFromDisk(key: String) async {
        let fileURL = diskCachePath.appendingPathComponent(key)
        try? FileManager.default.removeItem(at: fileURL)
    }
    
    private func loadDiskCacheMetadata() async {
        // Clean up expired entries on startup
        guard let files = try? FileManager.default.contentsOfDirectory(
            at: diskCachePath,
            includingPropertiesForKeys: [.creationDateKey]
        ) else { return }
        
        for file in files {
            if let entry = await loadFromDisk(key: file.lastPathComponent),
               entry.isExpired {
                await removeFromDisk(key: file.lastPathComponent)
            }
        }
    }
    
    // MARK: - Encoding/Decoding
    
    private func encodeLLMResponse(_ response: LLMResponse) throws -> Data {
        let encoder = JSONEncoder()
        return try encoder.encode(response)
    }
    
    private func decodeLLMResponse(from data: Data) throws -> LLMResponse {
        let decoder = JSONDecoder()
        return try decoder.decode(LLMResponse.self, from: data)
    }
}

// MARK: - Supporting Types

struct CacheStatistics {
    let hitCount: Int
    let missCount: Int
    let hitRate: Double
    let evictionCount: Int
    let memoryEntries: Int
    let memorySizeBytes: Int
}

struct DiskCacheContainer: Codable {
    let response: Data
    let metadata: AIResponseCache.CacheMetadata
    let timestamp: Date
}

// MARK: - LLMResponse Codable Extension

extension LLMResponse: Codable {
    enum CodingKeys: String, CodingKey {
        case content
        case model
        case usage
        case finishReason
        case metadata
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        content = try container.decode(String.self, forKey: .content)
        model = try container.decode(String.self, forKey: .model)
        usage = try container.decode(TokenUsage.self, forKey: .usage)
        finishReason = try container.decode(FinishReason.self, forKey: .finishReason)
        
        // Decode metadata as [String: String] for simplicity
        if let metadataDict = try? container.decode([String: String].self, forKey: .metadata) {
            metadata = metadataDict.reduce(into: [:]) { $0[$1.key] = $1.value }
        } else {
            metadata = [:]
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(content, forKey: .content)
        try container.encode(model, forKey: .model)
        try container.encode(usage, forKey: .usage)
        try container.encode(finishReason, forKey: .finishReason)
        
        // Encode metadata as [String: String]
        let stringMetadata = metadata.reduce(into: [:]) { result, pair in
            if let stringValue = pair.value as? String {
                result[pair.key] = stringValue
            } else {
                result[pair.key] = String(describing: pair.value)
            }
        }
        try container.encode(stringMetadata, forKey: .metadata)
    }
}