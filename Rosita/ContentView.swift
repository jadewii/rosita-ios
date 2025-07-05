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
                
                // Main layout - no overlapping, efficient use of space
                VStack(spacing: 4) {
                    // Top section with all controls
                    HStack(alignment: .top, spacing: 8) {
                        // Left column - Instruments, Arp, ADSR, Effects
                        VStack(spacing: 6) {
                            // Instruments row
                            InstrumentSelectorView()
                                .frame(height: 60)
                            
                            // Arpeggiator 
                            ArpeggiatorView()
                                .frame(height: 70)
                            
                            // ADSR Envelope
                            ADSRView()
                                .frame(height: 110)
                            
                            // Control buttons
                            HStack(spacing: 6) {
                                Button(action: {}) {
                                    Text("ADSR")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundColor(.black)
                                        .frame(width: 48, height: 24)
                                        .background(Color.white)
                                        .cornerRadius(4)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 4)
                                                .stroke(Color.black, lineWidth: 1)
                                        )
                                }
                                
                                Button(action: {}) {
                                    Text("Major")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundColor(.black)
                                        .frame(width: 48, height: 24)
                                        .background(Color.white)
                                        .cornerRadius(4)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 4)
                                                .stroke(Color.black, lineWidth: 1)
                                        )
                                }
                                
                                Button(action: {}) {
                                    Text("Octave")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundColor(.black)
                                        .frame(width: 48, height: 24)
                                        .background(Color.white)
                                        .cornerRadius(4)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 4)
                                                .stroke(Color.black, lineWidth: 1)
                                        )
                                }
                            }
                            
                            // Effects
                            EffectsView()
                                .frame(maxHeight: .infinity)
                        }
                        .frame(width: geometry.size.width * 0.35)
                        
                        // Right column - Transport, Pattern, Grid
                        VStack(spacing: 4) {
                            // Transport controls with BPM
                            HStack(spacing: 6) {
                                TransportControlsView()
                                
                                Spacer()
                                
                                // BPM control
                                HStack(spacing: 3) {
                                    Text("BPM:")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundColor(.black)
                                    
                                    Text("\(Int(audioEngine.bpm))")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundColor(.black)
                                        .frame(width: 36, height: 24)
                                        .background(
                                            RoundedRectangle(cornerRadius: 4)
                                                .fill(Color.pink)
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 4)
                                                        .stroke(Color.black, lineWidth: 1)
                                                )
                                        )
                                }
                            }
                            .frame(height: 32)
                            
                            // Pattern slots
                            PatternSlotsView()
                                .frame(height: 32)
                            
                            // Main sequencer grid - takes all available space
                            GridSequencerView()
                                .frame(maxHeight: .infinity)
                        }
                        .frame(width: geometry.size.width * 0.63)
                    }
                    .frame(height: geometry.size.height * 0.72)
                    
                    // Piano keyboard at bottom
                    PianoKeyboardView()
                        .frame(height: geometry.size.height * 0.26)
                }
                .padding(.horizontal, 8)
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