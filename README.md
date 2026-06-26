# Morse Texter

This is my first app. It is a phone app that will let you enter text, your phone will convert it to morse code with your phone flash, and then another phone will read that morse with its camera, and convert it back to text.

## MVP features

- **Send** — type a short message (A–Z, 0–9, spaces); the rear flash transmits International Morse at 12 WPM
- **Receive** — camera watches another phone’s flash and decodes the message on screen
- **Unit tests** — Morse encode/decode logic tested in Xcode

## Requirements

- Mac with **Xcode 15+**
- **iPhone 11** or newer (primary test target); **iOS 15+**
- Two iPhones recommended for full send/receive testing
- Free Apple ID for on-device development

The iPhone 11 rear flash and camera are fully supported for Morse send and receive.

See [MAC_SETUP.md](MAC_SETUP.md) for step-by-step Mac and iPhone setup.

## Open the project

```text
MorseTexter/MorseTexter.xcodeproj
```

1. Open the project in Xcode on your Mac
2. Select your iPhone as the run destination
3. Press **⌘R** to build and run
4. Press **⌘U** to run unit tests

## Two-phone test script

Use a dim room and hold phones 1–2 meters apart, rear cameras facing each other.

| Step | Phone A (Send) | Phone B (Receive) |
|------|----------------|-------------------|
| 1 | Type `SOS`, tap **Send with flash** | **Receive** tab running |
| 2 | Type `HI` | Confirm decoded text updates |
| 3 | Type `TEST 123` | Confirm spaces and digits |

## Project structure

```text
MorseTexter/
  MorseTexter/
    Models/          MorseCodec, MorseTiming
    Services/        TorchSender, CameraReceiver
    Views/           SendView, ReceiveView, CameraPreviewView
    ContentView.swift
  MorseTexterTests/  MorseCodecTests
```

## Known MVP limits

- Fixed speed (12 WPM) — sender and receiver must use the same timing
- Sensitive to bright ambient light
- Short messages only (40 characters max)
- No punctuation

## License

Personal project.
