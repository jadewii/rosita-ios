import SwiftUI

struct PianoKeyboardView: View {
    @EnvironmentObject var audioEngine: AudioEngine
    @State private var pressedKeys: Set<Int> = []
    
    // Two full octaves: C4 to B5
    let whiteKeys = [
        60, 62, 64, 65, 67, 69, 71,  // C4-B4
        72, 74, 76, 77, 79, 81, 83   // C5-B5
    ]
    
    // Define all black keys with their positions - proper 2-3 grouping
    let blackKeys: [(note: Int, position: CGFloat)] = [
        // First octave - 2 then 3 black keys
        (61, 0.75),   // C#4
        (63, 1.75),   // D#4
        (66, 3.75),   // F#4
        (68, 4.75),   // G#4
        (70, 5.75),   // A#4
        // Second octave - 2 then 3 black keys
        (73, 7.75),   // C#5
        (75, 8.75),   // D#5
        (78, 10.75),  // F#5
        (80, 11.75),  // G#5
        (82, 12.75)   // A#5
    ]
    
    var body: some View {
        GeometryReader { geometry in
            let totalWidth = geometry.size.width
            let whiteKeyWidth = totalWidth / CGFloat(whiteKeys.count)
            let blackKeyWidth = whiteKeyWidth * 0.65
            let keyboardHeight = geometry.size.height
            let blackKeyHeight = keyboardHeight * 0.65
            
            ZStack(alignment: .topLeading) {
                // White keys layer
                HStack(spacing: 0) {
                    ForEach(0..<whiteKeys.count, id: \.self) { index in
                        WhiteKey(
                            isPressed: pressedKeys.contains(whiteKeys[index]),
                            width: whiteKeyWidth,
                            height: keyboardHeight
                        )
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { _ in
                                    if !pressedKeys.contains(whiteKeys[index]) {
                                        pressedKeys.insert(whiteKeys[index])
                                        audioEngine.noteOn(note: whiteKeys[index])
                                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                    }
                                }
                                .onEnded { _ in
                                    pressedKeys.remove(whiteKeys[index])
                                    audioEngine.noteOff(note: whiteKeys[index])
                                }
                        )
                    }
                }
                
                // Black keys layer - positioned absolutely
                ForEach(blackKeys, id: \.note) { blackKey in
                    BlackKey(
                        isPressed: pressedKeys.contains(blackKey.note),
                        width: blackKeyWidth,
                        height: blackKeyHeight
                    )
                    .position(
                        x: blackKey.position * whiteKeyWidth + blackKeyWidth / 2,
                        y: blackKeyHeight / 2
                    )
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { _ in
                                if !pressedKeys.contains(blackKey.note) {
                                    pressedKeys.insert(blackKey.note)
                                    audioEngine.noteOn(note: blackKey.note)
                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                }
                            }
                            .onEnded { _ in
                                pressedKeys.remove(blackKey.note)
                                audioEngine.noteOff(note: blackKey.note)
                            }
                    )
                }
            }
        }
        .frame(height: 200) // Reasonable height
        .background(
            Rectangle()
                .fill(Color.white)
                .overlay(
                    Rectangle()
                        .stroke(Color.black, lineWidth: 3)
                )
        )
    }
    
    private func hasBlackKeyAfter(whiteKeyIndex: Int) -> Bool {
        // Piano pattern: Black keys exist after C, D, F, G, A
        // But NOT after E and B
        let noteValue = whiteKeys[whiteKeyIndex] % 12
        
        // MIDI note values: C=0, D=2, E=4, F=5, G=7, A=9, B=11
        switch noteValue {
        case 0: return true  // C -> C#
        case 2: return true  // D -> D#
        case 4: return false // E -> F (no black key)
        case 5: return true  // F -> F#
        case 7: return true  // G -> G#
        case 9: return true  // A -> A#
        case 11: return false // B -> C (no black key)
        default: return false
        }
    }
    
    private func handleKeyPress(note: Int) {
        if pressedKeys.contains(note) {
            pressedKeys.remove(note)
            audioEngine.noteOff(note: note)
        } else {
            pressedKeys.insert(note)
            audioEngine.noteOn(note: note)
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }
    }
}

// White key component
struct WhiteKey: View {
    let isPressed: Bool
    let width: CGFloat
    let height: CGFloat
    
    var body: some View {
        Rectangle()
            .fill(isPressed ? Color(hex: "FF69B4").opacity(0.3) : Color.white)
            .frame(width: width, height: height)
            .overlay(
                Rectangle()
                    .stroke(Color.black, lineWidth: 2)
            )
    }
}

// Black key component
struct BlackKey: View {
    let isPressed: Bool
    let width: CGFloat
    let height: CGFloat
    
    var body: some View {
        Rectangle()
            .fill(isPressed ? Color(hex: "FF1493") : Color(hex: "FF69B4"))
            .frame(width: width, height: height)
            .overlay(
                Rectangle()
                    .stroke(Color.black, lineWidth: 2)
            )
    }
}