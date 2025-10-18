import SwiftUI

struct PianoKeyboardView: View {
    @EnvironmentObject var audioEngine: AudioEngine
    @State private var pressedKeys: Set<Int> = []

    // Computed properties for scale-mapped keys
    // All keys (white and black) play only notes from the current scale
    var whiteKeys: [Int] {
        // Map white key positions (0-13) to scale notes
        (0..<14).map { audioEngine.keyboardIndexToScaleNote(index: $0) }
    }

    // Define all black keys with their positions - proper 2-3 grouping
    // Black keys now play the next set of scale notes (indices 14-23)
    var blackKeys: [(note: Int, position: CGFloat)] {
        [
            // First octave - 2 then 3 black keys (scale indices 14-18)
            (audioEngine.keyboardIndexToScaleNote(index: 14), 0.75),
            (audioEngine.keyboardIndexToScaleNote(index: 15), 1.75),
            (audioEngine.keyboardIndexToScaleNote(index: 16), 3.75),
            (audioEngine.keyboardIndexToScaleNote(index: 17), 4.75),
            (audioEngine.keyboardIndexToScaleNote(index: 18), 5.75),
            // Second octave - 2 then 3 black keys (scale indices 19-23)
            (audioEngine.keyboardIndexToScaleNote(index: 19), 7.75),
            (audioEngine.keyboardIndexToScaleNote(index: 20), 8.75),
            (audioEngine.keyboardIndexToScaleNote(index: 21), 10.75),
            (audioEngine.keyboardIndexToScaleNote(index: 22), 11.75),
            (audioEngine.keyboardIndexToScaleNote(index: 23), 12.75)
        ]
    }

