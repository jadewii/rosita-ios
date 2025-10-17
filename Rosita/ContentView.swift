import SwiftUI

struct ContentView: View {
    @EnvironmentObject var audioEngine: AudioEngine
    @State private var showHelp = false
    @State private var showExportAlert = false
    @State private var showLayoutEditor = false
    @State private var isEditMode = false
    @State private var octaveMode: OctaveMode = .grid // GRD is default
    @State private var stpLongPressTimer: Timer?
    @State private var stpFlashPurple = false
    @State private var plusButtonPressed = false
    @State private var minusButtonPressed = false
    @State private var keyboardOffsetX: Double = 0
    @State private var keyboardOffsetY: Double = -72
    @State private var octaveButtonOffsetY: Double = -95

    // Base positions for keyboard and octave (for drag accumulation)
    @State private var keyboardBaseX: Double = 0
    @State private var keyboardBaseY: Double = -72
    @State private var octaveButtonBaseX: Double = 0
    @State private var octaveButtonBaseY: Double = -95
    @State private var octaveButtonOffsetX: Double = 0

    // Draggable element positions (current display offset)
    @State private var oscilloscopeOffset = CGSize.zero
    @State private var instrumentSelectorOffset = CGSize.zero
    @State private var adsrOffset = CGSize.zero
    @State private var effectsOffset = CGSize.zero
    @State private var playStopRecOffset = CGSize.zero
    @State private var transport6ButtonsOffset = CGSize.zero
    @State private var patternSlotsOffset = CGSize.zero  // Includes DUP button
    @State private var allTransportControlsOffset = CGSize.zero  // Unified offset for Play through DUP
    @State private var bpmSliderOffset = CGSize.zero
    @State private var wavButtonOffset = CGSize.zero
    @State private var helpButtonOffset = CGSize.zero
    @State private var utilityButtonsOffset = CGSize.zero  // EDIT/WAV/? group


