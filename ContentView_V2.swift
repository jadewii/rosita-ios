import SwiftUI
import AVFoundation

struct ContentView: View {
    @StateObject private var drumMachine = DrumMachine()
    @State private var showingSynthPanel = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [
                        Color(red: 0.96, green: 0.76, blue: 0.78),
                        Color(red: 0.82, green: 0.93, blue: 0.95),
                        Color(red: 0.89, green: 0.89, blue: 1.0)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                HStack(spacing: 12) {
                    // Left side - Main sequencer
                    VStack(spacing: 8) {
                        // Header
                        HStack {
                            Text("🌸 Aurora Grid")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(Color(red: 0.91, green: 0.12, blue: 0.39))
                            
                            Spacer()
                            
                            HStack(spacing: 12) {
                                Button(action: {
                                    drumMachine.togglePlayback()
                                }) {
                                    Text(drumMachine.isPlaying ? "■ Stop" : "▶ Play")
                                        .foregroundColor(.white)
                                        .font(.headline)
                                        .frame(width: 100, height: 44)
                                        .background(drumMachine.isPlaying ? Color.red : Color.green)
                                        .cornerRadius(22)
                                }
                                
                                Button(action: {
                                    drumMachine.clear()
                                }) {
                                    Text("Clear")
                                        .foregroundColor(.black)
                                        .frame(width: 80, height: 44)
                                        .background(Color.white.opacity(0.8))
                                        .cornerRadius(22)
                                }
                                
                                HStack {
                                    Text("BPM:")
                                    Slider(value: $drumMachine.bpm, in: 60...200, step: 1)
                                        .frame(width: 120)
                                    Text("\(Int(drumMachine.bpm))")
                                        .font(.headline)
                                        .frame(width: 40)
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Color.white.opacity(0.8))
                                .cornerRadius(22)
                                
                                Button(action: {
                                    showingSynthPanel.toggle()
                                }) {
                                    Text("🎛️ Synth")
                                        .foregroundColor(.white)
                                        .frame(width: 80, height: 44)
                                        .background(Color.purple)
                                        .cornerRadius(22)
                                }
                            }
                        }
                        .padding(.horizontal)
                        
                        // Main Grid
                        VStack(spacing: 6) {
                            ForEach(0..<6) { trackIndex in
                                TrackRowView(
                                    trackIndex: trackIndex,
                                    drumMachine: drumMachine
                                )
                            }
                        }
                        .padding()
                        .background(Color.white.opacity(0.9))
                        .cornerRadius(16)
                        
                        // Pattern and controls
                        HStack(spacing: 16) {
                            // Pattern selector
                            VStack {
                                Text("Patterns")
                                    .font(.headline)
                                HStack {
                                    ForEach(0..<4) { pattern in
                                        Button("\(pattern + 1)") {
                                            drumMachine.switchPattern(to: pattern)
                                        }
                                        .foregroundColor(drumMachine.currentPattern == pattern ? .white : .black)
                                        .frame(width: 44, height: 44)
                                        .background(drumMachine.currentPattern == pattern ? Color.pink : Color.white.opacity(0.7))
                                        .cornerRadius(22)
                                    }
                                }
                            }
                            
                            Button("Random Fill") {
                                drumMachine.randomFill()
                            }
                            .foregroundColor(.white)
                            .frame(width: 120, height: 44)
                            .background(Color.blue)
                            .cornerRadius(22)
                            
                            Spacer()
                        }
                        .padding()
                        .background(Color.white.opacity(0.9))
                        .cornerRadius(16)
                    }
                    
                    // Right side - Synthesizer panel (when shown)
                    if showingSynthPanel {
                        SynthesizerPanel(drumMachine: drumMachine)
                            .frame(width: 300)
                    }
                }
                .padding(12)
            }
        }
        .statusBarHidden()
        .navigationBarHidden(true)
        .supportedInterfaceOrientations(.landscape)
        .onAppear {
            // Force landscape orientation
            UIDevice.current.setValue(UIInterfaceOrientation.landscapeLeft.rawValue, forKey: "orientation")
        }
    }
}

struct TrackRowView: View {
    let trackIndex: Int
    @ObservedObject var drumMachine: DrumMachine
    
    let trackNames = ["Kick", "Snare", "Hi-Hat", "Open Hat", "Crash", "Bass"]
    let trackColors = [
        Color(red: 1.0, green: 0.7, blue: 0.73),   // Kick - pink
        Color(red: 0.73, green: 0.88, blue: 1.0),  // Snare - blue  
        Color(red: 0.73, green: 1.0, blue: 0.79),  // Hi-hat - green
        Color(red: 1.0, green: 1.0, blue: 0.73),   // Open hat - yellow
        Color(red: 1.0, green: 0.87, blue: 0.73),  // Crash - orange
        Color(red: 0.88, green: 0.67, blue: 1.0)   // Bass - purple
    ]
    
