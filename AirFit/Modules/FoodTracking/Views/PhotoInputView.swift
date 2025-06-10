@preconcurrency import AVFoundation
import SwiftUI
import SwiftData
import Vision
import Photos
import UIKit

/// Photo capture interface for intelligent meal recognition and food analysis.
struct PhotoInputView: View {
    @State var viewModel: FoodTrackingViewModel
    @Environment(\.dismiss) private var dismiss
    
    @StateObject private var cameraManager = CameraManager()
    @State private var showingImagePicker = false
    @State private var showingPermissionAlert = false
    @State private var capturedImage: UIImage?
    @State private var isAnalyzing = false
    @State private var analysisProgress: Double = 0
    @State private var showingTips = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Camera preview or placeholder
                cameraPreviewLayer
                
                // Overlay UI
                VStack {
                    // Top controls
                    topControls
                    
                    Spacer()
                    
                    // Bottom controls
                    bottomControls
                }
                .padding()
                
                // Analysis overlay
                if isAnalyzing {
                    analysisOverlay
                }
            }
            .background(Color.black)
            .navigationTitle("Photo Capture")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(.white)
                }
                
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { showingTips = true }) {
                        Image(systemName: "questionmark.circle")
                            .foregroundStyle(.white)
                    }
                }
            }
            .onAppear {
                setupCamera()
            }
            .onDisappear {
                cameraManager.stopSession()
            }
            .alert("Camera Permission Required", isPresented: $showingPermissionAlert) {
                Button("Settings") { openSettings() }
                Button("Cancel", role: .cancel) { dismiss() }
            } message: {
                Text("Please enable camera access in Settings to capture meal photos.")
            }
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(image: $capturedImage, sourceType: .photoLibrary)
            }
            .sheet(isPresented: $showingTips) {
                PhotoTipsView()
            }
            .onChange(of: capturedImage) { _, newImage in
                if let image = newImage {
                    analyzePhoto(image)
                }
            }
        }
    }
    
    // MARK: - Camera Preview
    private var cameraPreviewLayer: some View {
        Group {
            if cameraManager.isAuthorized {
                CameraPreview(session: cameraManager.session)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(AppColors.accent, lineWidth: 2)
                    )
                    .overlay(alignment: .center) {
                        // Focus indicator
                        if cameraManager.isFocusing {
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(AppColors.accent, lineWidth: 2)
                                .frame(width: 80, height: 80)
                                .scaleEffect(cameraManager.focusScale)
                                .animation(.easeOut(duration: 0.3), value: cameraManager.focusScale)
                        }
                    }
                    .accessibilityLabel("Camera preview")
                    .accessibilityHint("Live camera feed for food photo capture")
                    .accessibilityIdentifier("camera_preview")
            } else {
                CameraPlaceholder {
                    requestCameraPermission()
                }
            }
        }
    }
    
    // MARK: - Top Controls
    private var topControls: some View {
        HStack {
            // Flash toggle
            Button(action: cameraManager.toggleFlash) {
                Image(systemName: cameraManager.flashMode == .on ? "bolt.fill" : "bolt.slash.fill")
                    .font(.title2)
                    .foregroundStyle(.white)
                    .padding(12)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
                    .accessibilityLabel("Flash toggle")
                    .accessibilityValue(cameraManager.flashMode == .on ? "Flash on" : "Flash off")
                    .accessibilityHint("Tap to toggle camera flash")
                    .accessibilityIdentifier("flash_button")
            }
            
            Spacer()
            
            // Camera position toggle
            Button(action: cameraManager.switchCamera) {
                Image(systemName: "camera.rotate")
                    .font(.title2)
                    .foregroundStyle(.white)
                    .padding(12)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
                    .accessibilityLabel("Switch camera")
                    .accessibilityHint("Tap to switch between front and back camera")
                    .accessibilityIdentifier("camera_switch_button")
            }
        }
    }
    
    // MARK: - Bottom Controls
    private var bottomControls: some View {
        HStack(spacing: 40) {
            // Photo library
            Button(action: { showingImagePicker = true }) {
                Image(systemName: "photo.on.rectangle")
                    .font(.title2)
                    .foregroundStyle(.white)
                    .frame(width: 60, height: 60)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
                    .accessibilityLabel("Photo gallery")
                    .accessibilityHint("Tap to select a photo from your gallery")
                    .accessibilityIdentifier("gallery_button")
            }
            
            // Capture button
            Button(action: capturePhoto) {
                ZStack {
                    Circle()
                        .fill(.white)
                        .frame(width: 80, height: 80)
                    
                    Circle()
                        .stroke(.black, lineWidth: 4)
                        .frame(width: 70, height: 70)
                }
                .accessibilityLabel("Capture photo")
                .accessibilityHint("Tap to take a photo of your food")
                .accessibilityIdentifier("capture_button")
            }
            .disabled(!cameraManager.isAuthorized || isAnalyzing)
            .scaleEffect(cameraManager.isCapturing ? 0.9 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: cameraManager.isCapturing)
            
            // AI analysis toggle
            Button(action: toggleAIAnalysis) {
                Image(systemName: cameraManager.aiAnalysisEnabled ? "brain.head.profile" : "brain.head.profile.fill")
                    .font(.title2)
                    .foregroundStyle(cameraManager.aiAnalysisEnabled ? AppColors.accent : .white)
                    .frame(width: 60, height: 60)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
                .accessibilityLabel("AI analysis toggle")
            }
        }
    }
    
    // MARK: - Analysis Overlay
    private var analysisOverlay: some View {
        ZStack {
            Color.black.opacity(0.7)
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                // AI brain animation
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 60))
                    .foregroundStyle(AppColors.accent)
                    .symbolEffect(.pulse, isActive: isAnalyzing)
                
                VStack(spacing: 12) {
                    Text("Analyzing Your Meal")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                    
                    Text("Identifying food items and estimating nutrition...")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                // Progress indicator
                ProgressView(value: analysisProgress)
                    .progressViewStyle(LinearProgressViewStyle(tint: AppColors.accent))
                    .frame(width: 200)
                
                Text("\(Int(analysisProgress * 100))%")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .accessibilityLabel("AI analysis progress")
                    .accessibilityValue("Analyzing photo: \(Int(analysisProgress * 100)) percent complete")
                    .accessibilityIdentifier("analysis_progress")
            }
            .padding(32)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 20))
        }
    }
    
    // MARK: - Actions
    private func setupCamera() {
        Task {
            await cameraManager.requestPermission()
            if cameraManager.isAuthorized {
                await cameraManager.startSession()
            } else {
                showingPermissionAlert = true
            }
        }
    }
    
    private func requestCameraPermission() {
        Task {
            await cameraManager.requestPermission()
            if !cameraManager.isAuthorized {
                showingPermissionAlert = true
            }
        }
    }
    
    private func capturePhoto() {
        Task {
            if let image = await cameraManager.capturePhoto() {
                capturedImage = image
                // TODO: Add haptic feedback via DI when needed
            }
        }
    }
    
    private func toggleAIAnalysis() {
        cameraManager.aiAnalysisEnabled.toggle()
        // TODO: Add haptic feedback via DI when needed
    }
    
    private func analyzePhoto(_ image: UIImage) {
        guard !isAnalyzing else { return }
        
        isAnalyzing = true
        analysisProgress = 0
        
        Task {
            do {
                // Simulate progress updates
                await updateProgress(to: 0.2, message: "Processing image...")
                
                // Vision framework analysis
                let visionResults = try await performVisionAnalysis(on: image)
                await updateProgress(to: 0.5, message: "Detecting food items...")
                
                // AI-powered food analysis
                let foodItems = try await performAIFoodAnalysis(image: image, visionResults: visionResults)
                await updateProgress(to: 0.9, message: "Calculating nutrition...")
                
                // Final processing
                await updateProgress(to: 1.0, message: "Complete!")
                
                // Process results
                await MainActor.run {
                    Task {
                        await viewModel.processPhotoResult(image)
                    }
                    dismiss()
                }
                
            } catch {
                await MainActor.run {
                    AppLogger.error("Photo analysis failed", error: error, category: .ai)
                    isAnalyzing = false
                    // Show error to user
                }
            }
        }
    }
    
    private func updateProgress(to value: Double, message: String) async {
        await MainActor.run {
            withAnimation(.easeInOut(duration: 0.3)) {
                analysisProgress = value
            }
        }
        
        // Simulate processing time
        try? await Task.sleep(nanoseconds: 300_000_000) // 300ms
    }
    
    private func performVisionAnalysis(on image: UIImage) async throws -> VisionAnalysisResult {
        return try await withCheckedThrowingContinuation { continuation in
            guard let cgImage = image.cgImage else {
                continuation.resume(throwing: PhotoAnalysisError.invalidImage)
                return
            }
            
            let request = VNRecognizeTextRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                let observations = request.results as? [VNRecognizedTextObservation] ?? []
                let recognizedText = observations.compactMap { observation in
                    observation.topCandidates(1).first?.string
                }
                
                let result = VisionAnalysisResult(
                    recognizedText: recognizedText,
                    confidence: observations.first?.confidence ?? 0.0
                )
                
                continuation.resume(returning: result)
            }
            
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    
    private func performAIFoodAnalysis(image: UIImage, visionResults: VisionAnalysisResult) async throws -> [ParsedFoodItem] {
        // Convert image to base64 for AI analysis
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw PhotoAnalysisError.imageProcessingFailed
        }
        
        let base64Image = imageData.base64EncodedString()
        
        // Create AI function call for photo analysis
        let functionCall = AIFunctionCall(
            name: "analyzeMealPhoto",
            arguments: [
                "imageData": AIAnyCodable(base64Image),
                "recognizedText": AIAnyCodable(visionResults.recognizedText),
                "analysisMode": AIAnyCodable("comprehensive"),
                "includeNutrition": AIAnyCodable(true)
            ]
        )
        
        // Execute AI analysis with timeout
        let result = try await withTimeout(seconds: 10.0) {
            try await viewModel.coachEngine.executeFunction(functionCall, for: viewModel.user)
        }
        
        guard result.success, let data = result.data else {
            throw PhotoAnalysisError.aiAnalysisFailed
        }
        
        // Convert AI result to ParsedFoodItem array
        return try convertAIResultToFoodItems(data)
    }
    
    private func convertAIResultToFoodItems(_ data: [String: SendableValue]) throws -> [ParsedFoodItem] {
        guard let itemsValue = data["detectedFoods"],
              case .array(let itemsArray) = itemsValue else {
            throw PhotoAnalysisError.noFoodsDetected
        }
        
        var foodItems: [ParsedFoodItem] = []
        
        for itemValue in itemsArray {
            guard case .dictionary(let itemDict) = itemValue else { continue }
            
            let name = extractString(from: itemDict["name"]) ?? "Unknown Food"
            let confidence = extractFloat(from: itemDict["confidence"]) ?? 0.5
            let calories = extractDouble(from: itemDict["estimatedCalories"]) ?? 0
            let protein = extractDouble(from: itemDict["estimatedProtein"]) ?? 0
            let carbs = extractDouble(from: itemDict["estimatedCarbs"]) ?? 0
            let fat = extractDouble(from: itemDict["estimatedFat"]) ?? 0
            let fiber = extractDouble(from: itemDict["estimatedFiber"])
            let sugar = extractDouble(from: itemDict["estimatedSugar"])
            let sodium = extractDouble(from: itemDict["estimatedSodium"])
            
            let foodItem = ParsedFoodItem(
                name: name,
                brand: extractString(from: itemDict["brand"]),
                quantity: extractDouble(from: itemDict["estimatedQuantity"]) ?? 1.0,
                unit: extractString(from: itemDict["unit"]) ?? "serving",
                calories: Int(calories),
                proteinGrams: protein,
                carbGrams: carbs,
                fatGrams: fat,
                fiberGrams: fiber,
                sugarGrams: sugar,
                sodiumMilligrams: sodium,
                databaseId: extractString(from: itemDict["databaseId"]),
                confidence: confidence
            )
            
            foodItems.append(foodItem)
        }
        
        if foodItems.isEmpty {
            throw PhotoAnalysisError.noFoodsDetected
        }
        
        return foodItems
    }
    
    private func withTimeout<T: Sendable>(seconds: TimeInterval, operation: @escaping @Sendable () async throws -> T) async throws -> T {
        try await withThrowingTaskGroup(of: T.self) { group in
            group.addTask {
                try await operation()
            }
            
            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
                throw PhotoAnalysisError.analysisTimeout
            }
            
            guard let result = try await group.next() else {
                throw PhotoAnalysisError.analysisTimeout
            }
            
            group.cancelAll()
            return result
        }
    }
    
    // Helper methods for extracting values from SendableValue
    private func extractString(from value: SendableValue?) -> String? {
        guard let value = value else { return nil }
        switch value {
        case .string(let str): return str
        default: return nil
        }
    }
    
    private func extractDouble(from value: SendableValue?) -> Double? {
        guard let value = value else { return nil }
        switch value {
        case .double(let double): return double
        case .int(let int): return Double(int)
        default: return nil
        }
    }
    
    private func extractFloat(from value: SendableValue?) -> Float? {
        guard let value = value else { return nil }
        switch value {
        case .double(let double): return Float(double)
        case .int(let int): return Float(int)
        default: return nil
        }
    }
    
    private func openSettings() {
        if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsURL)
        }
    }
}

