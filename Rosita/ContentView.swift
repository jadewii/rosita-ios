import SwiftUI

struct ContentView: View {
    @EnvironmentObject var audioEngine: AudioEngine
    @State private var showHelp = false
    @State private var showExportAlert = false
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.verticalSizeClass) var verticalSizeClass
    
    var body: some View {
        GeometryReader { geometry in
            let isCompact = geometry.size.width < 1100 // iPad 11" vs 13"
            let scaleFactor = isCompact ? 0.85 : 1.0
            
            ZStack {
                // Beautiful pink gradient background like the goal image
                Rectangle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [Color(hex: "FFB6C1"), Color(hex: "FF1493")]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .ignoresSafeArea(.all)
                
                // Main layout - ensure full screen usage
                VStack(spacing: 4) {
                    // Top right buttons and controls
                    HStack(alignment: .top, spacing: 8) {
                        Spacer()
                        
                        // Instrument selector
                        InstrumentSelectorView()
                            .frame(width: 140, height: 56)
                        
                        // Arpeggiator
                        ArpeggiatorView()
                            .frame(width: 140, height: 56)
                        
                        // WAV button - same size as help button
                        RetroButton(
                            title: "WAV",
                            color: Color(hex: "90EE90"),
                            textColor: .black,
                            action: {
                                exportWAV()
                            },
                            width: 36,
                            height: 36,
                            fontSize: 12
                        )
                        
                        // Help button
                        RetroButton(
                            title: "?",
                            color: Color(hex: "87CEEB"),
                            textColor: .black,
                            action: {
                                showHelp = true
                            },
                            width: 36,
                            height: 36,
                            fontSize: 20
                        )
                        .padding(.trailing, 8)
                    }
                    .frame(height: 60)
                    
                    // TOP SECTION - Transport and Pattern controls
                    HStack(spacing: 8) {
                        // Transport controls
                        TransportControlsView()
                        
                        // Control buttons
                        HStack(spacing: 6) {
                            RetroButton(
                                title: "ADSR",
                                color: Color(hex: "00FFFF"),
                                textColor: .black,
                                action: {},
                                width: CGFloat(70 * scaleFactor),
                                height: CGFloat(42 * scaleFactor),
                                fontSize: CGFloat(14 * scaleFactor)
                            )
                            
                            RetroButton(
                                title: "MAJOR",
                                color: Color(hex: "FFFF00"),
                                textColor: .black,
                                action: {},
                                width: CGFloat(70 * scaleFactor),
                                height: CGFloat(42 * scaleFactor),
                                fontSize: CGFloat(14 * scaleFactor)
                            )
                            
                            RetroButton(
                                title: "OCTAVE",
                                color: Color(hex: "9370DB"),
                                textColor: .black,
                                action: {},
                                width: CGFloat(70 * scaleFactor),
                                height: CGFloat(42 * scaleFactor),
                                fontSize: CGFloat(14 * scaleFactor)
                            )
                        }
                    }
                    .padding(.horizontal, 8)
                    
                    // Pattern slots and BPM control
                    HStack(spacing: 16) {
                        Spacer()
                        
                        PatternSlotsView()
                            .frame(height: 56)
                        
                        // BPM and Grid Octave controls
                        HStack(spacing: 16) {
                            // BPM control
                            VStack(spacing: 4) {
                                HStack(spacing: 4) {
                                    Text("BPM")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundColor(.black)
                                    
                                    Text("\(Int(audioEngine.bpm))")
                                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                                        .foregroundColor(.black)
                                        .frame(width: 36, height: 20)
                                        .background(
                                            Rectangle()
                                                .fill(Color.white)
                                                .overlay(
                                                    Rectangle()
                                                        .stroke(Color.black, lineWidth: 1)
                                                )
                                        )
                                }
                                
                                CustomSlider(
                                    value: $audioEngine.bpm,
                                    range: 60...200,
                                    trackColor: Color(hex: "FF1493"),
                                    label: ""
                                )
                                .frame(width: 120, height: 40)
                            }
                            
                            // Grid Octave controls
                            HStack(spacing: 6) {
                                Text("GRID OCT")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.black)
                                
                                RetroButton(
                                    title: "-",
                                    color: Color(hex: "87CEEB"),
                                    textColor: .black,
                                    action: {
                                        if audioEngine.gridTranspose > -24 {
                                            audioEngine.gridTranspose -= 12
                                        }
                                    },
                                    width: 28,
                                    height: 28,
                                    fontSize: 16
                                )
                                
                                Text("\(audioEngine.gridTranspose / 12)")
                                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                                    .foregroundColor(.black)
                                    .frame(width: 24)
                                
                                RetroButton(
                                    title: "+",
                                    color: Color(hex: "87CEEB"),
                                    textColor: .black,
                                    action: {
                                        if audioEngine.gridTranspose < 24 {
                                            audioEngine.gridTranspose += 12
                                        }
                                    },
                                    width: 28,
                                    height: 28,
                                    fontSize: 16
                                )
                            }
                        }
                        
                        Spacer()
                    }
                    .padding(.horizontal, 8)
                    .padding(.bottom, 4)
                    
                    // MAIN CONTENT AREA
                    HStack(alignment: .top, spacing: 8) {
                        // LEFT COLUMN - Properly spaced components
                        VStack(alignment: .leading, spacing: 8) {
                            // Waveform Scope
                            WaveformScope()
                                .frame(width: 200, height: 140)
                            
                            // ADSR Envelope
                            ADSRView()
                                .frame(width: 200)
                            
                            // Effects
                            EffectsView()
                                .frame(width: 200)
                            
                            Spacer()
                            
                            // Keyboard Octave controls at bottom
                            HStack(spacing: 4) {
                                Text("KB")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundColor(.black)
                                Text("OCTAVE")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundColor(.black)
                                
                                RetroButton(
                                    title: "-",
                                    color: Color(hex: "FF69B4"),
                                    textColor: .black,
                                    action: {
                                        if audioEngine.transpose > -24 {
                                            audioEngine.transpose -= 12
                                        }
                                    },
                                    width: 28,
                                    height: 24,
                                    fontSize: 14
                                )
                                
                                Text("\(audioEngine.transpose / 12)")
                                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                                    .foregroundColor(.black)
                                    .frame(width: 20)
                                
                                RetroButton(
                                    title: "+",
                                    color: Color(hex: "FF69B4"),
                                    textColor: .black,
                                    action: {
                                        if audioEngine.transpose < 24 {
                                            audioEngine.transpose += 12
                                        }
                                    },
                                    width: 28,
                                    height: 24,
                                    fontSize: 14
                                )
                            }
                            .padding(.bottom, 8)
                        }
                        .frame(width: 200)
                        
                        // SEQUENCER GRID - takes remaining space
                        GridSequencerView()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                    .padding(.horizontal, 8)
                    .frame(maxHeight: .infinity)
                    
                    // BOTTOM - Piano keyboard with adaptive height
                    PianoKeyboardView()
                        .frame(height: isCompact ? 100 : 120)
                        .padding(.horizontal, 8)
                }
                
                // Help modal overlay
                if showHelp {
                    ZStack {
                        // Semi-transparent background
                        Color.black.opacity(0.6)
                            .ignoresSafeArea()
                            .onTapGesture {
                                showHelp = false
                            }
                        
                        // Help modal
                        VStack(spacing: 0) {
                            // Header
                            HStack {
                                Text("ROSITA HELP")
                                    .font(.system(size: 18, weight: .bold, design: .monospaced))
                                    .foregroundColor(.black)
                                
                                Spacer()
                                
                                Button("✕") {
                                    showHelp = false
                                }
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.black)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(Color(hex: "FFB6C1"))
                            
                            // Help content
                            ScrollView {
                                VStack(alignment: .leading, spacing: 12) {
                                    Group {
                                        Text("🎵 BASIC CONTROLS")
                                            .font(.system(size: 14, weight: .bold, design: .monospaced))
                                            .foregroundColor(.black)
                                        
                                        Text("• PLAY/STOP - Start and stop the sequencer\n• REC - Record in real-time (looper mode)\n• TR - Step recording mode (shows instead of REC)\n• Long press REC/TR to switch modes\n• CLEAR - Clear current instrument pattern\n• CLR ALL - Clear all instrument patterns\n• RANDOM - Generate random pattern")
                                            .font(.system(size: 11))
                                            .foregroundColor(.black)
                                        
                                        Text("🎙️ RECORDING MODES")
                                            .font(.system(size: 14, weight: .bold, design: .monospaced))
                                            .foregroundColor(.black)
                                        
                                        Text("• REC (red) - Real-time recording, plays notes as you press them\n• TR (dark red) - Step recording, each key press advances to next step")
                                            .font(.system(size: 11))
                                            .foregroundColor(.black)
                                        
                                        Text("🎹 INSTRUMENTS")
                                            .font(.system(size: 14, weight: .bold, design: .monospaced))
                                            .foregroundColor(.black)
                                        
                                        Text("• Buttons 1,2,3,4 - Select instrument track\n• Tap again - Cycle waveforms: Square→Saw→Triangle→Sine→Reverse Saw\n• Colors: Pink=Square, Green=Saw, Blue=Triangle, Gold=Sine, Orange=Reverse Saw")
                                            .font(.system(size: 11))
                                            .foregroundColor(.black)
                                        
                                        Text("🎯 SEQUENCER GRID")
                                            .font(.system(size: 14, weight: .bold, design: .monospaced))
                                            .foregroundColor(.black)
                                        
                                        Text("• Grid cells - Tap to activate/deactivate steps\n• 8 rows - Different notes/drums per row\n• 16 columns - 16 step sequence\n• White highlight - Shows current playing step")
                                            .font(.system(size: 11))
                                            .foregroundColor(.black)
                                        
                                        Text("🎼 PIANO & EFFECTS")
                                            .font(.system(size: 14, weight: .bold, design: .monospaced))
                                            .foregroundColor(.black)
                                        
                                        Text("• Piano keys - Play notes for selected instrument\n• ADSR - Attack, Decay, Sustain, Release envelope\n• Effects - Delay, Reverb, Distortion, Chorus\n• WAV - Export your composition as audio file")
                                            .font(.system(size: 11))
                                            .foregroundColor(.black)
                                    }
                                }
                                .padding(16)
                            }
                            .background(Color.white)
                        }
                        .frame(maxWidth: 600, maxHeight: 400)
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.black, lineWidth: 2)
                        )
                    }
                }
            }
        }
        .onAppear {
            // Force landscape orientation
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                windowScene.requestGeometryUpdate(.iOS(interfaceOrientations: .landscape))
            }
            AppDelegate.orientationLock = .landscape
        }
        .alert("WAV Export", isPresented: $showExportAlert) {
            Button("OK") { }
        } message: {
            Text("WAV export functionality coming soon!")
        }
    }
    
    private func exportWAV() {
        // TODO: Implement WAV export functionality
        showExportAlert = true
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

// Oscilloscope view matching ADSR window style
struct WaveformScope: View {
    @EnvironmentObject var audioEngine: AudioEngine
    @State private var waveformPoints: [CGPoint] = []
    @State private var freeze: Bool = false
    let timer = Timer.publish(every: 1.0/60.0, on: .main, in: .common).autoconnect()
    
    var body: some View {
        VStack(spacing: 4) {
            // Title matching ADSR style
            Text("SCOPE (TRACK \(audioEngine.selectedInstrument + 1))")
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundColor(.black)
            
            // Waveform display matching ADSR envelope display
            ZStack {
                Rectangle()
                    .fill(Color.black)
                    .cornerRadius(4)
                
                // Grid lines
                Path { path in
                    // Horizontal center line
                    path.move(to: CGPoint(x: 0, y: 40))
                    path.addLine(to: CGPoint(x: 184, y: 40))
                }
                .stroke(Color.green.opacity(0.3), lineWidth: 1)
                
                // Waveform
                if !waveformPoints.isEmpty {
                    Path { path in
                        if let first = waveformPoints.first {
                            path.move(to: first)
                        }
                        for point in waveformPoints.dropFirst() {
                            path.addLine(to: point)
                        }
                    }
                    .stroke(getWaveformColor(), lineWidth: 2)
                }
            }
            .frame(height: 80)
            
            // Freeze button
            Button(action: { freeze.toggle() }) {
                Text(freeze ? "RUN" : "FREEZE")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(freeze ? .white : .black)
                    .frame(width: 80, height: 24)
                    .background(freeze ? Color.red : Color(hex: "90EE90"))
                    .overlay(Rectangle().stroke(Color.black, lineWidth: 1))
            }
        }
        .padding(8)
        .background(
            Rectangle()
                .fill(Color.white.opacity(0.8))
                .overlay(
                    Rectangle()
                        .stroke(Color.black, lineWidth: 3)
                )
        )
        .onReceive(timer) { _ in
            if !freeze {
                updateWaveform()
            }
        }
    }
    
    private func getWaveformColor() -> Color {
        // Match instrument colors
        switch audioEngine.selectedInstrument {
        case 0: return Color(hex: "FFB6C1") // Pink
        case 1: return Color(hex: "87CEEB") // Sky Blue
        case 2: return Color(hex: "DDA0DD") // Plum
        case 3: return Color(hex: "FFD700") // Gold
        default: return Color.green
        }
    }
    
    private func updateWaveform() {
        // Get real waveform data from audio engine
        DispatchQueue.main.async {
            let width: CGFloat = 184
            let height: CGFloat = 80
            
            // Get actual audio buffer data
            let buffer = audioEngine.generateOscilloscopeData()
            var points: [CGPoint] = []
            
            for (i, sample) in buffer.enumerated() {
                let x = CGFloat(i) * width / CGFloat(buffer.count - 1)
                let y = height / 2 - CGFloat(sample) * height / 2 // Invert for proper display
                let clampedY = max(5, min(y, height - 5))
                points.append(CGPoint(x: x, y: clampedY))
            }
            
            waveformPoints = points
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