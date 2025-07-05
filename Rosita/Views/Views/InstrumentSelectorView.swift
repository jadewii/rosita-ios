import SwiftUI

struct InstrumentSelectorView: View {
    @EnvironmentObject var audioEngine: AudioEngine
    
    var body: some View {
        VStack(spacing: 16) {
            // Title
            Text("Instrument")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.black)
            
            // Instrument buttons grid
            HStack(spacing: 12) {
                ForEach(0..<4) { index in
                    InstrumentButton(
                        index: index,
                        isSelected: audioEngine.selectedInstrument == index,
                        type: InstrumentType(rawValue: index) ?? .synth
                    ) {
                        audioEngine.selectedInstrument = index
                    }
                }
            }
            
            // Volume controls for each instrument
            HStack(spacing: 8) {
                ForEach(0..<3) { index in
                    VStack(spacing: 4) {
                        Button(action: {
                            // Volume up action
                        }) {
                            Text("+")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.black)
                                .frame(width: 24, height: 16)
                                .background(Color.yellow)
                                .cornerRadius(4)
                        }
                        
                        Button(action: {
                            // Volume down action
                        }) {
                            Text("-")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.black)
                                .frame(width: 24, height: 16)
                                .background(Color.yellow)
                                .cornerRadius(4)
                        }
                    }
                }
                
                // Kit 4 special display
                Text("Kit 4")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.black)
                    .frame(width: 60, height: 40)
                    .background(Color.orange)
                    .cornerRadius(8)
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
}

struct InstrumentButton: View {
    let index: Int
    let isSelected: Bool
    let type: InstrumentType
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.2)) {
                action()
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            }
        }) {
            Text(type.displayNumber)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.black)
                .frame(width: 50, height: 40)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isSelected ? type.color : type.color.opacity(0.6))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.black, lineWidth: isSelected ? 3 : 1)
                        )
                )
                .scaleEffect(isSelected ? 1.1 : 1.0)
        }
    }
}