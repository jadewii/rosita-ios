import SwiftUI

struct ArpeggiatorView: View {
    @EnvironmentObject var audioEngine: AudioEngine
    
    var body: some View {
        // Main box with title and buttons - matching instrument selector exactly
        VStack(spacing: 2) {
            // Title
            Text("ARPEGGIATOR")
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundColor(.black)
            
            // Arpeggiator buttons - retro style
            HStack(spacing: 4) {
                ForEach(0..<3) { index in
                    RetroArpButton(
                        number: index + 1,
                        isSelected: audioEngine.arpeggiatorMode == index,
                        color: getArpColor(index: index)
                    ) {
                        audioEngine.arpeggiatorMode = index
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
    
    private func getArpColor(index: Int) -> Color {
        switch index {
        case 0: return Color(hex: "FF69B4")
        case 1: return Color(hex: "808080")
        case 2: return Color(hex: "FF69B4")
        default: return Color(hex: "808080")
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

struct RetroArpButton: View {
    let number: Int
    let isSelected: Bool
    let color: Color
    let action: () -> Void
    
    @State private var isDown = false
    
    var body: some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.1)) {
                action()
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            }
        }) {
            Text("\(number)")
                .font(.system(size: 20, weight: .bold, design: .monospaced))
                .foregroundColor(isSelected ? .black : .white)
                .frame(width: 46, height: 36)
                .background(
                    ZStack {
                        Rectangle()
                            .fill(isSelected ? color : Color.black)
                        
                        // 3D bevel effect
                        if !isDown && isSelected {
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
                                    .fill(Color.black.opacity(0.5))
                                    .frame(height: 2)
                            }
                            
                            HStack(spacing: 0) {
                                Spacer()
                                Rectangle()
                                    .fill(Color.black.opacity(0.5))
                                    .frame(width: 2)
                            }
                        }
                    }
                )
                .overlay(
                    Rectangle()
                        .stroke(isSelected ? Color.white : Color.gray, lineWidth: 2)
                )
                .offset(y: isDown ? 1 : 0)
        }
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            isDown = pressing
        }, perform: {})
    }
}

struct PatternDots: View {
    let isActive: Bool
    let pattern: [Bool]
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<pattern.count, id: \.self) { index in
                Rectangle()
                    .fill(pattern[index] && isActive ? Color.black : Color.gray.opacity(0.3))
                    .frame(width: 6, height: 6)
            }
        }
        .frame(width: 40, height: 16)
    }
}