import SwiftUI

struct ADSRView: View {
    @EnvironmentObject var audioEngine: AudioEngine
    @State private var attack: Double = 0.01
    @State private var decay: Double = 0.1
    @State private var sustain: Double = 0.8
    @State private var release: Double = 0.3
    
    var body: some View {
        VStack(spacing: 4) {
            // Visual ADSR Envelope Display
            ADSREnvelopeView(attack: attack, decay: decay, sustain: sustain, release: release)
                .frame(height: 60)
                .background(Color.black)
                .cornerRadius(4)
            
            // ADSR Sliders - beautiful custom sliders like original
            VStack(spacing: 4) {
                CustomSlider(value: $attack, range: 0...2, trackColor: Color(hex: "FFB6C1"), label: "A:")
                CustomSlider(value: $decay, range: 0...2, trackColor: Color(hex: "FFB6C1"), label: "D:")
                CustomSlider(value: $sustain, range: 0...1, trackColor: Color(hex: "FF69B4"), label: "S:")
                CustomSlider(value: $release, range: 0...5, trackColor: Color(hex: "FFB6C1"), label: "R:")
            }
            .onChange(of: attack) { newValue in
                // Check if in STEP EDIT mode with a selected step
                if (audioEngine.isStepEditMode && audioEngine.editingStep != nil) || (audioEngine.isDrumPitchEditMode && audioEngine.editingDrumStep != nil) {
                    // Update per-step ADSR
                    let step = audioEngine.editingStep ?? audioEngine.editingDrumStep
                    if let step = step {
                        audioEngine.setStepADSR(row: step.row, col: step.col, instrument: audioEngine.selectedInstrument, attack: newValue, decay: decay, sustain: sustain, release: release)
                    }
                } else {
                    // Update track ADSR
                    audioEngine.updateTrackADSR(track: audioEngine.selectedInstrument, attack: newValue, decay: decay, sustain: sustain, release: release)
                }
            }
            .onChange(of: decay) { newValue in
                if (audioEngine.isStepEditMode && audioEngine.editingStep != nil) || (audioEngine.isDrumPitchEditMode && audioEngine.editingDrumStep != nil) {
                    let step = audioEngine.editingStep ?? audioEngine.editingDrumStep
                    if let step = step {
                        audioEngine.setStepADSR(row: step.row, col: step.col, instrument: audioEngine.selectedInstrument, attack: attack, decay: newValue, sustain: sustain, release: release)
                    }
                } else {
                    audioEngine.updateTrackADSR(track: audioEngine.selectedInstrument, attack: attack, decay: newValue, sustain: sustain, release: release)
                }
            }
            .onChange(of: sustain) { newValue in
                if (audioEngine.isStepEditMode && audioEngine.editingStep != nil) || (audioEngine.isDrumPitchEditMode && audioEngine.editingDrumStep != nil) {
                    let step = audioEngine.editingStep ?? audioEngine.editingDrumStep
                    if let step = step {
                        audioEngine.setStepADSR(row: step.row, col: step.col, instrument: audioEngine.selectedInstrument, attack: attack, decay: decay, sustain: newValue, release: release)
                    }
                } else {
                    audioEngine.updateTrackADSR(track: audioEngine.selectedInstrument, attack: attack, decay: decay, sustain: newValue, release: release)
                }
            }
            .onChange(of: release) { newValue in
                if (audioEngine.isStepEditMode && audioEngine.editingStep != nil) || (audioEngine.isDrumPitchEditMode && audioEngine.editingDrumStep != nil) {
                    let step = audioEngine.editingStep ?? audioEngine.editingDrumStep
                    if let step = step {
                        audioEngine.setStepADSR(row: step.row, col: step.col, instrument: audioEngine.selectedInstrument, attack: attack, decay: decay, sustain: sustain, release: newValue)
                    }
                } else {
                    audioEngine.updateTrackADSR(track: audioEngine.selectedInstrument, attack: attack, decay: decay, sustain: sustain, release: newValue)
                }
            }
            .onChange(of: audioEngine.currentStepADSR) { newValue in
                // When step ADSR changes (step selected), update UI
                attack = newValue[0]
                decay = newValue[1]
                sustain = newValue[2]
                release = newValue[3]
            }
            .onChange(of: audioEngine.selectedInstrument) { _ in
                // Load ADSR values - check if step is selected, otherwise use track
                if (audioEngine.isStepEditMode && audioEngine.editingStep != nil) || (audioEngine.isDrumPitchEditMode && audioEngine.editingDrumStep != nil) {
                    let adsr = audioEngine.currentStepADSR
                    attack = adsr[0]
                    decay = adsr[1]
                    sustain = adsr[2]
                    release = adsr[3]
                } else {
                    let trackADSR = audioEngine.getTrackADSR(track: audioEngine.selectedInstrument)
                    attack = trackADSR[0]
                    decay = trackADSR[1]
                    sustain = trackADSR[2]
                    release = trackADSR[3]
                }
            }
            .onAppear {
                // Initialize - check if step is selected, otherwise use track
                if (audioEngine.isStepEditMode && audioEngine.editingStep != nil) || (audioEngine.isDrumPitchEditMode && audioEngine.editingDrumStep != nil) {
                    let adsr = audioEngine.currentStepADSR
                    attack = adsr[0]
                    decay = adsr[1]
                    sustain = adsr[2]
                    release = adsr[3]
                } else {
                    let trackADSR = audioEngine.getTrackADSR(track: audioEngine.selectedInstrument)
                    attack = trackADSR[0]
                    decay = trackADSR[1]
                    sustain = trackADSR[2]
                    release = trackADSR[3]
                }
            }
        }
        .padding(8)
    }
}

