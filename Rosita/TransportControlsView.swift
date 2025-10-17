import SwiftUI

// First 3 buttons: Play/Pause, Stop, REC
struct PlayStopRecButtons: View {
    @EnvironmentObject var audioEngine: AudioEngine

    var body: some View {
        HStack(spacing: 6) {
            // Play/Pause button
            if audioEngine.isPlaying {
                RetroIconButton(
                    icon: PauseIconShape(),
                    color: Color.white,
                    iconColor: .black,
                    action: {
                        audioEngine.togglePlayback()
                    },
                    width: 56,
                    height: 56
                )
            } else {
                RetroIconButton(
                    icon: PlayIconShape(),
                    color: Color.white,
                    iconColor: .black,
                    action: {
                        audioEngine.togglePlayback()
                    },
                    width: 56,
                    height: 56
                )
            }

            // Stop button
            RetroIconButton(
                icon: StopIconShape(),
                color: Color.white,
                iconColor: .black,
                action: {
                    audioEngine.stop()
                },
                width: 56,
                height: 56
            )

            // REC button
            RetroButton(
                title: audioEngine.isRecording ? "REC" : "REC",
                color: audioEngine.isRecording ? Color(hex: "FF0000") : Color.white,
                textColor: audioEngine.isRecording ? .white : .black,
                action: {
                    audioEngine.toggleRecording()
                },
                width: 56,
                height: 56,
                fontSize: 12
            )
        }
    }
}

// Next 6 buttons: Random, Clear, STEP EDIT, KIT, Mixer, Scale
struct Transport6Buttons: View {
    @EnvironmentObject var audioEngine: AudioEngine
    @State private var longPressTimer: Timer?
    @State private var isLongPressing = false

    // Clear button countdown state
    @State private var clearLongPressTimer: Timer?
    @State private var isClearLongPressing = false
    @State private var clearCountdown: Int? = nil // 3, 2, 1, then clear
    @State private var isFlashingRed = false

    // Scale button long press state
    @State private var scaleLongPressTimer: Timer?
    @State private var isScaleLongPressing = false

