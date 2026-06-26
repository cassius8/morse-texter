import AVFoundation
import Foundation

@MainActor
final class TorchSender: ObservableObject {
    @Published private(set) var isSending = false
    @Published private(set) var statusMessage = "Ready to send"
    @Published private(set) var morsePreview = ""

    private var captureDevice: AVCaptureDevice?
    private var sendTask: Task<Void, Never>?

    func prepare() {
        captureDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)
    }

    func send(text: String) {
        guard !isSending else { return }

        let sanitized = MorseCodec.sanitizeInput(text)
        guard !sanitized.isEmpty else {
            statusMessage = "Enter letters, numbers, or spaces"
            return
        }

        guard let device = captureDevice, device.hasTorch else {
            statusMessage = "Torch is not available on this device"
            return
        }

        let segments = MorseCodec.encodeSegments(sanitized)
        morsePreview = MorseCodec.encodePattern(sanitized)
        isSending = true
        statusMessage = "Sending…"

        sendTask = Task {
            await runSegments(segments, on: device)
            await finishSending()
        }
    }

    func cancel() {
        sendTask?.cancel()
        sendTask = nil
        setTorch(false, on: captureDevice)
        isSending = false
        statusMessage = "Cancelled"
    }

    private func runSegments(_ segments: [TorchSegment], on device: AVCaptureDevice) async {
        for segment in segments {
            if Task.isCancelled { return }

            setTorch(segment.isOn, on: device)
            try? await Task.sleep(nanoseconds: UInt64(segment.durationMs) * 1_000_000)
        }

        setTorch(false, on: device)
    }

    private func finishSending() {
        isSending = false
        statusMessage = "Done"
        sendTask = nil
    }

    private func setTorch(_ isOn: Bool, on device: AVCaptureDevice?) {
        guard let device, device.hasTorch else { return }

        do {
            try device.lockForConfiguration()
            if isOn {
                try device.setTorchModeOn(level: AVCaptureDevice.maxAvailableTorchLevel)
            } else {
                device.torchMode = .off
            }
            device.unlockForConfiguration()
        } catch {
            statusMessage = "Torch error: \(error.localizedDescription)"
        }
    }
}
