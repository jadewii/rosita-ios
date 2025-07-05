import SwiftUI

struct ContentView: View {
    @EnvironmentObject var audioEngine: AudioEngine
    @State private var showHelp = false
    @State private var showExportAlert = false
    
    var body: some View {
        GeometryReader { geometry in
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
                
                // Main layout - matching the reference image structure
                VStack(spacing: 6) {
                    // TOP SECTION - Reorganized layout
                    VStack(spacing: 8) {
                        // First row: Transport controls, control buttons, BPM, Instrument and Arpeggiator
                        HStack(spacing: 8) {
                            // Transport controls
                            TransportControlsView()
                            
                            // Control buttons (ADSR, Major, Octave) next to MIXER
                            HStack(spacing: 6) {
                                RetroButton(
                                    title: "ADSR",
                                    color: Color(hex: "00FFFF"),
                                    textColor: .black,
                                    action: {},
                                    width: 70,
                                    height: 42,
                                    fontSize: 14
                                )
                                
                                RetroButton(
                                    title: "MAJOR",
                                    color: Color(hex: "FFFF00"),
                                    textColor: .black,
                                    action: {},
                                    width: 70,
                                    height: 42,
                                    fontSize: 14
                                )
                                
                                RetroButton(
                                    title: "OCTAVE",
                                    color: Color(hex: "FF00FF"),
                                    textColor: .black,
                                    action: {},
                                    width: 70,
                                    height: 42,
                                    fontSize: 14
                                )
                            }
                            
                            // Instrument, Arpeggiator, and utility buttons in one row
                            HStack(spacing: 8) {
                                InstrumentSelectorView()
                                    .frame(width: 200, height: 60)
                                
                                ArpeggiatorView()
                                    .frame(width: 200, height: 60)
                                
                                // Help and Export buttons
                                VStack(spacing: 4) {
                                    RetroButton(
                                        title: "?",
                                        color: Color(hex: "87CEEB"),
                                        textColor: .black,
                                        action: {
                                            showHelp = true
                                        },
                                        width: 44,
                                        height: 28,
                                        fontSize: 16
                                    )
                                    
                                    RetroButton(
                                        title: "WAV",
                                        color: Color(hex: "90EE90"),
                                        textColor: .black,
                                        action: {
                                            exportWAV()
                                        },
                                        width: 44,
                                        height: 28,
                                        fontSize: 10
                                    )
                                }
                            }
                        }
                        .frame(height: 60)
                        
                        // Pink space between sections
                        Spacer()
                            .frame(height: 12)
                        
                        // Second row: Pattern slots and BPM control
                        HStack(spacing: 16) {
                            Spacer()
                            
                            PatternSlotsView()
                                .frame(height: 56)
                            
                            // BPM control with slider
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
                                
                                Slider(value: $audioEngine.bpm, in: 60...200, step: 1)
                                    .frame(width: 120)
                                    .accentColor(Color(hex: "FF1493"))
                            }
                            
                            Spacer()
                        }
                    }
                    .padding(.horizontal, 8)
                    
                    // MAIN CONTENT AREA
                    HStack(alignment: .top, spacing: 8) {
                        // LEFT COLUMN - ADSR and Effects with proper spacing
                        VStack(spacing: 8) {
                            // ADSR Envelope - lowered position
                            ADSRView()
                                .frame(height: 140)
                            
                            // Effects - aligned with grid end
                            EffectsView()
                                .frame(maxHeight: .infinity)
                        }
                        .frame(width: 200) // Fixed width for left column
                        
                        // CENTER AND RIGHT AREA - Just the sequencer grid
                        GridSequencerView()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                    .frame(maxHeight: .infinity)
                    .padding(.horizontal, 8)
                    
                    // BOTTOM - Piano keyboard
                    PianoKeyboardView()
                        .frame(height: max(120, geometry.size.height * 0.18))
                        .padding(.horizontal, 8)
                        .padding(.bottom, 4)
                }
                .padding(.vertical, 4)
                
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
            UIDevice.current.setValue(UIInterfaceOrientation.landscapeRight.rawValue, forKey: "orientation")
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

// App Delegate for orientation lock
class AppDelegate: NSObject, UIApplicationDelegate {
    static var orientationLock = UIInterfaceOrientationMask.all
    
    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        return AppDelegate.orientationLock
    }
}