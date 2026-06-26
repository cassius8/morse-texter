import AVFoundation
import Foundation

@MainActor
final class CameraReceiver: NSObject, ObservableObject {
    @Published private(set) var decodedText = ""
    @Published private(set) var debugInfo = ""
    @Published private(set) var isReceiving = false
    @Published private(set) var permissionDenied = false

    let session = AVCaptureSession()

    private let sampleQueue = DispatchQueue(label: "morse.camera.samples")
    private var isSignalOn = false
    private var segmentStart: Date?
    private var decodedSymbols: [MorseSymbol] = []
    private var recentBrightness: [Double] = []
    private let brightnessWindow = 5

    private var onThreshold: Double = 0.72
    private var offThreshold: Double = 0.58

    func requestPermissionAndStart() async {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            permissionDenied = false
            startSessionIfNeeded()
        case .notDetermined:
            let granted = await AVCaptureDevice.requestAccess(for: .video)
            permissionDenied = !granted
            if granted {
                startSessionIfNeeded()
            }
        default:
            permissionDenied = true
        }
    }

    func startReceiving() {
        isReceiving = true
        debugInfo = "Watching for flashes…"
    }

    func stopReceiving() {
        isReceiving = false
        debugInfo = "Paused"
    }

    func reset() {
        decodedText = ""
        decodedSymbols = []
        debugInfo = isReceiving ? "Watching for flashes…" : "Paused"
        isSignalOn = false
        segmentStart = nil
        recentBrightness = []
    }

    private func startSessionIfNeeded() {
        guard session.inputs.isEmpty else {
            if !session.isRunning {
                sampleQueue.async { [weak self] in
                    self?.session.startRunning()
                }
            }
            return
        }

        session.beginConfiguration()
        session.sessionPreset = .medium

        guard
            let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
            let input = try? AVCaptureDeviceInput(device: camera),
            session.canAddInput(input)
        else {
            session.commitConfiguration()
            debugInfo = "Camera unavailable"
            return
        }

        session.addInput(input)

        let output = AVCaptureVideoDataOutput()
        output.alwaysDiscardsLateVideoFrames = true
        output.videoSettings = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
        ]
        output.setSampleBufferDelegate(self, queue: sampleQueue)

        guard session.canAddOutput(output) else {
            session.commitConfiguration()
            debugInfo = "Cannot read camera frames"
            return
        }

        session.addOutput(output)
        session.commitConfiguration()

        sampleQueue.async { [weak self] in
            self?.session.startRunning()
        }
    }
}

extension CameraReceiver: AVCaptureVideoDataOutputSampleBufferDelegate {
    nonisolated func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        let brightness = Self.averageBrightness(of: pixelBuffer)
        Task { @MainActor in
            self.processBrightness(brightness)
        }
    }

    nonisolated private static func averageBrightness(of pixelBuffer: CVPixelBuffer) -> Double {
        CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly) }

        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)
        guard let baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer) else { return 0 }

        let rowBytes = CVPixelBufferGetBytesPerRow(pixelBuffer)
        let buffer = baseAddress.assumingMemoryBound(to: UInt8.self)

        let startX = width / 3
        let endX = width * 2 / 3
        let startY = height / 3
        let endY = height * 2 / 3

        var total = 0.0
        var count = 0

        for y in stride(from: startY, to: endY, by: 4) {
            for x in stride(from: startX, to: endX, by: 4) {
                let offset = y * rowBytes + x * 4
                let blue = Double(buffer[offset])
                let green = Double(buffer[offset + 1])
                let red = Double(buffer[offset + 2])
                total += (0.2126 * red + 0.7152 * green + 0.0722 * blue) / 255.0
                count += 1
            }
        }

        guard count > 0 else { return 0 }
        return total / Double(count)
    }

    private func processBrightness(_ brightness: Double) {
        guard isReceiving else { return }

        recentBrightness.append(brightness)
        if recentBrightness.count > brightnessWindow {
            recentBrightness.removeFirst()
        }

        let smoothed = recentBrightness.reduce(0, +) / Double(recentBrightness.count)
        let now = Date()

        if !isSignalOn {
            if smoothed >= onThreshold {
                finalizeOffSegment(at: now)
                isSignalOn = true
                segmentStart = now
            }
        } else if smoothed <= offThreshold {
            finalizeOnSegment(at: now)
            isSignalOn = false
            segmentStart = now
        }

        debugInfo = String(format: "Brightness %.2f | %@", smoothed, decodedSymbols.map(symbolLabel).joined())
    }

    private func finalizeOnSegment(at date: Date) {
        guard let start = segmentStart else { return }
        let durationMs = Int(date.timeIntervalSince(start) * 1000)
        guard let symbol = MorseCodec.classifyOnPulse(durationMs: durationMs) else { return }
        decodedSymbols.append(symbol)
        refreshDecodedText()
    }

    private func finalizeOffSegment(at date: Date) {
        guard let start = segmentStart else { return }
        let durationMs = Int(date.timeIntervalSince(start) * 1000)
        guard let symbol = MorseCodec.classifyOffGap(durationMs: durationMs) else { return }
        decodedSymbols.append(symbol)
        refreshDecodedText()
    }

    private func refreshDecodedText() {
        decodedText = MorseCodec.decodeSymbols(decodedSymbols)
    }

    private func symbolLabel(_ symbol: MorseSymbol) -> String {
        switch symbol {
        case .dot: return "."
        case .dash: return "-"
        case .letterGap: return "/"
        case .wordGap: return " "
        }
    }
}