// MARK: - Camera Manager
@MainActor
final class CameraManager: NSObject, ObservableObject {
    @Published var isAuthorized = false
    @Published var session = AVCaptureSession()
    @Published var flashMode: AVCaptureDevice.FlashMode = .off
    @Published var isCapturing = false
    @Published var isFocusing = false
    @Published var focusScale: CGFloat = 1.0
    @Published var aiAnalysisEnabled = true
    
    private var photoOutput = AVCapturePhotoOutput()
    private var currentCamera: AVCaptureDevice?
    private var frontCamera: AVCaptureDevice?
    private var backCamera: AVCaptureDevice?
    
    private var photoContinuation: CheckedContinuation<UIImage?, Never>?
    
    override init() {
        super.init()
        setupCameras()
    }
    
    func requestPermission() async {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        
        switch status {
        case .authorized:
            isAuthorized = true
        case .notDetermined:
            let granted = await AVCaptureDevice.requestAccess(for: .video)
            isAuthorized = granted
        case .denied, .restricted:
            isAuthorized = false
        @unknown default:
            isAuthorized = false
        }
    }
    
    func startSession() async {
        guard isAuthorized else { return }
        
        session.beginConfiguration()
        
        // Configure session for photo capture
        session.sessionPreset = .photo
        
        // Add camera input
        if let backCamera = backCamera {
            do {
                let input = try AVCaptureDeviceInput(device: backCamera)
                if session.canAddInput(input) {
                    session.addInput(input)
                    currentCamera = backCamera
                }
            } catch {
                AppLogger.error("Failed to add camera input", error: error, category: .ui)
            }
        }
        
        // Add photo output
        if session.canAddOutput(photoOutput) {
            session.addOutput(photoOutput)
            
            // Configure photo output for high quality
            photoOutput.isHighResolutionCaptureEnabled = true
            if let connection = photoOutput.connection(with: .video) {
                connection.videoOrientation = .portrait
            }
        }
        
        session.commitConfiguration()
        
        // Start session on background queue
        Task.detached { [session] in
            session.startRunning()
        }
    }
    
