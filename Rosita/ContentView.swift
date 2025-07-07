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
            
            VStack(spacing: 0) {
                // Add small pink space at top
                Spacer()
                    .frame(height: 56)
                
                // 🔝 Top Controls - FIXED HEIGHT
                VStack(spacing: 0) {
                    // Transport controls row
                    HStack(spacing: 8) {
                        // BPM controls in top left
                        HStack(spacing: 8) {
                            Text("BPM")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.black)
                            
                            CustomSlider(
                                value: $audioEngine.bpm,
                                range: 60...200,
                                trackColor: Color(hex: "FF1493"),
                                label: ""
                            )
                            .frame(width: 120, height: 30)
                            
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
                        .padding(.leading, 12)
                        .padding(.vertical, 10)
                        
                        Spacer()
                            .frame(width: 12)
                        
                        TransportControlsView()
                        
                        Spacer()
                        
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
                    .padding(.horizontal, 0)  // Remove padding since we have it on the main container
                    
                    // Add spacing to move pattern buttons down
                    Spacer()
                        .frame(height: 25)
                    
                    // Pattern row
                    HStack(spacing: 31) {  // Increased by 15 (was 16, now 31)
                        HStack {
                            // Empty space for left panel
                        }
                        .frame(width: 190)  // Match the reduced panel width
                        
                        PatternSlotsView()
                        
                        Spacer()
                        
                        InstrumentSelectorView()
                            .frame(width: 210, height: 76)
                        
                        ArpeggiatorView()
                            .frame(width: 190, height: 76)
                            .padding(.leading, 4)
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
                        // Oscilloscope section
                        OscilloscopeView()

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
                        
                        // Effects section
                        EffectsView()
                        
                        Spacer()
                        
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
                    }
                    .frame(width: 190)  // Further reduced to prevent right cutoff
                    .offset(y: -95)  // Move entire left panel up even more (-20)
                    
                    // Grid Area 
                    GridSequencerView()
                }
                
                // Add space above keyboard
                Spacer()
                    .frame(height: 30)
                
                // 🎹 KEYBOARD - FULL WIDTH, OUTSIDE OF HSTACK
                PianoKeyboardView()
                    .frame(maxWidth: .infinity)
                    .frame(height: 140)  // Bigger to show all keys
                    .padding(.horizontal, 0)
                    .offset(y: -72)  // Move down to avoid black line touching keys
                
                // Small bottom margin
                Spacer()
                    .frame(height: 30)  // More space to separate keyboard from black edge
            }
            .padding(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 4))  // Small right padding to prevent cutoff
            .background(Color(hex: "FFB6C1"))
            .overlay(
                // Help Panel overlay
                Group {
                    if showHelp {
                        HelpPanelPopup(isShowing: $showHelp)
                    }
                }
            )
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
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