import SwiftUI

struct GridSequencerView: View {
    @EnvironmentObject var audioEngine: AudioEngine
    
    // Get instrument colors from InstrumentType
    private func getInstrumentColor(for instrumentIndex: Int) -> Color {
        guard let instrumentType = InstrumentType(rawValue: instrumentIndex) else {
            return Color.gray
        }
        return instrumentType.color
    }
    
    // Get darker shade for active steps
    private func getDarkerShade(of color: Color) -> Color {
        // Convert to darker version for active steps
        switch color {
        case Color(hex: "FFB6C1"): return Color(hex: "FF1493") // Pink -> Deep Pink
        case Color(hex: "87CEEB"): return Color(hex: "1E90FF") // Sky Blue -> Dodger Blue
        case Color(hex: "DDA0DD"): return Color(hex: "9370DB") // Plum -> Medium Purple
        case Color(hex: "FFD700"): return Color(hex: "FFA500") // Gold -> Orange
        default: return color.opacity(0.7)
        }
    }
    
    // Get even darker shade for outlines
    private func getOutlineColor(for color: Color) -> Color {
        switch color {
        case Color(hex: "FFB6C1"): return Color(hex: "C71585") // Pink -> Medium Violet Red
        case Color(hex: "87CEEB"): return Color(hex: "4682B4") // Sky Blue -> Steel Blue
        case Color(hex: "DDA0DD"): return Color(hex: "6A0DAD") // Plum -> Dark Purple
        case Color(hex: "FFD700"): return Color(hex: "FF8C00") // Gold -> Dark Orange
        default: return color.opacity(0.5)
        }
    }
    
    var body: some View {
        if audioEngine.isFXMode {
            // FX mode - show performance effects grid
            FXGridView()
        } else if audioEngine.isKitBrowserMode {
            // Kit Browser mode - show kit selector + 4 drum tracks
            KitBrowserView()
        } else {
            // Main sequencer grid - 8 tracks x 16 steps
            VStack(spacing: 2) {
                ForEach(0..<8) { track in
                    HStack(spacing: 2) {
                        ForEach(0..<16) { step in
                            let isBeatMarker = (step % 4 == 0)
                            GridCell(
                                row: track,
                                col: step,
                                isActive: audioEngine.getGridCell(row: track, col: step),
                                isPlaying: audioEngine.isPlaying && step == audioEngine.currentPlayingStep,
                                selectedInstrument: audioEngine.selectedInstrument,
                                instrumentColor: getInstrumentColor(for: audioEngine.selectedInstrument),
                                darkerColor: getDarkerShade(of: getInstrumentColor(for: audioEngine.selectedInstrument)),
                                octave: audioEngine.getGridCellOctave(row: track, col: step),
                                velocity: audioEngine.getGridCellVelocity(row: track, col: step),
                                isBeatMarker: isBeatMarker,
                                selectedDrumSamples: audioEngine.selectedDrumSamples
                            ) {
                            // For drums (instrument 3), rows 4-7 select sample variants
                            if audioEngine.selectedInstrument == 3 && track >= 4 && track <= 7 {
                                // Rows 4-7 select samples for drum types 0-3
                                // Row 4 selects kicks, Row 5 selects snares, Row 6 selects hats, Row 7 selects percs
                                let drumType = track - 4  // 0=kick, 1=snare, 2=hat, 3=perc
                                let maxSamples = [15, 16, 16, 10]  // Max samples per drum type (kicks missing #5)

                                // Map step 0-15 to sample indices directly
                                // Step 0 = sample 0, step 1 = sample 1, etc.
                                // For steps beyond available samples, wrap around
                                let sampleIndex = step % maxSamples[drumType]
                                audioEngine.selectedDrumSamples[drumType] = sampleIndex

                                // Play the selected sample to preview it
                                audioEngine.playNote(instrument: 3, note: [36, 38, 42, 46][drumType])
                            } else if audioEngine.isStepEditMode && audioEngine.getGridCell(row: track, col: step) {
                                // In STEP EDIT mode, select step for editing instead of toggling
                                if audioEngine.selectedInstrument == 3 && track < 4 {
                                    // Drums - start drum pitch edit
                                    audioEngine.startDrumPitchEdit(row: track, col: step)
                                } else {
                                    // Melodic instruments - start melodic pitch edit
                                    audioEngine.startMelodicStepEdit(row: track, col: step)
                                }

                                // Play the note to preview
                                let note: Int
                                if audioEngine.selectedInstrument == 3 && track < 4 {
                                    note = [36, 38, 42, 46][track]
                                } else {
                                    let baseNote = audioEngine.rowToNote(row: track, instrument: audioEngine.selectedInstrument)
                                    let octaveOffset = audioEngine.trackOctaveOffsets[audioEngine.selectedInstrument] * 12
                                    note = baseNote + audioEngine.gridTranspose + octaveOffset
                                }
                                audioEngine.playNote(instrument: audioEngine.selectedInstrument, note: note)
                            } else if audioEngine.isStepEditMode && !audioEngine.getGridCell(row: track, col: step) {
                                // STEP EDIT mode but cell is empty - flash to indicate can't place steps
                                // The flash effect is handled by the GridCell itself via isFlashing state
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            } else if !audioEngine.isStepEditMode {
                                // Normal mode: toggle grid cell
                                audioEngine.toggleGridCell(row: track, col: step)

                                // Play sound when placing a step
                                if audioEngine.getGridCell(row: track, col: step) {
                                    // For drums (rows 0-3), use drum MIDI notes
                                    let note: Int
                                    if audioEngine.selectedInstrument == 3 && track < 4 {
                                        // Drum notes: Kick=36, Snare=38, Hat=42, Perc=46
                                        note = [36, 38, 42, 46][track]
                                    } else {
                                        // Melodic instruments - use scale-based note calculation
                                        let baseNote = audioEngine.rowToNote(row: track, instrument: audioEngine.selectedInstrument)
                                        let octaveOffset = audioEngine.trackOctaveOffsets[audioEngine.selectedInstrument] * 12
                                        note = baseNote + audioEngine.gridTranspose + octaveOffset
                                    }
                                    audioEngine.playNote(instrument: audioEngine.selectedInstrument, note: note)
                                }
                            }
                        } longPressAction: {
                            audioEngine.showVelocityEditor(row: track, col: step)
                        }
                    }
                }
            }
        }
        .padding(EdgeInsets(top: 0, leading: 8, bottom: 8, trailing: 8))
        }
    }
}

