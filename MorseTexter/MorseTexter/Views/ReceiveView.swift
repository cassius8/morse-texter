import SwiftUI

struct ReceiveView: View {
    @StateObject private var receiver = CameraReceiver()

    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                ZStack {
                    CameraPreviewView(session: receiver.session)
                        .clipShape(RoundedRectangle(cornerRadius: 12))

                    if receiver.permissionDenied {
                        VStack(spacing: 12) {
                            Image(systemName: "camera.fill")
                                .font(.largeTitle)
                            Text("Camera access needed")
                                .font(.headline)
                            Text("Allow camera access in Settings to read Morse flashes.")
                                .font(.subheadline)
                                .multilineTextAlignment(.center)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                    }
                }
                .frame(maxHeight: 320)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Decoded text")
                        .font(.headline)
                    Text(receiver.decodedText.isEmpty ? "Waiting for signal…" : receiver.decodedText)
                        .font(.title3)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }

                Text(receiver.debugInfo)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                HStack {
                    Button(receiver.isReceiving ? "Pause" : "Start receiving") {
                        if receiver.isReceiving {
                            receiver.stopReceiving()
                        } else {
                            receiver.startReceiving()
                        }
                    }
                    .buttonStyle(.borderedProminent)

                    Button("Reset") {
                        receiver.reset()
                    }
                    .buttonStyle(.bordered)
                }
            }
            .padding()
            .navigationTitle("Receive")
            .task {
                await receiver.requestPermissionAndStart()
                receiver.startReceiving()
            }
        }
    }
}

#Preview {
    ReceiveView()
}