    var body: some View {
        GeometryReader { geometry in
            let totalWidth = geometry.size.width
            let whiteKeyWidth = totalWidth / CGFloat(whiteKeys.count)
            let blackKeyWidth = whiteKeyWidth * 0.65
            let keyboardHeight = geometry.size.height
            let blackKeyHeight = keyboardHeight * 0.65

            ZStack(alignment: .topLeading) {
                if audioEngine.isStepEditMode {
                    // EDIT MODE - Show 16 pink step keys
                    HStack(spacing: 0) {
                        ForEach(0..<16, id: \.self) { step in
                            EditStepKey(
                                step: step,
                                width: totalWidth / 16,
                                height: keyboardHeight,
                                editMode: audioEngine.editKeyboardMode
                            )
                            .environmentObject(audioEngine)
                        }
                    }
                } else {
                    // NORMAL MODE - Show piano keys
                    // White keys layer
                    HStack(spacing: 0) {
                        ForEach(0..<whiteKeys.count, id: \.self) { index in
                            makeWhiteKeyView(index: index, whiteKeyWidth: whiteKeyWidth, keyboardHeight: keyboardHeight)
                                .frame(width: whiteKeyWidth, height: keyboardHeight)
                                .clipped()
                        }
                    }

                    // Black keys layer - positioned absolutely (hidden in drum/FX/edit modes)
                    if audioEngine.selectedInstrument != 3 && !audioEngine.isFXMode && !audioEngine.isStepEditMode {
                        ForEach(Array(blackKeys.enumerated()), id: \.offset) { index, blackKey in
                        BlackKey(
                            isPressed: pressedKeys.contains(blackKey.note),
                            width: blackKeyWidth,
                            height: blackKeyHeight
                        )
                        .contentShape(Rectangle())
                        .position(
                            x: blackKey.position * whiteKeyWidth + blackKeyWidth / 2,
                            y: blackKeyHeight / 2
                        )
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { _ in
                                    if !pressedKeys.contains(blackKey.note) {
                                        pressedKeys.insert(blackKey.note)

                                        // Always play the note sound
                                        audioEngine.noteOn(note: blackKey.note)

                                        // Record if in recording mode
                                        if audioEngine.isRecording {
                                            audioEngine.recordNoteToStep(note: blackKey.note)
                                        }

                                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                    }
                                }
                                .onEnded { _ in
                                    pressedKeys.remove(blackKey.note)
                                    audioEngine.noteOff(note: blackKey.note)
                                }
                        )
                    }
                }
                }
            }
        }
        .frame(height: 200) // Reasonable height
        .background(
            Rectangle()
                .fill(Color.white)
                .overlay(
                    Rectangle()
                        .stroke(Color.black, lineWidth: 3)
                )
        )
    }

    @ViewBuilder
    private func makeWhiteKeyView(index: Int, whiteKeyWidth: CGFloat, keyboardHeight: CGFloat) -> some View {
        let key = WhiteKey(
            isPressed: pressedKeys.contains(whiteKeys[index]),
            width: whiteKeyWidth,
            height: keyboardHeight,
            keyIndex: index,
            isDrumMode: audioEngine.selectedInstrument == 3,
            drumPerformanceMode: audioEngine.drumPerformanceMode
        )
        .environmentObject(audioEngine)

        if audioEngine.selectedInstrument == 3 && index < 16 {
            // Drum performance modes - different behavior based on mode
            switch audioEngine.drumPerformanceMode {
            case 0:  // MUTE mode - tap to toggle step mute
                key
                    .contentShape(Rectangle())
                    .onTapGesture {
                        audioEngine.toggleDrumStepMute(step: index)
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    }
            case 1:  // PROB mode - tap to cycle probability
                key
                    .contentShape(Rectangle())
                    .onTapGesture {
                        let currentProb = audioEngine.getStepProbability(step: index)
                        // Cycle: 100% -> 75% -> 50% -> 25% -> 0% -> 100%
                        let newProb: Float
                        if currentProb == 100 { newProb = 75 }
                        else if currentProb == 75 { newProb = 50 }
                        else if currentProb == 50 { newProb = 25 }
                        else if currentProb == 25 { newProb = 0 }
                        else { newProb = 100 }
                        audioEngine.setStepProbability(step: index, probability: newProb)
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    }
            case 2:  // ROLL mode - tap to toggle roll
                key
                    .contentShape(Rectangle())
                    .onTapGesture {
                        audioEngine.toggleStepRoll(step: index)
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    }
            case 3:  // TIME mode - drag to adjust timing
                key
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { gesture in
                                // Convert vertical drag to timing offset (-50 to +50 ms)
                                let offset = Float(gesture.translation.height) / 2.0  // -50 to +50
                                let clampedOffset = max(-50, min(50, offset))
                                audioEngine.setStepTimingOffset(step: index, offset: clampedOffset)
                            }
                            .onEnded { _ in
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            }
                    )
            case 4:  // VELO mode - drag to adjust velocity
                key
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { gesture in
                                // Convert vertical drag to velocity multiplier (0.5 to 1.5)
                                let velocity = 1.0 - Float(gesture.translation.height) / 100.0
                                let clampedVelocity = max(0.5, min(1.5, velocity))
                                audioEngine.setStepVelocity(step: index, velocity: clampedVelocity)
                            }
                            .onEnded { _ in
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            }
                    )
            case 5:  // PITCH mode - drag to adjust pitch shift
                key
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { gesture in
                                // Convert vertical drag to pitch shift (-12 to +12 semitones)
                                let semitones = -Float(gesture.translation.height) / 8.0
                                let clampedSemitones = max(-12, min(12, semitones))
                                audioEngine.setStepPitchShift(step: index, semitones: clampedSemitones)
                            }
                            .onEnded { _ in
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            }
                    )
            case 6:  // DECAY mode - drag to adjust decay length
                key
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { gesture in
                                // Convert vertical drag to decay multiplier (0.2 to 3.0)
                                let decay = 1.0 - Float(gesture.translation.height) / 100.0
                                let clampedDecay = max(0.2, min(3.0, decay))
                                audioEngine.setStepDecay(step: index, decay: clampedDecay)
                            }
                            .onEnded { _ in
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            }
                    )
            case 7:  // CHAOS mode - tap to toggle chaos/randomization
                key
                    .contentShape(Rectangle())
                    .onTapGesture {
                        audioEngine.toggleStepChaos(step: index)
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    }
            default:
                key
                    .contentShape(Rectangle())
                    .onTapGesture {
                        audioEngine.toggleDrumStepMute(step: index)
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    }
            }
        } else {
            // Normal keyboard mode - use drag gesture for held notes
            key
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { _ in
                            if !pressedKeys.contains(whiteKeys[index]) {
                                pressedKeys.insert(whiteKeys[index])
                                audioEngine.noteOn(note: whiteKeys[index])

                                // Record if in recording mode
                                if audioEngine.isRecording {
                                    audioEngine.recordNoteToStep(note: whiteKeys[index])
                                }

                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            }
                        }
                        .onEnded { _ in
                            pressedKeys.remove(whiteKeys[index])
                            audioEngine.noteOff(note: whiteKeys[index])
                        }
                )
        }
    }

    private func hasBlackKeyAfter(whiteKeyIndex: Int) -> Bool {
        // Piano pattern: Black keys exist after C, D, F, G, A
        // But NOT after E and B
        let noteValue = whiteKeys[whiteKeyIndex] % 12

        // MIDI note values: C=0, D=2, E=4, F=5, G=7, A=9, B=11
        switch noteValue {
        case 0: return true  // C -> C#
        case 2: return true  // D -> D#
        case 4: return false // E -> F (no black key)
        case 5: return true  // F -> F#
        case 7: return true  // G -> G#
        case 9: return true  // A -> A#
        case 11: return false // B -> C (no black key)
        default: return false
        }
    }

    private func handleKeyPress(note: Int) {
        if pressedKeys.contains(note) {
            pressedKeys.remove(note)
            audioEngine.noteOff(note: note)
        } else {
            pressedKeys.insert(note)
            audioEngine.noteOn(note: note)
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }
    }

    private func getDrumModeLabel() -> String {
        switch audioEngine.drumPerformanceMode {
        case 0: return "MUTE: \(audioEngine.mutedDrumSteps.count) MUTED"
        case 1: return "PROB: TAP TO SET %"
        case 2: return "ROLL: TAP TO TRIGGER"
        case 3: return "TIME: SLIDE TO SHIFT"
        case 4: return "VELO: SLIDE FOR VELOCITY"
        default: return "MUTE"
        }
    }

    private func getDrumModeColor() -> Color {
        switch audioEngine.drumPerformanceMode {
        case 0: return Color.black.opacity(0.7)        // MUTE - black
        case 1: return Color(hex: "9370DB").opacity(0.8)  // PROB - purple
        case 2: return Color(hex: "FF6347").opacity(0.8)  // ROLL - tomato red
        case 3: return Color(hex: "FFD700").opacity(0.8)  // TIME - gold
        case 4: return Color(hex: "32CD32").opacity(0.8)  // VELO - lime green
        default: return Color.black.opacity(0.7)
        }
    }
}