    var body: some View {
        HStack(spacing: 8) {
            // Track label
            Text(trackNames[trackIndex])
                .font(.system(size: 14, weight: .semibold))
                .frame(width: 80)
                .padding(.vertical, 8)
                .background(trackColors[trackIndex])
                .cornerRadius(8)
            
            // Step buttons
            HStack(spacing: 3) {
                ForEach(0..<16) { step in
                    StepButton(
                        trackIndex: trackIndex,
                        step: step,
                        drumMachine: drumMachine
                    )
                }
            }
            
            // Mute/Solo
            HStack(spacing: 4) {
                Button("M") {
                    drumMachine.toggleMute(track: trackIndex)
                }
                .foregroundColor(drumMachine.tracks[trackIndex].isMuted ? .white : .black)
                .frame(width: 32, height: 32)
                .background(drumMachine.tracks[trackIndex].isMuted ? Color.red : Color.white.opacity(0.7))
                .cornerRadius(16)
                
                Button("S") {
                    drumMachine.toggleSolo(track: trackIndex)
                }
                .foregroundColor(drumMachine.tracks[trackIndex].isSolo ? .black : .black)
                .frame(width: 32, height: 32)
                .background(drumMachine.tracks[trackIndex].isSolo ? Color.yellow : Color.white.opacity(0.7))
                .cornerRadius(16)
            }
        }
    }
}

struct StepButton: View {
    let trackIndex: Int
    let step: Int
    @ObservedObject var drumMachine: DrumMachine
    
    var body: some View {
        Button(action: {
            drumMachine.toggleStep(track: trackIndex, step: step)
        }) {
            Text("\(step + 1)")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(isActive ? .white : .gray)
                .frame(width: 36, height: 36)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(isActive ? Color.pink : Color.white.opacity(0.7))
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(
                                    isCurrentStep ? Color.yellow : (isBeat ? Color.black : Color.clear),
                                    lineWidth: isCurrentStep ? 3 : (isBeat ? 2 : 0)
                                )
                        )
                )
                .scaleEffect(isCurrentStep ? 1.1 : 1.0)
                .animation(.easeInOut(duration: 0.1), value: isCurrentStep)
        }
    }
    
    private var isActive: Bool {
        drumMachine.patterns[drumMachine.currentPattern].tracks[trackIndex].steps[step]
    }
    
    private var isCurrentStep: Bool {
        drumMachine.currentStep == step && drumMachine.isPlaying
    }
    
    private var isBeat: Bool {
        step % 4 == 0
    }
}

struct SynthesizerPanel: View {
    @ObservedObject var drumMachine: DrumMachine
    @State private var selectedTrack = 0
    
    let trackNames = ["Kick", "Snare", "Hi-Hat", "Open Hat", "Crash", "Bass"]
    
    var body: some View {
        VStack(spacing: 16) {
            Text("🎛️ Drum Synthesizer")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.purple)
            
            // Track selector
            Picker("Track", selection: $selectedTrack) {
                ForEach(0..<6) { index in
                    Text(trackNames[index]).tag(index)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            
            // Oscillator section
            VStack(alignment: .leading, spacing: 12) {
                Text("Oscillator")
                    .font(.headline)
                    .foregroundColor(.purple)
                
                SynthKnob(
                    label: "Frequency",
                    value: $drumMachine.synthParams[selectedTrack].frequency,
                    range: 20...2000
                )
                
                SynthKnob(
                    label: "Decay",
                    value: $drumMachine.synthParams[selectedTrack].decay,
                    range: 0.01...2.0
                )
                
                SynthKnob(
                    label: "Tone",
                    value: $drumMachine.synthParams[selectedTrack].tone,
                    range: 0...1
                )
            }
            
            // Envelope section
            VStack(alignment: .leading, spacing: 12) {
                Text("Envelope")
                    .font(.headline)
                    .foregroundColor(.purple)
                
                SynthKnob(
                    label: "Attack",
                    value: $drumMachine.synthParams[selectedTrack].attack,
                    range: 0.001...0.1
                )
                
                SynthKnob(
                    label: "Sustain",
                    value: $drumMachine.synthParams[selectedTrack].sustain,
                    range: 0...1
                )
                
                SynthKnob(
                    label: "Release",
                    value: $drumMachine.synthParams[selectedTrack].release,
                    range: 0.01...2.0
                )
            }
            
            // Test button
            Button("Test Sound") {
                drumMachine.testSound(track: selectedTrack)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity, minHeight: 44)
            .background(Color.purple)
            .cornerRadius(22)
            
            Spacer()
        }
        .padding()
        .background(Color.white.opacity(0.95))
        .cornerRadius(16)
    }
}

struct SynthKnob: View {
    let label: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    
    var body: some View {
        VStack {
            Text(label)
                .font(.caption)
                .foregroundColor(.gray)
            
            HStack {
                Slider(value: $value, in: range)
                    .accentColor(.purple)
                
                Text(String(format: "%.2f", value))
                    .font(.caption)
                    .frame(width: 45)
            }
        }
    }
}

extension View {
    func supportedInterfaceOrientations(_ orientations: UIInterfaceOrientationMask) -> some View {
        self
    }
}