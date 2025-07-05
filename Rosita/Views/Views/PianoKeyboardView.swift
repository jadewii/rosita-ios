import SwiftUI

struct PianoKeyboardView: View {
    @EnvironmentObject var audioEngine: AudioEngine
    @State private var pressedKeys: Set<Int> = []
    
    let whiteKeyNotes = [48, 50, 52, 53, 55, 57, 59, 60, 62, 64, 65, 67, 69, 71, 72] // C to C (2 octaves)
    let blackKeyPositions = [1, 2, 4, 5, 6, 8, 9, 11, 12, 13] // Positions where black keys appear
    let blackKeyNotes = [49, 51, 54, 56, 58, 61, 63, 66, 68, 70] // C# to A#
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // White keys
                HStack(spacing: 2) {
                    ForEach(0..<whiteKeyNotes.count, id: \.self) { index in
                        WhiteKey(
                            note: whiteKeyNotes[index],
                            isPressed: pressedKeys.contains(whiteKeyNotes[index]),
                            instrumentColor: InstrumentType(rawValue: audioEngine.selectedInstrument)?.color ?? .pink,
                            width: (geometry.size.width - CGFloat(whiteKeyNotes.count - 1) * 2) / CGFloat(whiteKeyNotes.count)
                        ) { note, isPressed in
                            handleKeyPress(note: note, isPressed: isPressed)
                        }
                    }
                }
                
                // Black keys
                HStack(spacing: 0) {
                    ForEach(0..<whiteKeyNotes.count - 1, id: \.self) { index in
                        if shouldShowBlackKey(at: index) {
                            let blackKeyIndex = getBlackKeyIndex(for: index)
                            BlackKey(
                                note: blackKeyNotes[blackKeyIndex],
                                isPressed: pressedKeys.contains(blackKeyNotes[blackKeyIndex]),
                                instrumentColor: InstrumentType(rawValue: audioEngine.selectedInstrument)?.color ?? .pink,
                                width: (geometry.size.width - CGFloat(whiteKeyNotes.count - 1) * 2) / CGFloat(whiteKeyNotes.count) * 0.6,
                                whiteKeyWidth: (geometry.size.width - CGFloat(whiteKeyNotes.count - 1) * 2) / CGFloat(whiteKeyNotes.count)
                            ) { note, isPressed in
                                handleKeyPress(note: note, isPressed: isPressed)
                            }
                            .offset(x: CGFloat(index) * ((geometry.size.width - CGFloat(whiteKeyNotes.count - 1) * 2) / CGFloat(whiteKeyNotes.count) + 2) + (geometry.size.width - CGFloat(whiteKeyNotes.count - 1) * 2) / CGFloat(whiteKeyNotes.count) * 0.7)
                        }
                    }
                }
            }
            .frame(height: 120)
        }
        .frame(height: 120)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.3))
        )
    }
    
    private func shouldShowBlackKey(at position: Int) -> Bool {
        let pattern = [true, true, false, true, true, true, false] // C# D# - F# G# A# -
        return pattern[position % 7]
    }
    
    private func getBlackKeyIndex(for position: Int) -> Int {
        var count = 0
        for i in 0..<position {
            if shouldShowBlackKey(at: i) {
                count += 1
            }
        }
        return count
    }
    
    private func handleKeyPress(note: Int, isPressed: Bool) {
        if isPressed {
            pressedKeys.insert(note)
            audioEngine.noteOn(note: note)
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        } else {
            pressedKeys.remove(note)
            audioEngine.noteOff(note: note)
        }
    }
}

struct WhiteKey: View {
    let note: Int
    let isPressed: Bool
    let instrumentColor: Color
    let width: CGFloat
    let onPress: (Int, Bool) -> Void
    
    @State private var isTouched = false
    
    var body: some View {
        Rectangle()
            .fill(isPressed || isTouched ? instrumentColor : Color.white)
            .frame(width: width, height: 100)
            .cornerRadius(4)
            .shadow(radius: 2)
            .scaleEffect(isPressed || isTouched ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: isPressed || isTouched)
            .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
                isTouched = pressing
                onPress(note, pressing)
            }, perform: {})
    }
}

struct BlackKey: View {
    let note: Int
    let isPressed: Bool
    let instrumentColor: Color
    let width: CGFloat
    let whiteKeyWidth: CGFloat
    let onPress: (Int, Bool) -> Void
    
    @State private var isTouched = false
    
    var body: some View {
        Rectangle()
            .fill(isPressed || isTouched ? instrumentColor : Color.black)
            .frame(width: width, height: 60)
            .cornerRadius(4)
            .shadow(radius: 2)
            .scaleEffect(isPressed || isTouched ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: isPressed || isTouched)
            .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
                isTouched = pressing
                onPress(note, pressing)
            }, perform: {})
            .zIndex(1)
    }
}