import SwiftUI

struct ArpeggiatorView: View {
    @EnvironmentObject var audioEngine: AudioEngine
    
    var body: some View {
        VStack(spacing: 16) {
            // Title
            Text("Arpeggiator")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.black)
            
            // Arpeggiator buttons
            HStack(spacing: 12) {
                ForEach(0..<3) { index in
                    ArpButton(
                        number: index + 1,
                        isSelected: audioEngine.arpeggiatorMode == index,
                        color: getArpColor(index: index)
                    ) {
                        audioEngine.arpeggiatorMode = index
                    }
                }
            }
            
            // Pattern dots display
            HStack(spacing: 8) {
                ForEach(0..<3) { index in
                    PatternDots(
                        isActive: audioEngine.arpeggiatorMode == index,
                        pattern: getPatternDots(index: index)
                    )
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.8))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.black, lineWidth: 2)
                )
        )
    }
    
    private func getArpColor(index: Int) -> Color {
        switch index {
        case 0: return .pink
        case 1: return .gray
        case 2: return .pink
        default: return .gray
        }
    }
    
    private func getPatternDots(index: Int) -> [Bool] {
        switch index {
        case 0: return [true, false, false]  // 1 dot
        case 1: return [true, true, true]    // 3 dots
        case 2: return [true, false, false]  // 1 dot
        default: return [false, false, false]
        }
    }
}

struct ArpButton: View {
    let number: Int
    let isSelected: Bool
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.2)) {
                action()
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            }
        }) {
            Text("\(number)")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.black)
                .frame(width: 50, height: 40)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isSelected ? color : color.opacity(0.6))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.black, lineWidth: isSelected ? 3 : 1)
                        )
                )
                .scaleEffect(isSelected ? 1.1 : 1.0)
        }
    }
}

struct PatternDots: View {
    let isActive: Bool
    let pattern: [Bool]
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<pattern.count, id: \.self) { index in
                Circle()
                    .fill(pattern[index] && isActive ? Color.black : Color.gray.opacity(0.3))
                    .frame(width: 8, height: 8)
            }
        }
        .frame(width: 50, height: 20)
    }
}