import SwiftUI

struct PatternSlotsView: View {
    @EnvironmentObject var audioEngine: AudioEngine
    
    var body: some View {
        HStack(spacing: 8) {
            // Pattern number buttons in a horizontal row like web version
            HStack(spacing: 4) {
                ForEach(0..<8) { index in
                    PatternButton(
                        number: index + 1,
                        isSelected: audioEngine.currentPattern == index
                    ) {
                        audioEngine.currentPattern = index
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    }
                }
            }
            
            // Duplicate button
            Button(action: {
                audioEngine.duplicatePattern()
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            }) {
                Text("Dup")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 50, height: 32)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.purple)
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(Color.black, lineWidth: 1)
                            )
                    )
            }
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white.opacity(0.15))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

struct PatternButton: View {
    let number: Int
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.2)) {
                action()
            }
        }) {
            Text("\(number)")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(isSelected ? .black : .white)
                .frame(width: 28, height: 28)
                .background(
                    Circle()
                        .fill(isSelected ? Color.white : Color.white.opacity(0.2))
                        .overlay(
                            Circle()
                                .stroke(Color.white, lineWidth: isSelected ? 2 : 1)
                        )
                        .shadow(color: isSelected ? Color.white.opacity(0.6) : Color.clear, radius: 4)
                )
                .scaleEffect(isSelected ? 1.1 : 1.0)
        }
    }
}