    func stopSession() {
        if session.isRunning {
            Task.detached { [weak self] in
                await self?.session.stopRunning()
            }
        }
    }
    
    func capturePhoto() async -> UIImage? {
        guard !isCapturing else { return nil }
        
        isCapturing = true
        defer { isCapturing = false }
        
        return await withCheckedContinuation { continuation in
            photoContinuation = continuation
            
            let settings = AVCapturePhotoSettings()
            settings.flashMode = flashMode
            
            photoOutput.capturePhoto(with: settings, delegate: self)
        }
    }
    
    func toggleFlash() {
        flashMode = flashMode == .off ? .on : .off
        // TODO: Add haptic feedback via DI when needed
    }
    
    func switchCamera() {
        guard let currentInput = session.inputs.first as? AVCaptureDeviceInput else { return }
        
        session.beginConfiguration()
        session.removeInput(currentInput)
        
        let newCamera = currentCamera == backCamera ? frontCamera : backCamera
        
        if let newCamera = newCamera {
            do {
                let newInput = try AVCaptureDeviceInput(device: newCamera)
                if session.canAddInput(newInput) {
                    session.addInput(newInput)
                    currentCamera = newCamera
                }
            } catch {
                AppLogger.error("Failed to switch camera", error: error, category: .ui)
                // Re-add the original input if switching fails
                if session.canAddInput(currentInput) {
                    session.addInput(currentInput)
                }
            }
        }
        
        session.commitConfiguration()
        // TODO: Add haptic feedback via DI when needed
    }
    