// Kit Browser View - shows kit selector + drum tracks
struct KitBrowserView: View {
    @EnvironmentObject var audioEngine: AudioEngine

    // 16 kit colors - gradient from gold through orange to red
    private func getKitColor(_ index: Int) -> Color {
        let colors: [Color] = [
            Color(hex: "FFD700"),  // Gold
            Color(hex: "FFC700"),
            Color(hex: "FFB700"),
            Color(hex: "FFA700"),
            Color(hex: "FF9700"),  // Orange
            Color(hex: "FF8700"),
            Color(hex: "FF7700"),
            Color(hex: "FF6700"),
            Color(hex: "FF5700"),  // Orange-Red
            Color(hex: "FF4700"),
            Color(hex: "FF3700"),
            Color(hex: "FF2700"),
            Color(hex: "FF1700"),  // Red
            Color(hex: "FF0700"),
            Color(hex: "F70000"),
            Color(hex: "E70000")
        ]
        return colors[index]
    }

    // Drum track colors
    private let drumColors: [Color] = [
        Color(hex: "87CEEB"),  // Kick - Sky Blue
        Color(hex: "FFD700"),  // Snare - Gold
        Color(hex: "FFA500"),  // Hat - Orange
        Color(hex: "DDA0DD")   // Perc - Purple
    ]

    private let drumDarkerColors: [Color] = [
        Color(hex: "1E90FF"),  // Kick darker
        Color(hex: "FFA500"),  // Snare darker
        Color(hex: "FF8C00"),  // Hat darker
        Color(hex: "9370DB")   // Perc darker
    ]