// White key component
struct WhiteKey: View {
    @EnvironmentObject var audioEngine: AudioEngine
    let isPressed: Bool
    let width: CGFloat
    let height: CGFloat
    let keyIndex: Int
    let isDrumMode: Bool
    let drumPerformanceMode: Int

    var body: some View {
        Rectangle()
            .fill(getKeyColor())
            .frame(width: width, height: height)
            .overlay(
                Rectangle()
                    .stroke(Color.black, lineWidth: 2)
            )
            .overlay(
                // Show value overlay for certain modes
                getValueOverlay()
            )
    }

    @ViewBuilder
    private func getValueOverlay() -> some View {
        if isDrumMode && keyIndex < 16 {
            switch drumPerformanceMode {
            case 1:  // PROB mode - show percentage
                let prob = audioEngine.getStepProbability(step: keyIndex)
                if prob < 100 {
                    Text("\(Int(prob))%")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                }
            case 3:  // TIME mode - show timing offset
                let offset = audioEngine.getStepTimingOffset(step: keyIndex)
                if offset != 0 {
                    Text("\(Int(offset))ms")
                        .font(.system(size: 8, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                }
            case 4:  // VELO mode - show velocity multiplier
                let velo = audioEngine.getStepVelocity(step: keyIndex)
                if velo != 1.0 {
                    Text("×\(String(format: "%.1f", velo))")
                        .font(.system(size: 8, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                }
            case 5:  // PITCH mode - show pitch shift
                let pitch = audioEngine.getStepPitchShift(step: keyIndex)
                if pitch != 0 {
                    Text("\(pitch > 0 ? "+" : "")\(Int(pitch))")
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                }
            case 6:  // DECAY mode - show decay multiplier
                let decay = audioEngine.getStepDecay(step: keyIndex)
                if decay != 1.0 {
                    Text("×\(String(format: "%.1f", decay))")
                        .font(.system(size: 8, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                }
            default:
                EmptyView()
            }
        }
    }

    private func getKeyColor() -> Color {
        // Drum performance modes - first 16 keys
        if isDrumMode && keyIndex < 16 {
            switch drumPerformanceMode {
            case 0:  // MUTE mode
                let isMuted = audioEngine.isDrumStepMuted(step: keyIndex)
                return isMuted ? Color.black.opacity(0.8) : Color(hex: "1E90FF")

            case 1:  // PROB mode
                let prob = audioEngine.getStepProbability(step: keyIndex)
                // Show gradient based on probability
                if prob == 0 { return Color.black.opacity(0.8) }
                else if prob == 25 { return Color(hex: "9370DB").opacity(0.4) }
                else if prob == 50 { return Color(hex: "9370DB").opacity(0.6) }
                else if prob == 75 { return Color(hex: "9370DB").opacity(0.8) }
                else { return Color(hex: "9370DB") }

            case 2:  // ROLL mode
                let isRolling = audioEngine.isStepRolling(step: keyIndex)
                return isRolling ? Color(hex: "FF6347") : Color.white

            case 3:  // TIME mode
                let offset = audioEngine.getStepTimingOffset(step: keyIndex)
                if offset > 0 { return Color(hex: "FFD700").opacity(0.6) }
                else if offset < 0 { return Color(hex: "FFD700").opacity(0.4) }
                else { return Color.white }

            case 4:  // VELO mode
                let velo = audioEngine.getStepVelocity(step: keyIndex)
                if velo > 1.0 { return Color(hex: "32CD32").opacity(0.7) }
                else if velo < 1.0 { return Color(hex: "32CD32").opacity(0.4) }
                else { return Color.white }

            case 5:  // PITCH mode
                let pitch = audioEngine.getStepPitchShift(step: keyIndex)
                if pitch > 0 { return Color(hex: "1E90FF").opacity(0.7) }  // Dodger blue for higher
                else if pitch < 0 { return Color(hex: "1E90FF").opacity(0.4) }  // Dodger blue darker for lower
                else { return Color.white }

            case 6:  // DECAY mode
                let decay = audioEngine.getStepDecay(step: keyIndex)
                if decay > 1.0 { return Color(hex: "FF8C00").opacity(0.7) }  // Dark orange for longer
                else if decay < 1.0 { return Color(hex: "FF8C00").opacity(0.4) }  // Darker for shorter
                else { return Color.white }

            case 7:  // CHAOS mode
                let isChaos = audioEngine.isStepChaos(step: keyIndex)
                return isChaos ? Color(hex: "FF1493") : Color.white  // Deep pink for chaos

            default:
                return Color.white
            }
        }

        // Normal keyboard mode
        return isPressed ? Color(hex: "FF69B4").opacity(0.3) : Color.white
    }
}

// Black key component
struct BlackKey: View {
    let isPressed: Bool
    let width: CGFloat
    let height: CGFloat

    var body: some View {
        Rectangle()
            .fill(isPressed ? Color(hex: "FF1493") : Color(hex: "FF69B4"))
            .frame(width: width, height: height)
            .overlay(
                Rectangle()
                    .stroke(Color.black, lineWidth: 2)
            )
    }
}

// Edit Step Key - Pink keyboard for edit mode
struct EditStepKey: View {
    @EnvironmentObject var audioEngine: AudioEngine
    let step: Int
    let width: CGFloat
    let height: CGFloat
    let editMode: Int

    var body: some View {
        Rectangle()
            .fill(getStepColor())
            .frame(width: width, height: height)
            .overlay(
                Rectangle()
                    .stroke(Color.black, lineWidth: 2)
            )
            .overlay(
                getStepLabel()
            )
            .contentShape(Rectangle())
            .onTapGesture {
                handleStepTap()
            }
    }

    private func handleStepTap() {
        switch editMode {
        case 0:  // COPY mode
            if audioEngine.copiedStepData != nil {
                // Paste to this step
                audioEngine.pasteStep(step: step)
            } else {
                // Copy this step
                audioEngine.copyStep(step: step)
            }

        case 1:  // CLEAR mode
            audioEngine.clearStep(step: step)

        case 6:  // ADSR mode - randomize ADSR for this step
            audioEngine.randomizeStep(step: step)

        case 7:  // CHAOS mode
            audioEngine.randomizeStep(step: step)

        default:
            break
        }

        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    private func getStepColor() -> Color {
        if editMode == 0 && audioEngine.copiedStepData?.col == step {
            return Color(hex: "FFD700")  // Gold for copied step
        } else {
            return Color(hex: "FF9999")  // Same pink as EDIT button
        }
    }

    @ViewBuilder
    private func getStepLabel() -> some View {
        Text("\(step + 1)")
            .font(.system(size: 10, weight: .bold, design: .monospaced))
            .foregroundColor(.white)
    }
}
