import SwiftUI

struct ContentView: View {
    @EnvironmentObject var audioEngine: AudioEngine
    @State private var showHelp = false
    @State private var showExportAlert = false
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.verticalSizeClass) var verticalSizeClass
    
    var body: some View {
        GeometryReader { geometry in
            let isCompact = geometry.size.width < 1100
            let isPhone = geometry.size.width < 800
            let scaleFactor = isPhone ? 0.7 : (isCompact ? 0.85 : 1.0)
            
            // Only calculate keyboard height - everything else is flexbox
            let keyboardHeight: CGFloat = isPhone ? 110 : 130
            
            VStack(spacing: 0) {
                // TOP SECTION: Controls + Pattern Row (LOCKED HEIGHT)
                VStack(spacing: 2) {
                        // Transport controls row
                        HStack(spacing: 8) {
                            Spacer()
                                .frame(width: 240) // Add left spacing to accommodate oscilloscope
                            
                            TransportControlsView()
                            
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
                            
                            Spacer()
                            
                            InstrumentSelectorView()
                                .frame(width: 180, height: 70)
                            
                            ArpeggiatorView()
                                .frame(width: 160, height: 70)
                            
                            RetroButton(
                                title: "WAV",
                                color: Color(hex: "90EE90"),
                                textColor: .black,
                                action: { exportWAV() },
                                width: 36,
                                height: 36,
                                fontSize: 12
                            )
                            
                            RetroButton(
                                title: "?",
                                color: Color(hex: "87CEEB"),
                                textColor: .black,
                                action: { showHelp = true },
                                width: 36,
                                height: 36,
                                fontSize: 20
                            )
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 2)
                        
                        // Pattern row
                        HStack(spacing: 16) {
                            Spacer()
                                .frame(width: 240) // Match the transport controls spacing
                            
                            PatternSlotsView()
                                .frame(height: 50)
                            
                            VStack(spacing: 2) {
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
                                .frame(width: 120, height: 30)
                            }
                            
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
                            
                            Spacer()
                        }
                        .padding(.horizontal, 12)
                    }
                    .frame(height: 100) // LOCKED HEIGHT for top section
                    
                    // MAIN AREA: Left Panel + Grid (maxHeight: .infinity is the magic)
                    HStack(alignment: .top, spacing: 0) {
                        // Left sidebar (fixed width)
                        VStack(alignment: .leading, spacing: 2) {
                            // Oscilloscope
                            OscilloscopeView()
                                .frame(width: 220, height: 100)
                            
                            // ADSR section
                            VStack(spacing: 0) {
                                Text("ADSR (TRACK \(audioEngine.selectedInstrument + 1))")
                                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                                    .foregroundColor(.black)
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .padding(.vertical, 4)
                                    .background(Color.white.opacity(0.3))
                                
                                ADSRView()
                            }
                            .background(
                                Rectangle()
                                    .fill(Color.white.opacity(0.8))
                                    .overlay(
                                        Rectangle()
                                            .stroke(Color.black, lineWidth: 3)
                                    )
                            )
                            .frame(width: 220)
                            
                            EffectsView()
                                .frame(width: 220)
                            
                            // KB Octave controls
                            HStack(spacing: 4) {
                                Text("KB OCTAVE")
                                    .font(.system(size: 10, weight: .bold))
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
                                    width: 30,
                                    height: 26,
                                    fontSize: 14
                                )
                                
                                Text("\(audioEngine.transpose / 12)")
                                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                                    .foregroundColor(.black)
                                    .frame(width: 24)
                                
                                RetroButton(
                                    title: "+",
                                    color: Color(hex: "FF69B4"),
                                    textColor: .black,
                                    action: {
                                        if audioEngine.transpose < 24 {
                                            audioEngine.transpose += 12
                                        }
                                    },
                                    width: 30,
                                    height: 26,
                                    fontSize: 14
                                )
                            }
                            .padding(8)
                            .background(
                                Rectangle()
                                    .fill(Color(hex: "FFB6C1").opacity(0.5))
                                    .overlay(
                                        Rectangle()
                                            .stroke(Color.black, lineWidth: 2)
                                    )
                            )
                            
                            Spacer()
                        }
                        .padding()
                        .background(Color(hex: "FFB6C1").opacity(0.1))
                        
                        // Sequencer grid (flexible width and height)
                        GridSequencerView()
                            .padding()
                    }
                    .frame(maxHeight: .infinity) // THIS IS THE MAGIC - takes all remaining space
                    
                    // KEYBOARD: Fixed height at bottom (LOCKED HEIGHT)
                    PianoKeyboardView()
                        .frame(height: keyboardHeight)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [Color(hex: "FFB6C1"), Color(hex: "FF1493")]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                
                // Help Panel overlay
                if showHelp {
                    HelpPanelPopup(isShowing: $showHelp)
            }
        }
        .ignoresSafeArea(.keyboard)
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