    var body: some View {
        VStack(spacing: 2) {
            // Row 0: Kit selector (16 normal-sized squares)
            HStack(spacing: 2) {
                ForEach(0..<16) { kitIndex in
                    Button(action: {
                        // Select this kit
                        audioEngine.instrumentWaveforms[3] = kitIndex
                        // Play a preview sound
                        audioEngine.playNote(instrument: 3, note: 36)
                    }) {
                        Rectangle()
                            .fill(getKitColor(kitIndex))
                            .overlay(
                                Rectangle()
                                    .stroke(audioEngine.instrumentWaveforms[3] == kitIndex ? Color.white : Color.black.opacity(0.3),
                                           lineWidth: audioEngine.instrumentWaveforms[3] == kitIndex ? 3 : 1)
                            )
                            .aspectRatio(1.0, contentMode: .fit)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .transaction { t in t.animation = nil }
                }
            }

            // Rows 1-4: Drum tracks (kick, snare, hat, perc) - 16 steps each
            ForEach(0..<4) { drumTrack in
                HStack(spacing: 2) {
                    ForEach(0..<16) { step in
                        let isBeatMarker = (step % 4 == 0)
                        KitGridCell(
                            drumTrack: drumTrack,
                            step: step,
                            isActive: audioEngine.getGridCell(row: drumTrack, col: step),
                            isPlaying: audioEngine.isPlaying && step == audioEngine.currentPlayingStep,
                            drumColor: drumColors[drumTrack],
                            darkerColor: drumDarkerColors[drumTrack],
                            isBeatMarker: isBeatMarker
                        ) {
                            // Toggle drum step
                            audioEngine.toggleGridCell(row: drumTrack, col: step)

                            // Play sound when placing a step
                            if audioEngine.getGridCell(row: drumTrack, col: step) {
                                let note = [36, 38, 42, 46][drumTrack]
                                audioEngine.playNote(instrument: 3, note: note)
                            }
                        }
                    }
                }
            }
        }
        .padding(EdgeInsets(top: 0, leading: 8, bottom: 8, trailing: 8))
    }
}

// Kit Grid Cell - simplified cell for kit browser
struct KitGridCell: View {
    let drumTrack: Int
    let step: Int
    let isActive: Bool
    let isPlaying: Bool
    let drumColor: Color
    let darkerColor: Color
    var isBeatMarker: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Rectangle()
                .fill(cellColor)
                .overlay(
                    Rectangle()
                        .stroke(isActive ? darkerColor.opacity(0.8) : darkerColor.opacity(0.4), lineWidth: isActive ? 3 : 1)
                )
                .overlay(
                    // Playing indicator
                    Rectangle()
                        .stroke(isPlaying ? Color.white : Color.clear, lineWidth: 2)
                        .scaleEffect(isPlaying ? 1.05 : 1.0)
                        .opacity(isPlaying ? 1.0 : 0.0)
                )
                .aspectRatio(1.0, contentMode: .fit)
                .scaleEffect(isPlaying ? 1.08 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
    }

    private var cellColor: Color {
        if isActive {
            return darkerColor
        } else {
            if isBeatMarker {
                return darkerColor.opacity(0.15)
            } else {
                return drumColor.opacity(0.3)
            }
        }
    }
}

struct GridCell: View {
    let row: Int
    let col: Int
    let isActive: Bool
    let isPlaying: Bool
    let selectedInstrument: Int
    let instrumentColor: Color
    let darkerColor: Color
    let octave: Int
    let velocity: Float
    var isBeatMarker: Bool = false
    let selectedDrumSamples: [Int]
    let action: () -> Void
    let longPressAction: () -> Void

    @State private var longPressTimer: Timer?
    @State private var isLongPressing = false
    @State private var isFlashing = false
    @EnvironmentObject var audioEngine: AudioEngine

