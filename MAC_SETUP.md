# Mac setup (Phase 0)

Complete these steps on a Mac before running the app on an iPhone.

## 1. Install Xcode

1. Open the **Mac App Store** and install **Xcode**.
2. Launch Xcode once and accept the license agreement.
3. Open **Xcode → Settings → Platforms** and install the latest **iOS** platform if prompted.

## 2. Get the project on your Mac

Clone or copy this repository, then open:

`MorseTexter/MorseTexter.xcodeproj`

## 3. Connect your iPhone

1. Plug in your iPhone with a USB cable.
2. On the iPhone, tap **Trust** if prompted.
3. On iOS 16+, enable **Settings → Privacy & Security → Developer Mode** and restart if asked.

## 4. Configure signing

1. In Xcode, select the **MorseTexter** project in the navigator.
2. Select the **MorseTexter** target → **Signing & Capabilities**.
3. Choose your **Team** (your Apple ID). A free Apple ID is enough for device testing.
4. At the top of Xcode, pick your iPhone as the run destination.

## 5. Build and run

1. Press **⌘R** to build and run on your iPhone.
2. If iOS blocks the app, open **Settings → General → VPN & Device Management** and trust your developer certificate.

## 6. Run unit tests

Press **⌘U** in Xcode to run `MorseCodecTests` (no device hardware required).

## Gate checklist

- [ ] Xcode opens the project without errors
- [ ] App installs on your iPhone
- [ ] Send and Receive tabs appear
- [ ] Unit tests pass

## Two-phone test (after build works)

1. Phone A → **Send** tab → type `SOS` → **Send with flash**
2. Phone B → **Receive** tab → point camera at Phone A’s flash in a dim room
3. Repeat with `HI` and `TEST 123`

Works best at 1–2 meters with the rear cameras facing each other.