struct ADSREnvelopeView: View {
    let attack: Double
    let decay: Double
    let sustain: Double
    let release: Double
    
    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height
            
            // Calculate phase widths (proportional)
            let totalTime = attack + decay + 1.0 + release // 1.0 is sustain hold time
            let attackWidth = (attack / totalTime) * width * 0.6 // Leave room for padding
            let decayWidth = (decay / totalTime) * width * 0.6
            let sustainWidth = (1.0 / totalTime) * width * 0.6
            let _ = (release / totalTime) * width * 0.6 // releaseWidth calculated but not used in layout
            
            let padding: CGFloat = width * 0.1
            let drawWidth = width - (padding * 2)
            
            Path { path in
                // Start at bottom left
                path.move(to: CGPoint(x: padding, y: height))
                
                // Attack phase - rise to peak
                path.addLine(to: CGPoint(
                    x: padding + (attackWidth / (attack + decay + 1.0 + release)) * drawWidth,
                    y: height * 0.1
                ))
                
                // Decay phase - fall to sustain level
                let decayX = padding + ((attackWidth + decayWidth) / (attack + decay + 1.0 + release)) * drawWidth
                path.addLine(to: CGPoint(
                    x: decayX,
                    y: height * (1.0 - sustain) + height * 0.1
                ))
                
                // Sustain phase - hold sustain level
                let sustainX = padding + ((attackWidth + decayWidth + sustainWidth) / (attack + decay + 1.0 + release)) * drawWidth
                path.addLine(to: CGPoint(
                    x: sustainX,
                    y: height * (1.0 - sustain) + height * 0.1
                ))
                
                // Release phase - fall to zero
                let releaseX = padding + drawWidth
                path.addLine(to: CGPoint(
                    x: releaseX,
                    y: height
                ))
            }
            .stroke(Color.green, lineWidth: 2)
            .background(
                // Fill under the envelope
                Path { path in
                    path.move(to: CGPoint(x: padding, y: height))
                    
                    // Same path as above but closed
                    path.addLine(to: CGPoint(
                        x: padding + (attackWidth / (attack + decay + 1.0 + release)) * drawWidth,
                        y: height * 0.1
                    ))
                    
                    let decayX = padding + ((attackWidth + decayWidth) / (attack + decay + 1.0 + release)) * drawWidth
                    path.addLine(to: CGPoint(
                        x: decayX,
                        y: height * (1.0 - sustain) + height * 0.1
                    ))
                    
                    let sustainX = padding + ((attackWidth + decayWidth + sustainWidth) / (attack + decay + 1.0 + release)) * drawWidth
                    path.addLine(to: CGPoint(
                        x: sustainX,
                        y: height * (1.0 - sustain) + height * 0.1
                    ))
                    
                    let releaseX = padding + drawWidth
                    path.addLine(to: CGPoint(
                        x: releaseX,
                        y: height
                    ))
                    
                    // Close the path
                    path.addLine(to: CGPoint(x: padding, y: height))
                }
                .fill(Color.green.opacity(0.2))
            )
            .overlay(
                // Phase labels
                HStack {
                    Text("A")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                    Text("D")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                    Text("S")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                    Text("R")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                }
                .padding(.horizontal, padding),
                alignment: .bottom
            )
        }
        .animation(nil, value: attack)  // Disable animation for instant updates
        .animation(nil, value: decay)
        .animation(nil, value: sustain)
        .animation(nil, value: release)
        .transaction { t in t.animation = nil }  // Force-disable inherited animations
    }
}