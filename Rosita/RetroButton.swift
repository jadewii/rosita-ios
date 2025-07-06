import SwiftUI

// Custom retro-style button with square corners and old-school aesthetic
struct RetroButton: View {
    let title: String
    let color: Color
    let textColor: Color
    let action: () -> Void
    var width: CGFloat? = nil
    var height: CGFloat = 24
    var fontSize: CGFloat = 11
    var isPressed: Bool = false
    
    @State private var isDown = false
    
    var body: some View {
        Button(action: {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            action()
        }) {
            Text(title)
                .font(.system(size: fontSize, weight: .bold, design: .monospaced))
                .foregroundColor(isDown ? .white : textColor)
                .frame(width: width, height: height)
                .background(
                    ZStack {
                        // Main button color
                        Rectangle()
                            .fill(isDown ? Color.black.opacity(0.8) : color)
                        
                        // 3D bevel effect for retro look
                        if !isDown {
                            // Top and left highlight
                            VStack(spacing: 0) {
                                Rectangle()
                                    .fill(Color.white.opacity(0.3))
                                    .frame(height: 2)
                                Spacer()
                            }
                            
                            HStack(spacing: 0) {
                                Rectangle()
                                    .fill(Color.white.opacity(0.3))
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
                        .stroke(Color.black, lineWidth: 2)
                )
                .offset(y: isDown ? 1 : 0)
        }
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            isDown = pressing
        }, perform: {})
    }
}

// Pattern slot button with retro style
struct RetroPatternButton: View {
    let number: Int
    let isSelected: Bool
    var isDupTarget: Bool = false
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            action()
        }) {
            Text("\(number)")
                .font(.system(size: 16, weight: .bold, design: .monospaced))
                .foregroundColor(isSelected ? .black : (isDupTarget ? .yellow : .white))
                .frame(width: 56, height: 56)
                .background(
                    Rectangle()
                        .fill(isSelected ? Color.yellow : Color.black)
                        .overlay(
                            Rectangle()
                                .stroke(isDupTarget ? Color.yellow : Color.black, lineWidth: isSelected ? 3 : 2)
                        )
                        .animation(.easeInOut(duration: 0.3), value: isDupTarget)
                )
        }
    }
}

// Retro toggle button for effects
struct RetroToggleButton: View {
    @Binding var isOn: Bool
    let size: CGFloat = 20
    
    var body: some View {
        Button(action: {
            isOn.toggle()
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }) {
            Rectangle()
                .fill(isOn ? Color.green : Color.red)
                .frame(width: size, height: size)
                .overlay(
                    ZStack {
                        // 3D effect
                        if !isOn {
                            VStack(spacing: 0) {
                                Rectangle()
                                    .fill(Color.white.opacity(0.3))
                                    .frame(height: 2)
                                Spacer()
                            }
                            HStack(spacing: 0) {
                                Rectangle()
                                    .fill(Color.white.opacity(0.3))
                                    .frame(width: 2)
                                Spacer()
                            }
                        }
                        
                        Rectangle()
                            .stroke(Color.black, lineWidth: 2)
                    }
                )
        }
    }
}