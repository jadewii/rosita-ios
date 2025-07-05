import SwiftUI

struct PatternSlotsView: View {
    @EnvironmentObject var audioEngine: AudioEngine
    
    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<8) { slot in
                RetroPatternButton(
                    number: slot + 1,
                    isSelected: audioEngine.currentPatternSlot == slot,
                    action: {
                        audioEngine.switchToPattern(slot)
                    }
                )
            }
            
            // Dup button - retro style (twice the size)
            RetroButton(
                title: "DUP",
                color: Color(hex: "FF00FF"),
                textColor: .black,
                action: {
                    audioEngine.duplicateCurrentPattern()
                },
                width: 80,
                height: 56,
                fontSize: 16
            )
        }
    }
}