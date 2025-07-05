import SwiftUI

struct PatternSlotsView: View {
    @EnvironmentObject var audioEngine: AudioEngine
    
    var body: some View {
        HStack(spacing: 12) {
            // Pattern number buttons
            HStack(spacing: 8) {
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
            
            Spacer()
            
            // Duplicate button
            Button(action: {
                audioEngine.duplicatePattern()
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            }) {
                Text("Dup")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.purple)
                            .shadow(radius: 2)
                    )
            }
        }
        .padding(.horizontal)
        .frame(height: 50)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.1))
                .shadow(radius: 4)
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
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(isSelected ? .black : .white)
                .frame(width: 36, height: 36)
                .background(
                    Circle()
                        .fill(isSelected ? Color.white : Color.white.opacity(0.2))
                        .shadow(radius: isSelected ? 4 : 2)
                )
                .scaleEffect(isSelected ? 1.1 : 1.0)
        }
    }
}