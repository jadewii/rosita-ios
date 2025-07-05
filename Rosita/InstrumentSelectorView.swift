import SwiftUI

struct InstrumentSelectorView: View {
    @EnvironmentObject var audioEngine: AudioEngine
    
    var body: some View {
        VStack(spacing: 4) {
            // Title
            Text("INSTRUMENT")
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundColor(.black)
            
            // Instrument buttons in a single row - retro style
            HStack(spacing: 6) {
                ForEach(0..<4) { index in
                    RetroInstrumentButton(
                        index: index,
                        isSelected: audioEngine.selectedInstrument == index,
                        type: InstrumentType(rawValue: index) ?? .synth
                    ) {
                        audioEngine.selectedInstrument = index
                    }
                }
            }
        }
        .padding(8)
        .background(
            Rectangle()
                .fill(Color.white)
                .overlay(
                    Rectangle()
                        .stroke(Color.black, lineWidth: 2)
                )
        )
    }
}

struct RetroInstrumentButton: View {
    let index: Int
    let isSelected: Bool
    let type: InstrumentType
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.1)) {
                action()
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            }
        }) {
            Text(type.displayNumber)
                .font(.system(size: 14, weight: .bold, design: .monospaced))
                .foregroundColor(isSelected ? .black : Color.white.opacity(0.8))
                .frame(width: 36, height: 36)
                .background(
                    Rectangle()
                        .fill(isSelected ? type.color : type.color.opacity(0.3))
                        .overlay(
                            ZStack {
                                // 3D bevel effect
                                if isSelected {
                                    // Top and left highlight
                                    VStack(spacing: 0) {
                                        Rectangle()
                                            .fill(Color.white.opacity(0.4))
                                            .frame(height: 2)
                                        Spacer()
                                    }
                                    
                                    HStack(spacing: 0) {
                                        Rectangle()
                                            .fill(Color.white.opacity(0.4))
                                            .frame(width: 2)
                                        Spacer()
                                    }
                                    
                                    // Bottom and right shadow
                                    VStack(spacing: 0) {
                                        Spacer()
                                        Rectangle()
                                            .fill(Color.black.opacity(0.6))
                                            .frame(height: 2)
                                    }
                                    
                                    HStack(spacing: 0) {
                                        Spacer()
                                        Rectangle()
                                            .fill(Color.black.opacity(0.6))
                                            .frame(width: 2)
                                    }
                                }
                                
                                Rectangle()
                                    .stroke(isSelected ? Color.white : Color.gray, lineWidth: 2)
                            }
                        )
                )
        }
    }
}