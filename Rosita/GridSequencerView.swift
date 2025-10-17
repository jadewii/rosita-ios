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
                                isPlaying: audioEngine.isPlaying && step == audioEngine.currentInstrumentPlayingStep,
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

                                // Play the selected sample to preview it (only if sequencer is NOT playing)
                                if !audioEngine.isPlaying {
                                    audioEngine.playNote(instrument: 3, note: [36, 38, 42, 46][drumType])
                                }
                            } else if audioEngine.isStepEditMode && audioEngine.getGridCell(row: track, col: step) {
                                // In STEP EDIT mode, toggle step selection for multi-select octave adjustment
                                audioEngine.toggleStepSelection(row: track, col: step)
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                // Note: Don't play sound when selecting in step edit mode
                            } else if audioEngine.isStepEditMode && !audioEngine.getGridCell(row: track, col: step) {
                                // STEP EDIT mode but cell is empty - flash to indicate can't place steps
                                // The flash effect is handled by the GridCell itself via isFlashing state
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            } else if !audioEngine.isStepEditMode {
                                // Normal mode: toggle grid cell
                                audioEngine.toggleGridCell(row: track, col: step)

                                // Play sound when placing a step (only if sequencer is NOT playing)
                                if audioEngine.getGridCell(row: track, col: step) && !audioEngine.isPlaying {
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

// Kit Browser View - shows kit selector + drum sound selection
struct KitBrowserView: View {
    @EnvironmentObject var audioEngine: AudioEngine

    // 16 kit colors - pastel rainbow colors matching drum grid aesthetic
    private func getKitColor(_ index: Int) -> Color {
        let colors: [Color] = [
            Color(hex: "FFB6C1"),  // Light Pink
            Color(hex: "FFE4B5"),  // Moccasin
            Color(hex: "FFDAB9"),  // Peach Puff
            Color(hex: "E0BBE4"),  // Lavender
            Color(hex: "C7CEEA"),  // Periwinkle
            Color(hex: "B5E7E7"),  // Light Cyan
            Color(hex: "D4F1F4"),  // Light Sky Blue
            Color(hex: "C1FFC1"),  // Pale Green
            Color(hex: "FFFACD"),  // Lemon Chiffon
            Color(hex: "FFE5CC"),  // Champagne
            Color(hex: "FFD6E8"),  // Light Rose
            Color(hex: "E6E6FA"),  // Lavender Blue
            Color(hex: "F0E68C"),  // Khaki
            Color(hex: "DDA0DD"),  // Plum
            Color(hex: "87CEEB"),  // Sky Blue
            Color(hex: "FFD700")   // Gold
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
            // Row 0: Kit selector (16 normal-sized squares with pink gridlines)
            HStack(spacing: 2) {
                ForEach(0..<16) { kitIndex in
                    Button(action: {
                        // Select this kit and load its sounds
                        audioEngine.selectKit(kitIndex)
                        // Play a preview sound (kick) only if sequencer is NOT playing
                        if !audioEngine.isPlaying {
                            audioEngine.playNote(instrument: 3, note: 36)
                        }
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    }) {
                        Rectangle()
                            .fill(getKitColor(kitIndex))
                            .overlay(
                                Rectangle()
                                    .stroke(audioEngine.currentKitIndex == kitIndex ? Color.white : Color(hex: "9370DB").opacity(0.6),
                                           lineWidth: audioEngine.currentKitIndex == kitIndex ? 3 : 2)
                            )
                            .aspectRatio(1.0, contentMode: .fit)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .transaction { t in t.animation = nil }
                }
            }

            // Rows 1-4: Sound selection for current kit (kick, snare, hat, perc)
            ForEach(0..<4) { drumType in
                HStack(spacing: 2) {
                    ForEach(0..<16) { step in
                        let maxSamples = [15, 16, 16, 10]  // Max samples per drum type
                        let sampleIndex = step % maxSamples[drumType]
                        let isSelected = audioEngine.getCurrentKitSounds()[drumType] == sampleIndex

                        KitSoundCell(
                            drumType: drumType,
                            sampleIndex: sampleIndex,
                            isSelected: isSelected,
                            drumColor: drumColors[drumType],
                            darkerColor: drumDarkerColors[drumType]
                        ) {
                            // Select this sound for the current kit
                            audioEngine.updateCurrentKitSound(drumType: drumType, sampleIndex: sampleIndex)

                            // Play the selected sample to preview it (only if sequencer is NOT playing)
                            if !audioEngine.isPlaying {
                                let note = [36, 38, 42, 46][drumType]
                                audioEngine.playNote(instrument: 3, note: note)
                            }
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        }
                    }
                }
            }
        }
        .padding(EdgeInsets(top: 0, leading: 8, bottom: 8, trailing: 8))
    }
}

// Kit Sound Cell - shows sound selection for kits (pink selection with white gridlines)
struct KitSoundCell: View {
    let drumType: Int
    let sampleIndex: Int
    let isSelected: Bool
    let drumColor: Color
    let darkerColor: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Rectangle()
                .fill(cellColor)
                .overlay(
                    Rectangle()
                        .stroke(Color.white.opacity(0.4), lineWidth: 1)  // White gridlines
                )
                .aspectRatio(1.0, contentMode: .fit)
        }
        .buttonStyle(PlainButtonStyle())
    }

    private var cellColor: Color {
        if isSelected {
            return Color(hex: "FFB6C1") // Pink for selected sample - same as drum track
        } else {
            return Color.white.opacity(0.6) // Lighter white for unselected - same as drum track
        }
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
                    // White flash when active step is playing
                    Rectangle()
                        .fill(Color.white.opacity(isActive && isPlaying ? 0.7 : 0))
                )
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
                    // White flash when active step is playing
                    Rectangle()
                        .fill(Color.white.opacity(isActive && isPlaying ? 0.7 : 0))
                )
                .overlay(
                    Rectangle()
                        .stroke(isActive ? getActiveOutlineColor() : darkerColor.opacity(0.4), lineWidth: isActive ? 3 : 1)
                )
                .overlay(
                    // Pastel red outline for selected step in STEP EDIT mode
                    Rectangle()
                        .stroke(isStepBeingEdited() ? Color(hex: "FF9999") : Color.clear, lineWidth: 3)
                )
                .overlay(
                    // Purple outline for multi-selected steps
                    Rectangle()
                        .stroke(audioEngine.isStepSelected(row: row, col: col) ? Color(hex: "9370DB") : Color.clear, lineWidth: 3)
                )
                .overlay(
                    // Playback cursor - thick white border
                    Rectangle()
                        .stroke(isPlaying ? Color.white : Color.clear, lineWidth: 4)
                )
                .aspectRatio(1.0, contentMode: .fit)
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
                // Show white when inactive, but with bar indicators every 4 steps
                if row < 4 {
                    // Beat indicators every 4 steps with different colors
                    if isBeatMarker {
                        switch col {
                        case 0: return Color(hex: "32CD32").opacity(0.3)  // Step 0 - Green
                        case 4: return Color(hex: "FFD700").opacity(0.3)  // Step 4 - Gold
                        case 8: return Color(hex: "FF6347").opacity(0.3)  // Step 8 - Tomato
                        case 12: return Color(hex: "9370DB").opacity(0.3) // Step 12 - Purple
                        default: return Color.white.opacity(0.9)
                        }
                    }
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

// FX Grid View - 8x16 grid matching main grid layout
struct FXGridView: View {
    @EnvironmentObject var audioEngine: AudioEngine

    // FX Colors - First two columns are red for Pitch and Filter
    private func getFXColor(row: Int, col: Int) -> Color {
        switch col {
        case 0:      return Color(hex: "FF3B30")  // Red - Pitch (+12 to -12)
        case 1:      return Color(hex: "FF3B30")  // Red - Low Pass Filter
        case 2, 3:   return Color(hex: "FF9500")  // Orange - Filters
        case 4, 5:   return Color(hex: "FFCC00")  // Yellow - Overdrive/Bit
        case 6, 7:   return Color(hex: "34C759")  // Green - Rearrange
        case 8, 9:   return Color(hex: "00C7BE")  // Cyan - Repeat
        case 10, 11: return Color(hex: "5E5CE6")  // Violet - Delay
        case 12, 13: return Color(hex: "AF52DE")  // Purple - Reverb
        case 14, 15: return Color(hex: "FF2D55")  // Pink - Loop
        default:     return Color.gray
        }
    }

    var body: some View {
        VStack(spacing: 2) {
            ForEach(0..<8) { row in
                HStack(spacing: 2) {
                    ForEach(0..<16) { col in
                        let fxIndex = row * 16 + col
                        let isBeatMarker = (col % 4 == 0)
                        let isActive = col == 0 ? (audioEngine.activeFXPitchRow == row) : (col == 1 ? (audioEngine.activeFXFilterRow == row) : (audioEngine.activePerformanceFX == fxIndex))

                        FXCell(
                            row: row,
                            col: col,
                            fxIndex: fxIndex,
                            isActive: isActive,
                            isPlaying: false,  // Don't show sequence playback on FX page
                            color: getFXColor(row: row, col: col),
                            isBeatMarker: isBeatMarker
                        ) {
                            if col == 0 {
                                // Column 0: Pitch control
                                if audioEngine.activeFXPitchRow == row {
                                    audioEngine.activeFXPitchRow = nil
                                } else {
                                    audioEngine.activeFXPitchRow = row
                                }
                            } else if col == 1 {
                                // Column 1: Filter control
                                if audioEngine.activeFXFilterRow == row {
                                    audioEngine.activeFXFilterRow = nil
                                    audioEngine.clearLowPassFilter()
                                } else {
                                    audioEngine.activeFXFilterRow = row
                                    audioEngine.applyLowPassFilter(row: row)
                                }
                            } else {
                                // Other columns: old performance FX system
                                if audioEngine.activePerformanceFX == fxIndex {
                                    audioEngine.deactivatePerformanceFX()
                                } else {
                                    audioEngine.activatePerformanceFX(presetIndex: fxIndex)
                                }
                            }
                        }
                    }
                }
            }
        }
        .padding(EdgeInsets(top: 0, leading: 8, bottom: 8, trailing: 8))
    }
}

// FX Cell - matching GridCell style
struct FXCell: View {
    let row: Int
    let col: Int
    let fxIndex: Int
    let isActive: Bool
    let isPlaying: Bool
    let color: Color
    let isBeatMarker: Bool
    let action: () -> Void

    var body: some View {
        Rectangle()
            .fill(cellColor)
            .overlay(
                Rectangle()
                    .stroke(Color.white, lineWidth: isActive ? 3 : 1)
            )
            .aspectRatio(1.0, contentMode: .fit)
            .contentShape(Rectangle())
            .onTapGesture {
                action()
            }
    }

    private var cellColor: Color {
        if isActive {
            return color
        } else {
            if isBeatMarker {
                return color.opacity(0.15)
            } else {
                return color.opacity(0.3)
            }
        }
    }
}