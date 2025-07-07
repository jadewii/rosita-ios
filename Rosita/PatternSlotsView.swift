import SwiftUI

struct PatternSlotsView: View {
    @EnvironmentObject var audioEngine: AudioEngine
    
    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<8) { slot in
                RetroPatternButton(
                    number: slot + 1,
                    isSelected: audioEngine.currentPatternSlot == slot,
                    isDupTarget: audioEngine.isDupMode,
                    action: {
                        audioEngine.selectPattern(slot)
                    }
                )
            }
            
            Spacer()
                .frame(width: 6)  // Same spacing as between other buttons
            
            // Dup button - retro style (twice the size)
            RetroButton(
                title: "DUP",
                color: Color(hex: "9370DB"),
                textColor: .black,
                action: {
                    audioEngine.duplicatePattern()
                },
                width: 80,
                height: 56,
                fontSize: 16
            )
        }
    }
}