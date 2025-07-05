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
                
                // Main layout with better spacing
                VStack(spacing: 8) {
                    // Top control panel
                    HStack(alignment: .top, spacing: 10) {
                        // Left side controls
                        VStack(spacing: 8) {
                            // Instruments and Arpeggiator side by side
                            HStack(spacing: 8) {
                                InstrumentSelectorView()
                                    .frame(maxWidth: .infinity)
                                ArpeggiatorView()
                                    .frame(maxWidth: .infinity)
                            }
                            .frame(height: 80)
                            
                            // ADSR Envelope
                            ADSRView()
                                .frame(height: 120)
                            
                            // Control buttons between ADSR and Effects
                            HStack(spacing: 8) {
                                Button(action: {}) {
                                    Text("ADSR")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(.black)
                                        .frame(width: 55, height: 28)
                                        .background(Color.white)
                                        .cornerRadius(6)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 6)
                                                .stroke(Color.black, lineWidth: 1)
                                        )
                                }
                                
                                Button(action: {}) {
                                    Text("Major")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(.black)
                                        .frame(width: 55, height: 28)
                                        .background(Color.white)
                                        .cornerRadius(6)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 6)
                                                .stroke(Color.black, lineWidth: 1)
                                        )
                                }
                                
                                Button(action: {}) {
                                    Text("Octave")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(.black)
                                        .frame(width: 55, height: 28)
                                        .background(Color.white)
                                        .cornerRadius(6)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 6)
                                                .stroke(Color.black, lineWidth: 1)
                                        )
                                }
                            }
                            .frame(height: 30)
                            
                            // Effects
                            EffectsView()
                                .frame(maxHeight: .infinity)
                        }
                        .frame(width: geometry.size.width * 0.4)
                        
                        // Right side - Sequencer section
                        VStack(spacing: 6) {
                            // Transport controls and pattern buttons
                            HStack(spacing: 8) {
                                TransportControlsView()
                                    .frame(maxWidth: .infinity)
                                
                                // BPM control
                                HStack(spacing: 4) {
                                    Text("BPM:")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(.black)
                                    
                                    Text("\(Int(audioEngine.bpm))")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(.black)
                                        .frame(width: 40, height: 28)
                                        .background(
                                            RoundedRectangle(cornerRadius: 6)
                                                .fill(Color.pink)
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 6)
                                                        .stroke(Color.black, lineWidth: 1)
                                                )
                                        )
                                }
                            }
                            .frame(height: 40)
                            
                            PatternSlotsView()
                                .frame(height: 35)
                            
                            // Main sequencer grid
                            GridSequencerView()
                                .frame(maxHeight: .infinity)
                        }
                        .frame(width: geometry.size.width * 0.6)
                    }
                    .frame(height: geometry.size.height * 0.68)
                    
                    // Bottom piano keyboard  
                    PianoKeyboardView()
                        .frame(height: geometry.size.height * 0.28)
                }
                .padding(.horizontal, 10)
                .padding(.top, 8)
                .padding(.bottom, 4)
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