    var body: some View {
        HStack(spacing: 6) {
            // Random button - tap to randomize once, long press to enable continuous random
            RetroIconButton(
                icon: RandomIconShape(),
                color: audioEngine.continuousRandomEnabled[audioEngine.selectedInstrument] ? Color(hex: "9370DB") : Color.white,
                iconColor: audioEngine.continuousRandomEnabled[audioEngine.selectedInstrument] ? .white : .black,
                action: {
                    // Only fire if not long pressing
                    if !isLongPressing {
                        audioEngine.randomizePattern()
                    }
                },
                width: 56,
                height: 56
            )
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        if longPressTimer == nil {
                            // Start timer on press
                            longPressTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { _ in
                                // Long press detected
                                isLongPressing = true
                                audioEngine.continuousRandomEnabled[audioEngine.selectedInstrument].toggle()
                                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            }
                        }
                    }
                    .onEnded { _ in
                        // Cancel timer and reset
                        longPressTimer?.invalidate()
                        longPressTimer = nil

                        // Reset long press flag after a short delay
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            isLongPressing = false
                        }
                    }
            )

            // Clear button - hold to countdown and clear all
            ZStack {
                if let countdown = clearCountdown {
                    // Show countdown number
                    Text("\(countdown)")
                        .font(.system(size: 32, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                        .frame(width: 56, height: 56)
                        .background(isFlashingRed ? Color(hex: "FF0000") : Color.black)
                        .overlay(Rectangle().stroke(Color.white, lineWidth: 2))
                } else {
                    RetroIconButton(
                        icon: ClearIconShape(),
                        color: Color.white,
                        iconColor: .black,
                        action: {
                            // Tap to clear current instrument's pattern
                            audioEngine.clearPattern()
                        },
                        width: 56,
                        height: 56,
                        useStroke: true
                    )
                    .simultaneousGesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { _ in
                                if clearLongPressTimer == nil {
                                    // Start countdown timer on press (delay to allow tap to register)
                                    clearLongPressTimer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: false) { _ in
                                        // Long press detected - start countdown
                                        isClearLongPressing = true
                                        clearCountdown = 3

                                        // Countdown 3 -> 2 -> 1 -> flash -> clear
                                        clearLongPressTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { timer in
                                            if let count = clearCountdown {
                                                if count > 1 {
                                                    clearCountdown = count - 1
                                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                                } else {
                                                    // Flash red
                                                    isFlashingRed = true
                                                    UIImpactFeedbackGenerator(style: .heavy).impactOccurred()

                                                    // Clear after flash
                                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                                        audioEngine.clearAllPatterns()
                                                        clearCountdown = nil
                                                        isFlashingRed = false
                                                        timer.invalidate()
                                                        clearLongPressTimer = nil
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                            .onEnded { _ in
                                // Cancel countdown if released early
                                clearLongPressTimer?.invalidate()
                                clearLongPressTimer = nil
                                clearCountdown = nil
                                isFlashingRed = false

                                // Reset long press flag after delay
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    isClearLongPressing = false
                                }
                            }
                    )
                }
            }

            // EDIT button - toggles step edit mode for pitch editing
            RetroButton(
                title: "EDIT",
                color: audioEngine.isStepEditMode ? Color(hex: "FF9999") : Color.white,
                textColor: audioEngine.isStepEditMode ? .white : .black,
                action: {
                    audioEngine.isStepEditMode.toggle()
                },
                width: 56,
                height: 56,
                fontSize: 12
            )

            // KIT button - for drum kit browsing
            RetroButton(
                title: "KIT",
                color: audioEngine.isKitBrowserMode ? Color(hex: "FFA500") : Color.white,
                textColor: audioEngine.isKitBrowserMode ? .white : .black,
                action: {
                    // Always enable kit mode when pressed
                    audioEngine.isKitBrowserMode = true
                    audioEngine.isFXMode = false
                    audioEngine.isMixerMode = false
                },
                width: 56,
                height: 56,
                fontSize: 12
            )

            // Mixer button
            RetroIconButton(
                icon: MixerIconShape(),
                color: audioEngine.isMixerMode ? Color(hex: "FFA500") : Color.white,
                iconColor: audioEngine.isMixerMode ? .white : .black,
                action: {
                    // Always enable mixer mode when pressed
                    audioEngine.isMixerMode = true
                    audioEngine.isFXMode = false
                    audioEngine.isKitBrowserMode = false
                },
                width: 56,
                height: 56
            )

            // Scale button - tap to toggle scale selection, long press to lock selection mode
            ZStack {
                RetroButton(
                    title: getScaleName(),
                    color: getScaleColor(),
                    textColor: .black,
                    action: {
                        if !isScaleLongPressing {
                            // Tap: toggle scale selection mode
                            audioEngine.isScaleSelectionMode.toggle()
                            if !audioEngine.isScaleSelectionMode {
                                // Turning off selection mode also unlocks it
                                audioEngine.isScaleSelectionLocked = false
                            }
                        }
                    },
                    width: 56,
                    height: 56,
                    fontSize: 9
                )
                .simultaneousGesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { _ in
                            if scaleLongPressTimer == nil {
                                // Long press: open scale selection and lock it
                                scaleLongPressTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { _ in
                                    isScaleLongPressing = true
                                    // Enable scale selection mode and lock it
                                    audioEngine.isScaleSelectionMode = true
                                    audioEngine.isScaleSelectionLocked = true
                                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                }
                            }
                        }
                        .onEnded { _ in
                            scaleLongPressTimer?.invalidate()
                            scaleLongPressTimer = nil
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                isScaleLongPressing = false
                            }
                        }
                )

                // Yellow border when locked
                if audioEngine.isScaleSelectionLocked {
                    Rectangle()
                        .stroke(Color(hex: "FFD700"), lineWidth: 4)
                        .frame(width: 56, height: 56)
                        .allowsHitTesting(false)
                }
            }
        }
    }

    private func cycleScale() {
        let newScale = (audioEngine.currentScale + 1) % 8
        audioEngine.changeScale(to: newScale)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    private func getScaleName() -> String {
        switch audioEngine.currentScale {
        case 0: return "MAJ"
        case 1: return "MIN"
        case 2: return "PENT"
        case 3: return "BLUE"
        case 4: return "CHRO"
        case 5: return "DOR"
        case 6: return "MIX"
        case 7: return "H-MIN"
        default: return "MAJ"
        }
    }

    private func getScaleColor() -> Color {
        switch audioEngine.currentScale {
        case 0: return Color(hex: "FF69B4") // Major - Hot Pink
        case 1: return Color(hex: "9370DB") // Minor - Purple
        case 2: return Color(hex: "32CD32") // Pentatonic - Lime Green
        case 3: return Color(hex: "1E90FF") // Blues - Dodger Blue
        case 4: return Color(hex: "FFD700") // Chromatic - Gold
        case 5: return Color(hex: "FF6347") // Dorian - Tomato
        case 6: return Color(hex: "FF8C00") // Mixolydian - Dark Orange
        case 7: return Color(hex: "8A2BE2") // Harmonic Minor - Blue Violet
        default: return Color.gray
        }
    }
}

// Combined view for backward compatibility
struct TransportControlsView: View {
    var body: some View {
        HStack(spacing: 6) {
            PlayStopRecButtons()
            Transport6Buttons()
        }
    }
}
