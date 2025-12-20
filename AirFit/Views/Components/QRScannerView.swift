import SwiftUI
@preconcurrency import AVFoundation

/// A camera view that scans for AirFit server QR codes.
/// Expected format: airfit://server?url=http://airfit-server:8080
struct QRScannerView: View {
    @Environment(\.dismiss) private var dismiss

    /// Called when a valid server URL is scanned
    let onScan: (String) -> Void

    @State private var cameraPermission: CameraPermission = .unknown
    @State private var showPermissionDeniedAlert = false

    enum CameraPermission {
        case unknown, granted, denied
    }

    var body: some View {
        ZStack {
            // Background
            Color.black.ignoresSafeArea()

            switch cameraPermission {
            case .unknown:
                ProgressView()
                    .tint(.white)

            case .granted:
                QRCameraPreview(onCodeScanned: handleScannedCode)
                    .ignoresSafeArea()

                // Overlay with scanning frame
                scanningOverlay

            case .denied:
                permissionDeniedView
            }
        }
        .task {
            await checkCameraPermission()
        }
        .alert("Camera Access Required", isPresented: $showPermissionDeniedAlert) {
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("Cancel", role: .cancel) {
                dismiss()
            }
        } message: {
            Text("AirFit needs camera access to scan server QR codes. You can enable this in Settings.")
        }
    }

    // MARK: - Views

    private var scanningOverlay: some View {
        VStack {
            // Title
            Text("Scan Server QR Code")
                .font(.titleMedium)
                .foregroundStyle(.white)
                .padding(.top, 60)

            Spacer()

            // Scanning frame
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(.white.opacity(0.8), lineWidth: 3)
                .frame(width: 250, height: 250)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(.white.opacity(0.1))
                )

            Spacer()

            // Instructions
            Text("Point your camera at the QR code\nshared by your server host")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.8))
                .multilineTextAlignment(.center)
                .padding(.bottom, 40)

            // Cancel button
            Button {
                dismiss()
            } label: {
                Text("Cancel")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 12)
                    .background(.white.opacity(0.2))
                    .clipShape(Capsule())
            }
            .padding(.bottom, 40)
        }
    }

    private var permissionDeniedView: some View {
        VStack(spacing: 24) {
            Image(systemName: "camera.fill")
                .font(.system(size: 64))
                .foregroundStyle(.white.opacity(0.6))

            Text("Camera Access Needed")
                .font(.titleMedium)
                .foregroundStyle(.white)

            Text("To scan QR codes, please allow camera access in Settings.")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Button {
                showPermissionDeniedAlert = true
            } label: {
                Text("Open Settings")
                    .font(.headline)
                    .foregroundStyle(.black)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 12)
                    .background(.white)
                    .clipShape(Capsule())
            }

            Button {
                dismiss()
            } label: {
                Text("Enter Manually Instead")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.8))
            }
        }
    }

    // MARK: - Actions

    private func checkCameraPermission() async {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            cameraPermission = .granted
        case .notDetermined:
            let granted = await AVCaptureDevice.requestAccess(for: .video)
            cameraPermission = granted ? .granted : .denied
        case .denied, .restricted:
            cameraPermission = .denied
        @unknown default:
            cameraPermission = .denied
        }
    }

    private func handleScannedCode(_ code: String) {
        // Try to parse as AirFit QR code
        if let serverURL = ServerConfiguration.parseQRCode(code) {
            // Valid AirFit QR code
            onScan(serverURL)
            dismiss()
        } else if code.hasPrefix("http://") || code.hasPrefix("https://") {
            // Direct URL (also accept plain URLs for flexibility)
            onScan(code)
            dismiss()
        }
        // Otherwise ignore - not a valid server QR code
    }
}

// MARK: - Camera Preview (UIViewRepresentable)

struct QRCameraPreview: UIViewRepresentable {
    let onCodeScanned: (String) -> Void

    func makeUIView(context: Context) -> CameraPreviewView {
        let view = CameraPreviewView()
        view.onCodeScanned = onCodeScanned
        return view
    }

    func updateUIView(_ uiView: CameraPreviewView, context: Context) {}
}

/// Delegate class for handling QR code metadata - isolated from MainActor
private final class QRMetadataDelegate: NSObject, AVCaptureMetadataOutputObjectsDelegate, @unchecked Sendable {
    var onCodeScanned: ((String) -> Void)?
    private var hasScanned = false
    private weak var captureSession: AVCaptureSession?

    init(captureSession: AVCaptureSession) {
        self.captureSession = captureSession
        super.init()
    }

    func metadataOutput(
        _ output: AVCaptureMetadataOutput,
        didOutput metadataObjects: [AVMetadataObject],
        from connection: AVCaptureConnection
    ) {
        guard !hasScanned,
              let metadataObject = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
              let stringValue = metadataObject.stringValue else {
            return
        }

        // Prevent multiple scans
        hasScanned = true

        // Haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)

        // Stop scanning
        captureSession?.stopRunning()

        // Notify on main thread
        DispatchQueue.main.async { [weak self] in
            self?.onCodeScanned?(stringValue)
        }
    }
}

/// UIKit view that manages AVCaptureSession for QR scanning
class CameraPreviewView: UIView {
    var onCodeScanned: ((String) -> Void)? {
        didSet {
            metadataDelegate?.onCodeScanned = onCodeScanned
        }
    }

    private let captureSession = AVCaptureSession()
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var metadataDelegate: QRMetadataDelegate?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupCamera()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupCamera()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        previewLayer?.frame = bounds
    }

    private func setupCamera() {
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else { return }

        do {
            let videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
            if captureSession.canAddInput(videoInput) {
                captureSession.addInput(videoInput)
            }

            let metadataOutput = AVCaptureMetadataOutput()
            if captureSession.canAddOutput(metadataOutput) {
                captureSession.addOutput(metadataOutput)

                // Use separate delegate object for proper Swift 6 concurrency
                let delegate = QRMetadataDelegate(captureSession: captureSession)
                delegate.onCodeScanned = onCodeScanned
                self.metadataDelegate = delegate

                metadataOutput.setMetadataObjectsDelegate(delegate, queue: .main)
                metadataOutput.metadataObjectTypes = [.qr]
            }

            // Setup preview layer
            let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
            previewLayer.videoGravity = .resizeAspectFill
            layer.addSublayer(previewLayer)
            self.previewLayer = previewLayer

            // Start capture session on background thread
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                self?.captureSession.startRunning()
            }
        } catch {
            print("Failed to setup camera: \(error)")
        }
    }

    deinit {
        captureSession.stopRunning()
    }
}

#Preview {
    QRScannerView { url in
        print("Scanned: \(url)")
    }
}
