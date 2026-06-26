import SwiftUI

struct SendView: View {
    @StateObject private var sender = TorchSender()
    @State private var message = ""

    var body: some View {
        NavigationView {
            Form {
                Section("Message") {
                    TextField("Type text to send", text: $message)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                        .onChange(of: message) { newValue in
                            message = MorseCodec.sanitizeInput(newValue)
                        }

                    Text("\(message.count)/\(MorseCodec.maxMessageLength)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Section("Morse preview") {
                    Text(sender.morsePreview.isEmpty ? MorseCodec.encodePattern(message) : sender.morsePreview)
                        .font(.system(.body, design: .monospaced))
                }

                Section {
                    Button(sender.isSending ? "Sending…" : "Send with flash") {
                        sender.send(text: message)
                    }
                    .disabled(sender.isSending || message.isEmpty)

                    if sender.isSending {
                        Button("Stop", role: .destructive) {
                            sender.cancel()
                        }
                    }
                }

                Section {
                    Text(sender.statusMessage)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Send")
            .onAppear {
                sender.prepare()
            }
        }
    }
}

#Preview {
    SendView()
}
