import SwiftUI

struct OscilloscopeView: View {
    @EnvironmentObject var audioEngine: AudioEngine
    @State private var waveformPoints: [CGPoint] = []
    @State private var isFrozen = false
    @State private var frozenWaveform: [CGPoint] = []
    let timer = Timer.publish(every: 0.033, on: .main, in: .common).autoconnect() // ~30 FPS
    
    // Track colors
    private var waveformColor: Color {
        switch audioEngine.selectedInstrument {
        case 0: return Color(hex: "FFA500") // Orange for Track 1
        case 1: return Color(hex: "0080FF") // Blue for Track 2  
        case 2: return Color(hex: "9370DB") // Purple for Track 3
        default: return Color(hex: "FFD700") // Gold for Track 4 (drums)
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Title bar with track indicator and freeze button
            HStack {
                Text("SCOPE (TRACK \(audioEngine.selectedInstrument + 1))")
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity, alignment: .center)
                
                Button(action: {
                    isFrozen.toggle()
                    if isFrozen {
                        frozenWaveform = waveformPoints
                    }
                }) {
                    Text(isFrozen ? "UNFREEZE" : "FREEZE")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(isFrozen ? .white : .black)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(
                            Rectangle()
                                .fill(isFrozen ? Color.red : Color(hex: "00FFFF"))
                                .overlay(
                                    Rectangle()
                                        .stroke(Color.black, lineWidth: 1)
                                )
                        )
                }
                .padding(.trailing, 4)
            }
            .padding(.vertical, 4)
            .background(Color.white.opacity(0.3))
            
            // Waveform display
            GeometryReader { geometry in
                ZStack {
                    // Background
                    Rectangle()
                        .fill(Color.black)
                    
                    // Grid lines
                    Path { path in
                        let midY = geometry.size.height / 2
                        
                        // Horizontal center line
                        path.move(to: CGPoint(x: 0, y: midY))
                        path.addLine(to: CGPoint(x: geometry.size.width, y: midY))
                        
                        // Horizontal quarter lines
                        path.move(to: CGPoint(x: 0, y: geometry.size.height * 0.25))
                        path.addLine(to: CGPoint(x: geometry.size.width, y: geometry.size.height * 0.25))
                        path.move(to: CGPoint(x: 0, y: geometry.size.height * 0.75))
                        path.addLine(to: CGPoint(x: geometry.size.width, y: geometry.size.height * 0.75))
                        
                        // Vertical grid lines
                        let gridSpacing = geometry.size.width / 8
                        for i in 1..<8 {
                            let x = gridSpacing * CGFloat(i)
                            path.move(to: CGPoint(x: x, y: 0))
                            path.addLine(to: CGPoint(x: x, y: geometry.size.height))
                        }
                    }
                    .stroke(waveformColor.opacity(0.2), lineWidth: 1)
                    
                    // Waveform
                    let displayPoints = isFrozen ? frozenWaveform : waveformPoints
                    if !displayPoints.isEmpty {
                        Path { path in
                            path.move(to: displayPoints[0])
                            for point in displayPoints.dropFirst() {
                                path.addLine(to: point)
                            }
                        }
                        .stroke(waveformColor, lineWidth: 2)
                        .shadow(color: waveformColor.opacity(0.8), radius: 2)
                    } else {
                        // Default center line when no audio
                        Path { path in
                            let midY = geometry.size.height / 2
                            path.move(to: CGPoint(x: 0, y: midY))
                            path.addLine(to: CGPoint(x: geometry.size.width, y: midY))
                        }
                        .stroke(waveformColor.opacity(0.5), lineWidth: 2)
                    }
                }
                .onReceive(timer) { _ in
                    if !isFrozen {
                        updateWaveform(size: geometry.size)
                    }
                }
            }
            .frame(height: 80)
            .cornerRadius(4)
        }
        .background(
            Rectangle()
                .fill(Color.white.opacity(0.8))
                .overlay(
                    Rectangle()
                        .stroke(Color.black, lineWidth: 3)
                )
        )
    }
    
    private func updateWaveform(size: CGSize) {
        // Get audio buffer data from the audio engine
        let bufferData = audioEngine.getAudioBuffer()
        
        guard !bufferData.isEmpty else {
            // No audio data - show flat line
            waveformPoints = [
                CGPoint(x: 0, y: size.height / 2),
                CGPoint(x: size.width, y: size.height / 2)
            ]
            return
        }
        
        // Convert buffer data to display points
        let pointCount = min(bufferData.count, 256) // More points for smoother waveform
        let step = max(1, bufferData.count / pointCount)
        
        waveformPoints = []
        for i in 0..<pointCount {
            let index = i * step
            if index < bufferData.count {
                let sample = bufferData[index]
                let x = (CGFloat(i) / CGFloat(pointCount - 1)) * size.width
                let y = (1.0 - CGFloat(sample + 1.0) / 2.0) * size.height // Convert from [-1, 1] to [0, height]
                waveformPoints.append(CGPoint(x: x, y: y))
            }
        }
    }
}