    var body: some View {
        Button(action: {
            // Only fire action if not long pressing
            if !isLongPressing {
                // Check if in STEP EDIT mode with empty cell - trigger flash
                if audioEngine.isStepEditMode && !isActive {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        isFlashing = true
                    }
                    // Reset flash after animation
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            isFlashing = false
                        }
                    }
                }
                action()
            }
        }) {
            Rectangle()
                .fill(cellColor)
                .overlay(
                    Rectangle()
                        .stroke(isActive ? getActiveOutlineColor() : darkerColor.opacity(0.4), lineWidth: isActive ? 3 : 1)
                )
                .overlay(
                    // Orange outline for selected step in STEP EDIT mode
                    Rectangle()
                        .stroke(isStepBeingEdited() ? Color(hex: "FFA500") : Color.clear, lineWidth: 3)
                )
                .overlay(
                    // Playing indicator - clean white border with pulse
                    Rectangle()
                        .stroke(isPlaying ? Color.white : Color.clear, lineWidth: 2)
                        .scaleEffect(isPlaying ? 1.05 : 1.0)
                        .opacity(isPlaying ? 1.0 : 0.0)
                )
                .aspectRatio(1.0, contentMode: .fit)
                .scaleEffect(isPlaying ? 1.08 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .simultaneousGesture(
            audioEngine.isStepEditMode ? nil :
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if longPressTimer == nil {
                        // Start timer on press
                        longPressTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { _ in
                            // Long press detected
                            isLongPressing = true
                            // Show velocity editor
                            longPressAction()
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
    }
    
    private func isStepBeingEdited() -> Bool {
        // Check if this step is currently selected for editing in STEP EDIT mode
        if selectedInstrument == 3 && row < 4 {
            // Drums
            if let editingStep = audioEngine.editingDrumStep {
                return editingStep.row == row && editingStep.col == col
            }
        } else {
            // Melodic instruments
            if let editingStep = audioEngine.editingStep {
                return editingStep.row == row && editingStep.col == col
            }
        }
        return false
    }

    private func getActiveOutlineColor() -> Color {
        // For drums, always use pink outline
        if selectedInstrument == 3 {
            return Color(hex: "C71585") // Pink outline for drums
        }

        // Return an even darker shade than the cell color for better contrast
        switch instrumentColor {
        case Color(hex: "FFB6C1"): return Color(hex: "C71585") // Pink -> Medium Violet Red
        case Color(hex: "87CEEB"): return Color(hex: "4682B4") // Sky Blue -> Steel Blue
        case Color(hex: "DDA0DD"): return Color(hex: "6A0DAD") // Plum -> Dark Purple
        case Color(hex: "FFD700"): return Color(hex: "FF8C00") // Gold -> Dark Orange
        default: return darkerColor.opacity(0.8)
        }
    }
    
    private var cellColor: Color {
        // Flash white when tapped in STEP EDIT mode on empty cell
        if isFlashing {
            return Color.white
        }

        // Special handling for drums (instrument 4 = index 3)
        if selectedInstrument == 3 { // Drums
            if isActive {
                // Rows 0-3: Show colored steps when active
                if row < 4 {
                    switch row {
                    case 0: return Color(hex: "87CEEB") // Kick - Sky Blue
                    case 1: return Color(hex: "FFD700") // Snare - Yellow/Gold
                    case 2: return Color(hex: "FFA500") // Hi-hat - Orange
                    case 3: return Color(hex: "DDA0DD") // Percussion - Purple (Plum)
                    default: return darkerColor
                    }
                } else {
                    return darkerColor
                }
            } else {
                // Show white when inactive
                if row < 4 {
                    return Color.white.opacity(0.9) // Rows 0-3: White background
                } else {
                    // Rows 4-7: Sample selection area - lighter white background, pink for selected
                    if row >= 4 && row <= 7 {
                        let drumType = row - 4  // 0=kick, 1=snare, 2=hat, 3=perc
                        let maxSamples = [15, 16, 16, 10]
                        let sampleIndex = col % maxSamples[drumType]

                        // Check if this is the currently selected sample for this drum type
                        if selectedDrumSamples[drumType] == sampleIndex {
                            return Color(hex: "FFB6C1") // Pink for selected sample
                        } else {
                            return Color.white.opacity(0.6) // Lighter white for unselected
                        }
                    }
                    return Color.white.opacity(0.6)
                }
            }
        } else {
            // All other instruments: use the selected instrument's color scheme with octave shading
            if isActive {
                // Adjust color brightness based on octave
                switch octave {
                case -2: return darkerColor.opacity(0.5)  // Very low octave
                case -1: return darkerColor.opacity(0.7)  // Low octave
                case 0: return darkerColor                 // Base octave
                case 1: return instrumentColor.opacity(0.9)   // High octave - use base color lighter
                case 2: return instrumentColor.opacity(0.8)   // Very high octave - even lighter base
                default: return darkerColor
                }
            } else {
                // For beat markers (steps 4, 8, 12), use darker shade of instrument color
                if isBeatMarker {
                    return darkerColor.opacity(0.15)
                } else {
                    return instrumentColor.opacity(0.3)
                }
            }
        }
    }
}

// FX Grid View - 8x8 grid of performance effects
struct FXGridView: View {
    @EnvironmentObject var audioEngine: AudioEngine

    // Define all 64 performance effects
    let fxNames: [[String]] = [
        ["DELAY", "REVERB", "FILT LP", "FILT HP", "ECHO", "CHORUS", "FLANGE", "PHASE"],
        ["DIST", "CRUSH", "RING", "GLITCH", "STUTTER", "REPEAT", "SLICE", "GATE"],
        ["PITCH+", "PITCH-", "SHIFT", "HARM", "VIBRATO", "TREMOLO", "WARP", "BEND"],
        ["SLOW", "FAST", "HALF", "DBL", "REVERSE", "TAPE", "VINYL", "LOFI"],
        ["PAN L", "PAN R", "AUTO", "WIDTH", "FREEZE", "HOLD", "ROLL", "REGEN"],
        ["RND P", "RND V", "RND T", "CHANCE", "SCATTER", "CHAOS", "MUTATE", "EVOLVE"],
        ["COMP", "LIMIT", "SAT", "WARM", "BRIGHT", "DARK", "BOOST", "REDUCE"],
        ["SEQ+", "SEQ-", "SKIP", "FILL", "SHIFT>", "SHIFT<", "ROTATE", "MIRROR"]
    ]

    // Colors for each row
    let rowColors: [Color] = [
        Color(hex: "FFD700"),  // Row 1 - Gold (Time-based)
        Color(hex: "FF6347"),  // Row 2 - Tomato (Distortion)
        Color(hex: "9370DB"),  // Row 3 - Purple (Pitch)
        Color(hex: "32CD32"),  // Row 4 - Green (Speed)
        Color(hex: "FF69B4"),  // Row 5 - Hot Pink (Spatial)
        Color(hex: "FF8C00"),  // Row 6 - Dark Orange (Random)
        Color(hex: "87CEEB"),  // Row 7 - Sky Blue (Dynamics)
        Color(hex: "DDA0DD")   // Row 8 - Plum (Pattern)
    ]

    var body: some View {
        VStack(spacing: 2) {
            ForEach(0..<8) { row in
                HStack(spacing: 2) {
                    ForEach(0..<8) { col in
                        let fxIndex = row * 8 + col
                        FXButton(
                            label: fxNames[row][col],
                            fxIndex: fxIndex,
                            isActive: audioEngine.activePerformanceFX == fxIndex,
                            color: rowColors[row]
                        ) {
                            // Toggle FX - only one can be active at a time
                            if audioEngine.activePerformanceFX == fxIndex {
                                audioEngine.activePerformanceFX = nil
                            } else {
                                audioEngine.activePerformanceFX = fxIndex
                            }
                        }
                    }
                }
            }
        }
        .padding(EdgeInsets(top: 0, leading: 8, bottom: 8, trailing: 8))
    }
}

// FX Button
struct FXButton: View {
    let label: String
    let fxIndex: Int
    let isActive: Bool
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Rectangle()
                .fill(isActive ? color : Color.black)
                .overlay(
                    Text(label)
                        .font(.system(size: 8, weight: .bold, design: .monospaced))
                        .foregroundColor(isActive ? .black : .white)
                        .minimumScaleFactor(0.5)
                        .lineLimit(1)
                )
                .overlay(
                    Rectangle()
                        .stroke(isActive ? Color.white : color.opacity(0.5), lineWidth: isActive ? 3 : 1)
                )
                .aspectRatio(1.0, contentMode: .fit)
        }
        .buttonStyle(PlainButtonStyle())
    }
}