import SwiftUI

struct CustomSlider: View {
    @Binding var value: Double
    let range: ClosedRange<Double>
    let trackColor: Color
    let thumbColor: Color = Color(hex: "FF69B4") // Pink thumb like original
    let label: String
    
    @State private var isEditing = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label)
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundColor(.black)
                
                Spacer()
                
                Text(String(format: "%.2f", value))
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundColor(.black)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 2)
                    .background(Color.white)
                    .overlay(
                        Rectangle()
                            .stroke(Color.black, lineWidth: 2)
                    )
                    .frame(minWidth: 35)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Track background
                    Rectangle()
                        .fill(trackColor)
                        .frame(height: 24)
                        .overlay(
                            Rectangle()
                                .stroke(Color.black, lineWidth: 2)
                        )
                    
                    // Thumb
                    Rectangle()
                        .fill(thumbColor)
                        .frame(width: 20, height: 20)
                        .overlay(
                            Rectangle()
                                .stroke(Color.black, lineWidth: 2)
                        )
                        .offset(x: thumbPosition(in: geometry.size.width))
                        .scaleEffect(isEditing ? 1.1 : 1.0)
                        .animation(.easeInOut(duration: 0.1), value: isEditing)
                }
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { gesture in
                            isEditing = true
                            let newValue = valueFromPosition(gesture.location.x, width: geometry.size.width)
                            value = min(max(newValue, range.lowerBound), range.upperBound)
                        }
                        .onEnded { _ in
                            isEditing = false
                        }
                )
            }
            .frame(height: 24)
        }
    }
    
    private func thumbPosition(in width: CGFloat) -> CGFloat {
        let normalizedValue = (value - range.lowerBound) / (range.upperBound - range.lowerBound)
        let availableWidth = width - 20 // Account for thumb width
        return CGFloat(normalizedValue) * availableWidth
    }
    
    private func valueFromPosition(_ position: CGFloat, width: CGFloat) -> Double {
        let availableWidth = width - 20 // Account for thumb width
        let normalizedPosition = max(0, min(position - 10, availableWidth)) / availableWidth // Center on thumb
        return range.lowerBound + Double(normalizedPosition) * (range.upperBound - range.lowerBound)
    }
}

struct CustomEffectSlider: View {
    @Binding var value: Double
    @Binding var isEnabled: Bool
    let trackColor: Color
    let thumbColor: Color = Color(hex: "9370DB") // Purple thumb for effects
    let label: String
    
    @State private var isEditing = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .foregroundColor(.black)
            
            HStack(spacing: 8) {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        // Track background
                        Rectangle()
                            .fill(trackColor)
                            .frame(height: 24)
                            .overlay(
                                Rectangle()
                                    .stroke(Color.black, lineWidth: 2)
                            )
                        
                        // Thumb
                        Rectangle()
                            .fill(thumbColor)
                            .frame(width: 20, height: 20)
                            .overlay(
                                Rectangle()
                                    .stroke(Color.black, lineWidth: 2)
                            )
                            .offset(x: thumbPosition(in: geometry.size.width))
                            .scaleEffect(isEditing ? 1.1 : 1.0)
                            .animation(.easeInOut(duration: 0.1), value: isEditing)
                    }
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { gesture in
                                isEditing = true
                                let newValue = valueFromPosition(gesture.location.x, width: geometry.size.width)
                                value = min(max(newValue, 0), 1)
                            }
                            .onEnded { _ in
                                isEditing = false
                            }
                    )
                }
                .frame(height: 24)
                
                // Enable/disable checkbox
                Button(action: {
                    isEnabled.toggle()
                }) {
                    Rectangle()
                        .fill(isEnabled ? thumbColor : Color.gray.opacity(0.3))
                        .frame(width: 20, height: 20)
                        .overlay(
                            Rectangle()
                                .stroke(Color.black, lineWidth: 2)
                        )
                        .overlay(
                            Text(isEnabled ? "✓" : "")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                        )
                }
            }
        }
    }
    
    private func thumbPosition(in width: CGFloat) -> CGFloat {
        let availableWidth = width - 20 // Account for thumb width
        return CGFloat(value) * availableWidth
    }
    
    private func valueFromPosition(_ position: CGFloat, width: CGFloat) -> Double {
        let availableWidth = width - 20 // Account for thumb width
        let normalizedPosition = max(0, min(position - 10, availableWidth)) / availableWidth // Center on thumb
        return Double(normalizedPosition)
    }
}

// Preview
struct CustomSlider_Previews: PreviewProvider {
    @State static var testValue: Double = 0.5
    @State static var testEnabled: Bool = true
    
    static var previews: some View {
        VStack(spacing: 16) {
            CustomSlider(
                value: $testValue,
                range: 0...1,
                trackColor: Color(hex: "FFB6C1"),
                label: "A:"
            )
            
            CustomEffectSlider(
                value: $testValue,
                isEnabled: $testEnabled,
                trackColor: Color(hex: "E6E6FA"),
                label: "A:"
            )
        }
        .padding()
        .background(Color(hex: "FFB6C1"))
    }
}