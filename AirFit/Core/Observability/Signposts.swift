import os

enum ObsCategories {
    static let ai = OSLog(subsystem: "com.airfit", category: "ai")
    static let context = OSLog(subsystem: "com.airfit", category: "context")
    static let streaming = OSLog(subsystem: "com.airfit", category: "streaming")
}

enum SignpostNames {
    // End-to-end coaching pipeline stages
    static let pipeline = "coach.pipeline"
    static let parse = "coach.parse"
    static let assembleContext = "coach.context"
    static let infer = "coach.infer"
    static let act = "coach.act"

    // Streaming
    static let streamStart = "stream.start"
    static let streamFirstToken = "stream.first_token"
    static let streamDelta = "stream.delta"
    static let streamComplete = "stream.complete"
}

@inline(__always)
func spBegin(_ log: OSLog, _ name: StaticString, _ id: inout OSSignpostID) {
    id = OSSignpostID(log: log)
    os_signpost(.begin, log: log, name: name, signpostID: id)
}

@inline(__always)
func spEnd(_ log: OSLog, _ name: StaticString, _ id: OSSignpostID) {
    os_signpost(.end, log: log, name: name, signpostID: id)
}