    private func setupCameras() {
        let discoverySession = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInWideAngleCamera],
            mediaType: .video,
            position: .unspecified
        )
        
        for device in discoverySession.devices {
            switch device.position {
            case .back:
                backCamera = device
            case .front:
                frontCamera = device
            default:
                break
            }
        }
    }
}

// MARK: - AVCapturePhotoCaptureDelegate
extension CameraManager: @preconcurrency AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        defer { photoContinuation = nil }
        
        if let error = error {
            AppLogger.error("Photo capture failed", error: error, category: .ui)
            photoContinuation?.resume(returning: nil)
            return
        }
        
        guard let imageData = photo.fileDataRepresentation(),
              let image = UIImage(data: imageData) else {
            photoContinuation?.resume(returning: nil)
            return
        }
        
        photoContinuation?.resume(returning: image)
    }
}

// MARK: - Camera Preview
struct CameraPreview: UIViewRepresentable {
    let session: AVCaptureSession
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: UIScreen.main.bounds)
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.frame = view.frame
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        if let previewLayer = uiView.layer.sublayers?.first as? AVCaptureVideoPreviewLayer {
            previewLayer.frame = uiView.frame
        }
    }
}

// MARK: - Camera Placeholder
struct CameraPlaceholder: View {
    let action: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "camera.fill")
                .font(.system(size: 80))
                .foregroundStyle(.secondary)
            
            VStack(spacing: 12) {
                Text("Camera Access Required")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Enable camera access to capture meal photos for intelligent food recognition.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Button("Enable Camera", action: action)
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColors.backgroundSecondary)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}

