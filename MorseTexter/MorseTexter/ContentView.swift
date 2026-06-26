import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            SendView()
                .tabItem {
                    Label("Send", systemImage: "flashlight.on.fill")
                }

            ReceiveView()
                .tabItem {
                    Label("Receive", systemImage: "camera.fill")
                }
        }
    }
}

#Preview {
    ContentView()
}
