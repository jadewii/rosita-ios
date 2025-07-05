import SwiftUI

struct ContentView: View {
    @EnvironmentObject var audioEngine: AudioEngine
    
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
                            
                            // BPM display
                            HStack(spacing: 3) {
                                Text("BPM:")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(.black)
                                
                                Text("\(Int(audioEngine.bpm))")
                                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                                    .foregroundColor(.black)
                                    .frame(width: 36, height: 42)
                                    .background(
                                        Rectangle()
                                            .fill(Color.pink)
                                            .overlay(
                                                Rectangle()
                                                    .stroke(Color.black, lineWidth: 2)
                                            )
                                    )
                            }
                            
                            // Instrument and Arpeggiator in one row
                            HStack(spacing: 8) {
                                InstrumentSelectorView()
                                    .frame(width: 200, height: 60)
                                
                                ArpeggiatorView()
                                    .frame(width: 200, height: 60)
                            }
                        }
                        .frame(height: 60)
                        
                        // Pink space between sections
                        Spacer()
                            .frame(height: 12)
                        
                        // Second row: Just pattern slots centered with more space
                        HStack {
                            Spacer()
                            PatternSlotsView()
                                .frame(height: 56)
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
            }
        }
        .onAppear {
            UIDevice.current.setValue(UIInterfaceOrientation.landscapeRight.rawValue, forKey: "orientation")
            AppDelegate.orientationLock = .landscape
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

// App Delegate for orientation lock
class AppDelegate: NSObject, UIApplicationDelegate {
    static var orientationLock = UIInterfaceOrientationMask.all
    
    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        return AppDelegate.orientationLock
    }
}