// MARK: - Image Picker
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    let sourceType: UIImagePickerController.SourceType
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.image = image
            }
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

// MARK: - Photo Tips View
struct PhotoTipsView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("📸 Photo Tips")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("Get the best results from AI food recognition:")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                    }
                    
                    VStack(spacing: 16) {
                        TipRow(
                            icon: "lightbulb.fill",
                            title: "Good Lighting",
                            description: "Take photos in bright, natural light when possible."
                        )
                        
                        TipRow(
                            icon: "viewfinder",
                            title: "Clear View",
                            description: "Ensure all food items are clearly visible and not overlapping."
                        )
                        
                        TipRow(
                            icon: "arrow.up.and.down.and.arrow.left.and.right",
                            title: "Fill the Frame",
                            description: "Get close enough so food takes up most of the photo."
                        )
                        
                        TipRow(
                            icon: "hand.raised.fill",
                            title: "Steady Shot",
                            description: "Hold your phone steady to avoid blurry photos."
                        )
                        
                        TipRow(
                            icon: "brain.head.profile",
                            title: "AI Analysis",
                            description: "Enable AI analysis for automatic food identification and nutrition estimation."
                        )
                    }
                }
                .padding()
            }
            .navigationTitle("Photo Tips")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

struct TipRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(AppColors.accent)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                
                Text(description)
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .background(AppColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Supporting Types
enum PhotoAnalysisError: LocalizedError {
    case invalidImage
    case imageProcessingFailed
    case visionAnalysisFailed
    case aiAnalysisFailed
    case noFoodsDetected
    case analysisTimeout
    
    var errorDescription: String? {
        switch self {
        case .invalidImage:
            return "Invalid image format"
        case .imageProcessingFailed:
            return "Failed to process image"
        case .visionAnalysisFailed:
            return "Vision analysis failed"
        case .aiAnalysisFailed:
            return "AI analysis failed"
        case .noFoodsDetected:
            return "No food items detected in the photo"
        case .analysisTimeout:
            return "Analysis timed out"
        }
    }
} 