    // Base positions (persistent across drags)
    @State private var oscilloscopeBase = CGSize.zero
    @State private var utilityButtonsBase = CGSize.zero  // Base for utility group
    @State private var instrumentSelectorBase = CGSize.zero
    @State private var adsrBase = CGSize.zero
    @State private var effectsBase = CGSize.zero
    @State private var playStopRecBase = CGSize.zero
    @State private var transport6ButtonsBase = CGSize.zero
    @State private var patternSlotsBase = CGSize.zero  // Includes DUP button
    @State private var allTransportControlsBase = CGSize.zero  // Unified base for Play through DUP
    @State private var bpmSliderBase = CGSize.zero
    @State private var wavButtonBase = CGSize.zero
    @State private var helpButtonBase = CGSize.zero

    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.verticalSizeClass) var verticalSizeClass

    enum OctaveMode {
        case keyboard  // Controls transpose (keyboard octave)
        case grid      // Controls gridTranspose (grid octave)
        case stepEdit  // Controls single step pitch (in step edit mode)
        case sequence  // Controls entire grid octave (in step edit mode)
    }
    
    var body: some View {
        GeometryReader { geometry in
            let isCompact = geometry.size.width < 1100
            let isPhone = geometry.size.width < 800
            let scaleFactor = isPhone ? 0.7 : (isCompact ? 0.85 : 1.0)
            
            VStack(spacing: 0) {
                // Add small pink space at top
                Spacer()
                    .frame(height: 56)
                
                // 🔝 Top Controls - FIXED HEIGHT
                VStack(spacing: 0) {
                    // Transport controls row - all buttons in order
                    HStack(spacing: 8) {
                        // All transport controls from Play to DUP as one unified draggable group
                        HStack(spacing: 6) {
                            PlayStopRecButtons()
                                .disabled(isEditMode)

                            Transport6Buttons()
                                .disabled(isEditMode)

                            // Pattern buttons + DUP
                            Pattern8Buttons()
                            DupButton()
                        }
                        .offset(allTransportControlsOffset)
                        .animation(nil, value: allTransportControlsOffset)
                        .overlay(
                            isEditMode ?
                            Rectangle()
                                .stroke(Color(hex: "FF1493"), lineWidth: 3)
                            : nil
                        )
                        .simultaneousGesture(
                            isEditMode ?
                            DragGesture(minimumDistance: 0)
                                .onChanged { gesture in
                                    allTransportControlsOffset = CGSize(
                                        width: allTransportControlsBase.width + gesture.translation.width,
                                        height: allTransportControlsBase.height + gesture.translation.height
                                    )
                                }
                                .onEnded { gesture in
                                    allTransportControlsBase = allTransportControlsOffset
                                }
                            : nil
                        )
                        .zIndex(100)

                        Spacer()

                        // BPM slider OR Pitch slider (when editing pitch)
                        HStack(spacing: 8) {
                            if audioEngine.isDrumPitchEditMode {
                                // Drum pitch slider (0.5x to 2.0x)
                                CustomSlider(
                                    value: $audioEngine.drumStepPitch,
                                    range: 0.5...2.0,
                                    trackColor: Color(hex: "FFD700"),
                                    label: "",
                                    onlyUpdateOnRelease: false
                                )
                                .frame(width: 120, height: 30)
                                .onChange(of: audioEngine.drumStepPitch) { newPitch in
                                    // Apply pitch to selected drum step and play preview
                                    if let step = audioEngine.editingDrumStep {
                                        audioEngine.setDrumPitch(row: step.row, col: step.col, pitch: newPitch)

                                        // Play preview of the drum sound at this pitch
                                        let drumNote = [36, 38, 42, 46][step.row]
                                        audioEngine.playDrumSound(drumType: drumNote, pitch: newPitch)
                                    }
                                }

                                Text(String(format: "%.2f", audioEngine.drumStepPitch))
                                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                                    .foregroundColor(.black)
                                    .frame(width: 42, height: 24)
                                    .background(
                                        Rectangle()
                                            .fill(Color(hex: "FFD700"))
                                            .overlay(
                                                Rectangle()
                                                    .stroke(Color.black, lineWidth: 2)
                                            )
                                    )
                            } else if audioEngine.isStepEditMode {
                                // Melodic pitch slider (-24 to +24 semitones, octave snapped)
                                CustomSlider(
                                    value: $audioEngine.stepPitch,
                                    range: -24...24,
                                    trackColor: Color(hex: "32CD32"),
                                    label: "",
                                    onlyUpdateOnRelease: false
                                )
                                .frame(width: 120, height: 30)
                                .onChange(of: audioEngine.stepPitch) { newPitch in
                                    // Apply pitch to selected step and play preview
                                    if let step = audioEngine.editingStep {
                                        // Round to nearest octave (12 semitones)
                                        let roundedPitch = round(newPitch / 12.0) * 12.0
                                        audioEngine.setMelodicPitch(row: step.row, col: step.col, instrument: audioEngine.selectedInstrument, pitch: roundedPitch)

                                        // Play preview note at the new pitch
                                        let baseNote = audioEngine.rowToNote(row: step.row, instrument: audioEngine.selectedInstrument)
                                        let octaveOffset = audioEngine.trackOctaveOffsets[audioEngine.selectedInstrument] * 12
                                        let note = baseNote + audioEngine.gridTranspose + octaveOffset + Int(roundedPitch)
                                        audioEngine.playNote(instrument: audioEngine.selectedInstrument, note: note)
                                    }
                                }

                                Text(String(format: "%+d", Int(audioEngine.stepPitch)))
                                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                                    .foregroundColor(.black)
                                    .frame(width: 42, height: 24)
                                    .background(
                                        Rectangle()
                                            .fill(Color(hex: "32CD32"))
                                            .overlay(
                                                Rectangle()
                                                    .stroke(Color.black, lineWidth: 2)
                                            )
                                    )
                            } else {
                                // BPM slider (normal mode)
                                CustomSlider(
                                    value: $audioEngine.bpm,
                                    range: 60...200,
                                    trackColor: Color(hex: "FF1493"),
                                    label: "",
                                    onlyUpdateOnRelease: true
                                )
                                .frame(width: 120, height: 30)

                                Text("\(Int(audioEngine.bpm))")
                                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                                    .foregroundColor(.black)
                                    .frame(width: 42, height: 24)
                                    .background(
                                        Rectangle()
                                            .fill(Color.white)
                                            .overlay(
                                                Rectangle()
                                                    .stroke(Color.black, lineWidth: 2)
                                            )
                                    )
                            }
                        }
                        .disabled(isEditMode)
                        .padding(.trailing, 12)
                        .offset(bpmSliderOffset)
                        .animation(nil, value: bpmSliderOffset)
                        .overlay(
                            isEditMode ?
                            Rectangle()
                                .stroke(Color(hex: "FF1493"), lineWidth: 3)
                                .padding(.trailing, 12)
                            : nil
                        )
                        .simultaneousGesture(
                            isEditMode ?
                            DragGesture(minimumDistance: 0)
                                .onChanged { gesture in
                                    bpmSliderOffset = CGSize(
                                        width: bpmSliderBase.width + gesture.translation.width,
                                        height: bpmSliderBase.height + gesture.translation.height
                                    )
                                }
                                .onEnded { gesture in
                                    bpmSliderBase = bpmSliderOffset
                                }
                            : nil
                        )
                        .zIndex(100)
                    }
                    .padding(.horizontal, 0)

                    // Add spacing to move pattern buttons down
                    Spacer()
                        .frame(height: 25)

                    // Instrument and control buttons row
                    HStack(spacing: 16) {
                        HStack {
                            // Empty space for left panel
                        }
                        .frame(width: 190)

                        Spacer()

                        // Oscilloscope centered
                        OscilloscopeView()
                            .frame(width: 210, height: 76)
                            .offset(oscilloscopeOffset)
                            .animation(nil, value: oscilloscopeOffset)
                            .overlay(
                                isEditMode ?
                                Rectangle()
                                    .stroke(Color(hex: "FF1493"), lineWidth: 3)
                                    .frame(width: 210, height: 76)
                                : nil
                            )
                            .simultaneousGesture(
                                isEditMode ?
                                DragGesture(minimumDistance: 0)
                                    .onChanged { gesture in
                                        oscilloscopeOffset = CGSize(
                                            width: oscilloscopeBase.width + gesture.translation.width,
                                            height: oscilloscopeBase.height + gesture.translation.height
                                        )
                                    }
                                    .onEnded { gesture in
                                        oscilloscopeBase = oscilloscopeOffset
                                    }
                                : nil
                            )
                            .zIndex(100)

                        Spacer()
                    }
                    .padding(.horizontal, 0)
                }
                .frame(height: 100)
                
                // 🎯 SMALL GAP BETWEEN PATTERN BUTTONS AND GRID
                Spacer()
                    .frame(height: 53)  // Reduced by 7 to move everything up
                
                // 🎯 MAIN CONTENT - FILL REMAINING SPACE NATURALLY
                HStack(alignment: .top, spacing: 0) {
                    // Left Sidebar - START AT TOP
                    VStack(alignment: .leading, spacing: 12) {
                        // Instrument selector
                        InstrumentSelectorView()
                            .disabled(isEditMode)
                            .offset(instrumentSelectorOffset)
                            .animation(nil, value: instrumentSelectorOffset)
                            .overlay(
                                isEditMode ?
                                Rectangle()
                                    .stroke(Color(hex: "FF1493"), lineWidth: 3)
                                : nil
                            )
                            .simultaneousGesture(
                                isEditMode ?
                                DragGesture(minimumDistance: 0)
                                    .onChanged { gesture in
                                        instrumentSelectorOffset = CGSize(
                                            width: instrumentSelectorBase.width + gesture.translation.width,
                                            height: instrumentSelectorBase.height + gesture.translation.height
                                        )
                                    }
                                    .onEnded { gesture in
                                        instrumentSelectorBase = instrumentSelectorOffset
                                    }
                                : nil
                            )
                            .zIndex(100)

                        // ADSR section
                        VStack(spacing: 0) {
                            Text("ADSR (TRACK \(audioEngine.selectedInstrument + 1))")
                                .font(.system(size: 12, weight: .bold, design: .monospaced))
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding(.vertical, 4)
                                .background(Color.white.opacity(0.3))

                            ADSRView()
                                .disabled(isEditMode)
                        }
                        .background(
                            Rectangle()
                                .fill(Color.white.opacity(0.8))
                                .overlay(
                                    Rectangle()
                                        .stroke(isEditMode ? Color(hex: "FF1493") : Color.black, lineWidth: 3)
                                )
                        )
                        .offset(adsrOffset)
                        .animation(nil, value: adsrOffset)
                        .simultaneousGesture(
                            isEditMode ?
                            DragGesture(minimumDistance: 0)
                                .onChanged { gesture in
                                    adsrOffset = CGSize(
                                        width: adsrBase.width + gesture.translation.width,
                                        height: adsrBase.height + gesture.translation.height
                                    )
                                }
                                .onEnded { gesture in
                                    adsrBase = adsrOffset
                                }
                            : nil
                        )
                        .zIndex(100)

                        // Effects section
                        EffectsView()
                            .disabled(isEditMode)
                            .offset(effectsOffset)
                            .animation(nil, value: effectsOffset)
                            .overlay(
                                isEditMode ?
                                Rectangle()
                                    .stroke(Color(hex: "FF1493"), lineWidth: 3)
                                : nil
                            )
                            .simultaneousGesture(
                                isEditMode ?
                                DragGesture(minimumDistance: 0)
                                    .onChanged { gesture in
                                        effectsOffset = CGSize(
                                            width: effectsBase.width + gesture.translation.width,
                                            height: effectsBase.height + gesture.translation.height
                                        )
                                    }
                                    .onEnded { gesture in
                                        effectsBase = effectsOffset
                                    }
                                : nil
                            )
                            .zIndex(100)

                        Spacer()
                    }
                    .frame(width: 190)  // Further reduced to prevent right cutoff

                    // Grid Area - always at the back, disabled in edit mode
                    GridSequencerView()
                        .zIndex(-1)
                        .allowsHitTesting(!isEditMode)
                }
                
                // Add space above keyboard
                Spacer()
                    .frame(height: 30)
                
                // 🎹 KEYBOARD - FULL WIDTH, OUTSIDE OF HSTACK
                PianoKeyboardView()
                    .disabled(isEditMode)
                    .frame(maxWidth: .infinity)
                    .frame(height: 140)  // Bigger to show all keys
                    .padding(.horizontal, 0)
                    .offset(x: CGFloat(keyboardOffsetX), y: CGFloat(keyboardOffsetY))
                    .animation(nil, value: keyboardOffsetX)
                    .animation(nil, value: keyboardOffsetY)
                    .overlay(
                        isEditMode ?
                        Rectangle()
                            .stroke(Color(hex: "FF1493"), lineWidth: 3)
                            .frame(height: 140)
                        : nil
                    )
                    .simultaneousGesture(
                        isEditMode ?
                        DragGesture(minimumDistance: 0)
                            .onChanged { gesture in
                                keyboardOffsetX = keyboardBaseX + Double(gesture.translation.width)
                                keyboardOffsetY = keyboardBaseY + Double(gesture.translation.height)
                            }
                            .onEnded { gesture in
                                keyboardBaseX = keyboardOffsetX
                                keyboardBaseY = keyboardOffsetY
                            }
                        : nil
                    )
                    .zIndex(100)
                
                // Small bottom margin
                Spacer()
                    .frame(height: 30)  // More space to separate keyboard from black edge
            }
            .padding(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 4))  // Small right padding to prevent cutoff
            .background(Color(hex: "FFB6C1"))
            .overlay(overlaysView)
            .overlay(
                // KB/GRD/STP Octave controls - independently draggable
                HStack(spacing: 4) {
                    // Mode toggle button - KB=orange, GRD=blue, STP=pastel red (no toggle in step edit)
                    RetroButton(
                        title: audioEngine.isStepEditMode ? "STP" : (octaveMode == .keyboard ? "KB" : "GRD"),
                        color: audioEngine.isStepEditMode ? (stpFlashPurple ? Color(hex: "9370DB") : Color(hex: "FF9999")) : (octaveMode == .keyboard ? Color(hex: "FFA500") : Color(hex: "1E90FF")),
                        textColor: .white,
                        action: {
                            if !audioEngine.isStepEditMode {
                                // Toggle between KB and GRD in normal mode only
                                octaveMode = octaveMode == .keyboard ? .grid : .keyboard
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            }
                            // In step edit mode: tap does nothing (long press resets pitch)
                        },
                        width: 46,
                        height: 36,
                        fontSize: 11
                    )
                    .animation(.easeInOut(duration: 0.2), value: stpFlashPurple)
                    .simultaneousGesture(
                        audioEngine.isStepEditMode ?
                        DragGesture(minimumDistance: 0)
                            .onChanged { _ in
                                if stpLongPressTimer == nil {
                                    stpLongPressTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { _ in
                                        // Long press detected - reset pitch of selected notes
                                        audioEngine.resetSelectedStepsPitch()
                                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()

                                        // Flash purple
                                        stpFlashPurple = true
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                            stpFlashPurple = false
                                        }
                                    }
                                }
                            }
                            .onEnded { _ in
                                stpLongPressTimer?.invalidate()
                                stpLongPressTimer = nil
                            }
                        : nil
                    )

                    RetroButton(
                        title: "-",
                        color: getMinusButtonColor(),
                        textColor: getMinusButtonColor() == .black ? .white : .black,
                        action: {
                            minusButtonPressed = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                                minusButtonPressed = false
                            }

                            if audioEngine.isStepEditMode {
                                // STP mode: adjust octave of selected steps only
                                if !audioEngine.selectedSteps.isEmpty {
                                    audioEngine.adjustSelectedStepsOctave(by: -6)
                                }
                            } else if octaveMode == .keyboard {
                                // KB mode: control keyboard transpose
                                if audioEngine.transpose > -24 {
                                    audioEngine.transpose -= 12
                                }
                            } else if octaveMode == .grid {
                                // GRD mode: control current track octave
                                audioEngine.decreaseTrackOctave()
                            }
                        },
                        width: 38,
                        height: 36,
                        fontSize: 16
                    )
                    .animation(.easeInOut(duration: 0.15), value: minusButtonPressed)

                    Text("\(getCurrentOctave())")
                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                        .frame(width: 28)
                        .animation(nil, value: getCurrentOctave())

                    RetroButton(
                        title: "+",
                        color: getPlusButtonColor(),
                        textColor: getPlusButtonColor() == .black ? .white : .black,
                        action: {
                            plusButtonPressed = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                                plusButtonPressed = false
                            }

                            if audioEngine.isStepEditMode {
                                // STP mode: adjust octave of selected steps only
                                if !audioEngine.selectedSteps.isEmpty {
                                    audioEngine.adjustSelectedStepsOctave(by: +6)
                                }
                            } else if octaveMode == .keyboard {
                                // KB mode: control keyboard transpose
                                if audioEngine.transpose < 24 {
                                    audioEngine.transpose += 12
                                }
                            } else if octaveMode == .grid {
                                // GRD mode: control current track octave
                                audioEngine.increaseTrackOctave()
                            }
                        },
                        width: 38,
                        height: 36,
                        fontSize: 16
                    )
                    .animation(.easeInOut(duration: 0.15), value: plusButtonPressed)
                }
                .disabled(isEditMode)
                .animation(nil, value: octaveMode)
                .animation(nil, value: audioEngine.transpose)
                .animation(nil, value: audioEngine.trackOctaveOffsets)
                .animation(nil, value: audioEngine.isStepEditMode)
                .transaction { t in t.animation = nil }
                .padding(8)
                .background(
                    Rectangle()
                        .fill(Color(hex: "FFB6C1").opacity(0.5))
                        .overlay(
                            Rectangle()
                                .stroke(Color.black, lineWidth: 2)
                        )
                )
                .offset(x: CGFloat(octaveButtonOffsetX), y: CGFloat(octaveButtonOffsetY))
                .animation(nil, value: octaveButtonOffsetX)
                .animation(nil, value: octaveButtonOffsetY)
                .overlay(
                    isEditMode ?
                    Rectangle()
                        .stroke(Color(hex: "FF1493"), lineWidth: 3)
                    : nil
                )
                .simultaneousGesture(
                    isEditMode ?
                    DragGesture(minimumDistance: 0)
                        .onChanged { gesture in
                            octaveButtonOffsetX = octaveButtonBaseX + Double(gesture.translation.width)
                            octaveButtonOffsetY = octaveButtonBaseY + Double(gesture.translation.height)
                        }
                        .onEnded { gesture in
                            octaveButtonBaseX = octaveButtonOffsetX
                            octaveButtonBaseY = octaveButtonOffsetY
                        }
                    : nil
                )
                .zIndex(100)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
                .padding(.leading, 8)
                .padding(.bottom, 180)
            )
            .overlay(
                // Utility buttons - draggable group
                HStack(spacing: 6) {
                    RetroButton(
                        title: "EDIT",
                        color: isEditMode ? Color(hex: "FF1493") : Color(hex: "FFD700"),
                        textColor: isEditMode ? .white : .black,
                        action: {
                            isEditMode.toggle()
                            if !isEditMode {
                                saveElementPositions()
                            }
                        },
                        width: 60,
                        height: 36,
                        fontSize: 11
                    )

                    RetroButton(
                        title: "WAV",
                        color: Color(hex: "90EE90"),
                        textColor: .black,
                        action: { exportWAV() },
                        width: 36,
                        height: 36,
                        fontSize: 12
                    )
                    .disabled(isEditMode)

                    RetroButton(
                        title: "?",
                        color: Color(hex: "87CEEB"),
                        textColor: .black,
                        action: { showHelp = true },
                        width: 36,
                        height: 36,
                        fontSize: 20
                    )
                    .disabled(isEditMode)
                }
                .offset(utilityButtonsOffset)
                .animation(nil, value: utilityButtonsOffset)
                .overlay(
                    isEditMode ?
                    Rectangle()
                        .stroke(Color(hex: "FF1493"), lineWidth: 3)
                    : nil
                )
                .simultaneousGesture(
                    isEditMode ?
                    DragGesture(minimumDistance: 0)
                        .onChanged { gesture in
                            utilityButtonsOffset = CGSize(
                                width: utilityButtonsBase.width + gesture.translation.width,
                                height: utilityButtonsBase.height + gesture.translation.height
                            )
                        }
                        .onEnded { gesture in
                            utilityButtonsBase = utilityButtonsOffset
                        }
                    : nil
                )
                .zIndex(100)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            )
            .overlay(
                // Center crosshair guide in edit mode
                isEditMode ?
                GeometryReader { geo in
                    ZStack {
                        // Vertical line
                        Rectangle()
                            .fill(Color.white.opacity(0.5))
                            .frame(width: 2)
                            .position(x: geo.size.width / 2, y: geo.size.height / 2)

                        // Horizontal line
                        Rectangle()
                            .fill(Color.white.opacity(0.5))
                            .frame(height: 2)
                            .position(x: geo.size.width / 2, y: geo.size.height / 2)
                    }
                }
                : nil
            )
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .onAppear {
            // Force landscape orientation
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                windowScene.requestGeometryUpdate(.iOS(interfaceOrientations: .landscape))
            }
            AppDelegate.orientationLock = .landscape

            // Load slot 2 keyboard position by default
            let savedX = UserDefaults.standard.double(forKey: "keyboardX_2")
            let savedY = UserDefaults.standard.double(forKey: "keyboardY_2")

            if savedX != 0 || savedY != 0 {
                keyboardOffsetX = savedX
                keyboardOffsetY = savedY
                keyboardBaseX = savedX
                keyboardBaseY = savedY
            } else {
                keyboardBaseY = -72  // Initialize default
            }

            // Load element positions (includes KB/GRD section)
            loadElementPositions()
        }
        .onChange(of: audioEngine.isStepEditMode) { isStepEdit in
            // When exiting step edit mode, clear selection
            if !isStepEdit {
                audioEngine.clearStepSelection()
            }
        }
        .alert("WAV Export", isPresented: $showExportAlert) {
            Button("OK") { }
        } message: {
            Text("WAV export functionality coming soon!")
        }
    }

    private var overlaysView: some View {
        ZStack {
            // Help Panel overlay
            if showHelp {
                HelpPanelPopup(isShowing: $showHelp)
            }

            // Layout Editor overlay
            if showLayoutEditor {
                KeyboardLayoutEditor(
                    isShowing: $showLayoutEditor,
                    keyboardOffsetX: $keyboardOffsetX,
                    keyboardOffsetY: $keyboardOffsetY,
                    octaveButtonOffsetY: $octaveButtonOffsetY
                )
            }
        }
    }

    private func getCurrentOctave() -> Int {
        if audioEngine.isStepEditMode {
            // STP mode: show average pitch of selected notes in semitones
            return audioEngine.getAverageSelectedStepsPitch()
        }

        switch octaveMode {
        case .keyboard:
            return audioEngine.transpose / 12
        case .grid, .sequence, .stepEdit:
            return audioEngine.trackOctaveOffsets[audioEngine.selectedInstrument]
        }
    }

    private func getOctaveButtonColor(isLowerButton: Bool) -> Color {
        let baseColor = Color(hex: "FF9999")  // Pastel red
        let octave = getCurrentOctave()

        // Determine if this button should be highlighted
        let shouldHighlight = (isLowerButton && octave < 0) || (!isLowerButton && octave > 0)

        if !shouldHighlight {
            return Color.black
        }

        let absOctave = abs(octave)

        if !isLowerButton {
            // + button: lighter colors for higher octaves
            switch absOctave {
            case 1: return adjustBrightness(baseColor, by: 0.15)
            case 2: return adjustBrightness(baseColor, by: 0.30)
            default: return baseColor
            }
        } else {
            // - button: darker colors for lower octaves
            switch absOctave {
            case 1: return adjustBrightness(baseColor, by: -0.20)
            case 2: return adjustBrightness(baseColor, by: -0.40)
            default: return baseColor
            }
        }
    }

    private func adjustBrightness(_ color: Color, by amount: CGFloat) -> Color {
        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        var alpha: CGFloat = 0

        let uiColor = UIColor(color)
        uiColor.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)

        let newBrightness = max(0, min(1, brightness + amount))
        return Color(hue: Double(hue), saturation: Double(saturation), brightness: Double(newBrightness), opacity: Double(alpha))
    }

    private func getTrackColor() -> Color {
        let trackColors: [Color] = [
            Color(hex: "FF69B4"),  // Track 1 - Hot Pink
            Color(hex: "9370DB"),  // Track 2 - Purple
            Color(hex: "32CD32"),  // Track 3 - Lime Green
            Color(hex: "1E90FF"),  // Track 4 - Dodger Blue
            Color(hex: "FFD700"),  // Track 5 - Gold
            Color(hex: "FF6347"),  // Track 6 - Tomato
            Color(hex: "FF8C00"),  // Track 7 - Dark Orange
            Color(hex: "FFA500")   // Track 8 - Orange
        ]
        return trackColors[audioEngine.selectedInstrument]
    }

    private func getPlusButtonColor() -> Color {
        if audioEngine.isStepEditMode {
            // In STP mode, use track color, lighter when pressed
            let trackColor = getTrackColor()
            return plusButtonPressed ? adjustBrightness(trackColor, by: 0.25) : trackColor
        }
        return getOctaveButtonColor(isLowerButton: false)
    }

    private func getMinusButtonColor() -> Color {
        if audioEngine.isStepEditMode {
            // In STP mode, use track color, darker when pressed
            let trackColor = getTrackColor()
            return minusButtonPressed ? adjustBrightness(trackColor, by: -0.25) : trackColor
        }
        return getOctaveButtonColor(isLowerButton: true)
    }

    private func saveElementPositions() {
        // Original elements
        UserDefaults.standard.set(oscilloscopeOffset.width, forKey: "oscilloscopeX")
        UserDefaults.standard.set(oscilloscopeOffset.height, forKey: "oscilloscopeY")
        UserDefaults.standard.set(instrumentSelectorOffset.width, forKey: "instrumentSelectorX")
        UserDefaults.standard.set(instrumentSelectorOffset.height, forKey: "instrumentSelectorY")
        UserDefaults.standard.set(adsrOffset.width, forKey: "adsrX")
        UserDefaults.standard.set(adsrOffset.height, forKey: "adsrY")
        UserDefaults.standard.set(effectsOffset.width, forKey: "effectsX")
        UserDefaults.standard.set(effectsOffset.height, forKey: "effectsY")

        // Unified transport controls (Play through DUP)
        UserDefaults.standard.set(allTransportControlsOffset.width, forKey: "allTransportControlsX")
        UserDefaults.standard.set(allTransportControlsOffset.height, forKey: "allTransportControlsY")

        // BPM
        UserDefaults.standard.set(bpmSliderOffset.width, forKey: "bpmSliderX")
        UserDefaults.standard.set(bpmSliderOffset.height, forKey: "bpmSliderY")

        // Utility button group
        UserDefaults.standard.set(utilityButtonsOffset.width, forKey: "utilityButtonsX")
        UserDefaults.standard.set(utilityButtonsOffset.height, forKey: "utilityButtonsY")

        // Keyboard and octave (save to slot 2 for consistency)
        UserDefaults.standard.set(keyboardOffsetX, forKey: "keyboardX_2")
        UserDefaults.standard.set(keyboardOffsetY, forKey: "keyboardY_2")

        // KB/GRD section position
        UserDefaults.standard.set(octaveButtonOffsetX, forKey: "octaveButtonX")
        UserDefaults.standard.set(octaveButtonOffsetY, forKey: "octaveButtonY")
    }

    private func loadElementPositions() {
        // Original elements
        oscilloscopeOffset = CGSize(
            width: UserDefaults.standard.double(forKey: "oscilloscopeX"),
            height: UserDefaults.standard.double(forKey: "oscilloscopeY")
        )
        oscilloscopeBase = oscilloscopeOffset

        instrumentSelectorOffset = CGSize(
            width: UserDefaults.standard.double(forKey: "instrumentSelectorX"),
            height: UserDefaults.standard.double(forKey: "instrumentSelectorY")
        )
        instrumentSelectorBase = instrumentSelectorOffset

        adsrOffset = CGSize(
            width: UserDefaults.standard.double(forKey: "adsrX"),
            height: UserDefaults.standard.double(forKey: "adsrY")
        )
        adsrBase = adsrOffset

        effectsOffset = CGSize(
            width: UserDefaults.standard.double(forKey: "effectsX"),
            height: UserDefaults.standard.double(forKey: "effectsY")
        )
        effectsBase = effectsOffset

        // Unified transport controls (Play through DUP)
        allTransportControlsOffset = CGSize(
            width: UserDefaults.standard.double(forKey: "allTransportControlsX"),
            height: UserDefaults.standard.double(forKey: "allTransportControlsY")
        )
        allTransportControlsBase = allTransportControlsOffset

        // BPM - position below oscilloscope
        bpmSliderOffset = CGSize(width: 0, height: 105)
        bpmSliderBase = bpmSliderOffset

        // Utility button group
        utilityButtonsOffset = CGSize(
            width: UserDefaults.standard.double(forKey: "utilityButtonsX"),
            height: UserDefaults.standard.double(forKey: "utilityButtonsY")
        )
        utilityButtonsBase = utilityButtonsOffset

        // KB/GRD section position
        let savedOctX = UserDefaults.standard.double(forKey: "octaveButtonX")
        let savedOctY = UserDefaults.standard.double(forKey: "octaveButtonY")
        octaveButtonOffsetX = savedOctX
        octaveButtonOffsetY = savedOctY != 0 ? savedOctY : -95
        octaveButtonBaseX = octaveButtonOffsetX
        octaveButtonBaseY = octaveButtonOffsetY
    }

    private func exportWAV() {
        showExportAlert = true
    }

    private func cycleScale() {
        let newScale = (audioEngine.currentScale + 1) % 8
        audioEngine.changeScale(to: newScale)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
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

// Color extension for hex colors
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// Keyboard Layout Editor
struct KeyboardLayoutEditor: View {
    @Binding var isShowing: Bool
    @Binding var keyboardOffsetX: Double
    @Binding var keyboardOffsetY: Double
    @Binding var octaveButtonOffsetY: Double
    @State private var selectedSlot: Int = 2  // Default to slot 2
    @State private var selectedElement: String = "keyboard"  // "keyboard" or "octave"
    @State private var savedPositions: [Int: (keyX: Double, keyY: Double, octY: Double)] = [:]

    var body: some View {
        ZStack {
            // Semi-transparent background
            Color.black.opacity(0.7)
                .ignoresSafeArea()
                .onTapGesture {
                    isShowing = false
                }

            // Editor panel
            VStack(spacing: 16) {
                Text("KEYBOARD LAYOUT EDITOR")
                    .font(.system(size: 16, weight: .bold, design: .monospaced))
                    .foregroundColor(.black)
                    .padding()
                    .background(Color(hex: "FFD700"))
                    .overlay(
                        Rectangle()
                            .stroke(Color.black, lineWidth: 3)
                    )

                VStack(spacing: 12) {
                    // Slot selector
                    HStack(spacing: 8) {
                        Text("SLOT:")
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundColor(.black)

                        ForEach(1...4, id: \.self) { slot in
                            RetroButton(
                                title: "\(slot)",
                                color: selectedSlot == slot ? Color(hex: "FF69B4") : Color.white,
                                textColor: .black,
                                action: {
                                    selectedSlot = slot
                                    if let saved = savedPositions[slot] {
                                        keyboardOffsetX = saved.keyX
                                        keyboardOffsetY = saved.keyY
                                        octaveButtonOffsetY = saved.octY
                                    }
                                },
                                width: 40,
                                height: 36,
                                fontSize: 14
                            )
                        }
                    }

                    // Element selector
                    HStack(spacing: 8) {
                        Text("ELEMENT:")
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundColor(.black)

                        RetroButton(
                            title: "KEYBOARD",
                            color: selectedElement == "keyboard" ? Color(hex: "1E90FF") : Color.white,
                            textColor: .black,
                            action: { selectedElement = "keyboard" },
                            width: 90,
                            height: 32,
                            fontSize: 10
                        )

                        RetroButton(
                            title: "OCTAVE",
                            color: selectedElement == "octave" ? Color(hex: "FFA500") : Color.white,
                            textColor: .black,
                            action: { selectedElement = "octave" },
                            width: 80,
                            height: 32,
                            fontSize: 10
                        )
                    }

                    // Position controls based on selected element
                    VStack(spacing: 8) {
                        if selectedElement == "keyboard" {
                            // X position
                            HStack(spacing: 8) {
                                Text("X:")
                                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                                    .foregroundColor(.black)
                                    .frame(width: 30)

                                CustomSlider(
                                    value: $keyboardOffsetX,
                                    range: -300...300,
                                    trackColor: Color(hex: "1E90FF"),
                                    label: ""
                                )
                                .frame(width: 200, height: 30)

                                Text("\(Int(keyboardOffsetX))")
                                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                                    .foregroundColor(.black)
                                    .frame(width: 50)
                            }

                            // Y position
                            HStack(spacing: 8) {
                                Text("Y:")
                                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                                    .foregroundColor(.black)
                                    .frame(width: 30)

                                CustomSlider(
                                    value: $keyboardOffsetY,
                                    range: -300...300,
                                    trackColor: Color(hex: "FF69B4"),
                                    label: ""
                                )
                                .frame(width: 200, height: 30)

                                Text("\(Int(keyboardOffsetY))")
                                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                                    .foregroundColor(.black)
                                    .frame(width: 50)
                            }
                        } else {
                            // Octave button Y position only
                            HStack(spacing: 8) {
                                Text("Y:")
                                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                                    .foregroundColor(.black)
                                    .frame(width: 30)

                                CustomSlider(
                                    value: $octaveButtonOffsetY,
                                    range: -300...300,
                                    trackColor: Color(hex: "FFA500"),
                                    label: ""
                                )
                                .frame(width: 200, height: 30)

                                Text("\(Int(octaveButtonOffsetY))")
                                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                                    .foregroundColor(.black)
                                    .frame(width: 50)
                            }
                        }

                        // Save and Reset buttons
                        HStack(spacing: 8) {
                            RetroButton(
                                title: "SAVE",
                                color: Color(hex: "32CD32"),
                                textColor: .black,
                                action: {
                                    savedPositions[selectedSlot] = (keyX: keyboardOffsetX, keyY: keyboardOffsetY, octY: octaveButtonOffsetY)
                                    UserDefaults.standard.set(keyboardOffsetX, forKey: "keyboardX_\(selectedSlot)")
                                    UserDefaults.standard.set(keyboardOffsetY, forKey: "keyboardY_\(selectedSlot)")
                                    UserDefaults.standard.set(octaveButtonOffsetY, forKey: "octaveY_\(selectedSlot)")
                                },
                                width: 80,
                                height: 36,
                                fontSize: 12
                            )

                            RetroButton(
                                title: "RESET",
                                color: Color(hex: "FFA500"),
                                textColor: .black,
                                action: {
                                    if selectedElement == "keyboard" {
                                        keyboardOffsetX = 0
                                        keyboardOffsetY = -72
                                    } else {
                                        octaveButtonOffsetY = -95
                                    }
                                },
                                width: 80,
                                height: 36,
                                fontSize: 12
                            )
                        }
                    }
                }
                .padding(16)
                .background(
                    Rectangle()
                        .fill(Color(hex: "FFB6C1"))
                        .overlay(
                            Rectangle()
                                .stroke(Color.black, lineWidth: 3)
                        )
                )

                // Close button
                RetroButton(
                    title: "DONE",
                    color: Color(hex: "90EE90"),
                    textColor: .black,
                    action: {
                        isShowing = false
                    },
                    width: 120,
                    height: 48,
                    fontSize: 14
                )
            }
            .padding(32)
            .onAppear {
                // Load saved positions
                for slot in 1...4 {
                    let x = UserDefaults.standard.double(forKey: "keyboardX_\(slot)")
                    let y = UserDefaults.standard.double(forKey: "keyboardY_\(slot)")
                    let octY = UserDefaults.standard.double(forKey: "octaveY_\(slot)")
                    if x != 0 || y != 0 || octY != 0 {
                        savedPositions[slot] = (keyX: x, keyY: y, octY: octY == 0 ? -95 : octY)
                    }
                }
                // Load slot 2 by default
                if let saved = savedPositions[2] {
                    keyboardOffsetX = saved.keyX
                    keyboardOffsetY = saved.keyY
                    octaveButtonOffsetY = saved.octY
                }
            }
        }
    }
}

// App Delegate for orientation lock
class AppDelegate: NSObject, UIApplicationDelegate {
    static var orientationLock = UIInterfaceOrientationMask.all

    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        return AppDelegate.orientationLock
    }
}