import SwiftUI

// MARK: - Button Icon Shapes

struct PlayIconShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height

        // Play triangle pointing right
        path.move(to: CGPoint(x: width * 0.3, y: height * 0.2))
        path.addLine(to: CGPoint(x: width * 0.75, y: height * 0.5))
        path.addLine(to: CGPoint(x: width * 0.3, y: height * 0.8))
        path.closeSubpath()

        return path
    }
}

struct StopIconShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height
        let size = min(width, height) * 0.6
        let offsetX = (width - size) / 2
        let offsetY = (height - size) / 2

        // Stop square
        path.addRect(CGRect(x: offsetX, y: offsetY, width: size, height: size))

        return path
    }
}

struct PauseIconShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height
        let barWidth = width * 0.15
        let barHeight = height * 0.6
        let offsetY = (height - barHeight) / 2

        // Two vertical bars
        path.addRect(CGRect(x: width * 0.35 - barWidth/2, y: offsetY, width: barWidth, height: barHeight))
        path.addRect(CGRect(x: width * 0.65 - barWidth/2, y: offsetY, width: barWidth, height: barHeight))

        return path
    }
}

struct RandomIconShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height

        // Dice dots pattern - show 6 dots like a die
        let dotSize = width * 0.12
        let padding = width * 0.2

        // Top row
        path.addEllipse(in: CGRect(x: padding, y: padding, width: dotSize, height: dotSize))
        path.addEllipse(in: CGRect(x: width - padding - dotSize, y: padding, width: dotSize, height: dotSize))

        // Middle row
        path.addEllipse(in: CGRect(x: padding, y: height/2 - dotSize/2, width: dotSize, height: dotSize))
        path.addEllipse(in: CGRect(x: width - padding - dotSize, y: height/2 - dotSize/2, width: dotSize, height: dotSize))

        // Bottom row
        path.addEllipse(in: CGRect(x: padding, y: height - padding - dotSize, width: dotSize, height: dotSize))
        path.addEllipse(in: CGRect(x: width - padding - dotSize, y: height - padding - dotSize, width: dotSize, height: dotSize))

        return path
    }
}

struct ClearIconShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height
        let size = min(width, height) * 0.6
        let offsetX = (width - size) / 2
        let offsetY = (height - size) / 2

        // X pattern
        path.move(to: CGPoint(x: offsetX, y: offsetY))
        path.addLine(to: CGPoint(x: offsetX + size, y: offsetY + size))
        path.move(to: CGPoint(x: offsetX + size, y: offsetY))
        path.addLine(to: CGPoint(x: offsetX, y: offsetY + size))

        return path
    }
}

struct MixerIconShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height
        let sliderWidth = width * 0.12
        let spacing = width * 0.25
        let sliderHeight = height * 0.7
        let offsetY = height * 0.15

        // Three vertical faders at different positions
        // Fader 1 - high
        path.addRect(CGRect(x: spacing - sliderWidth/2, y: offsetY, width: sliderWidth, height: sliderHeight * 0.3))

        // Fader 2 - medium
        path.addRect(CGRect(x: width/2 - sliderWidth/2, y: offsetY + sliderHeight * 0.3, width: sliderWidth, height: sliderHeight * 0.4))

        // Fader 3 - low
        path.addRect(CGRect(x: width - spacing - sliderWidth/2, y: offsetY + sliderHeight * 0.5, width: sliderWidth, height: sliderHeight * 0.35))

        return path
    }
}

struct ScaleIconShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height
        let noteHeight = height * 0.12
        let spacing = height * 0.05
        let startY = height * 0.15

        // Draw 5 horizontal lines representing musical staff/scale
        for i in 0..<5 {
            let y = startY + CGFloat(i) * (noteHeight + spacing)
            path.addRect(CGRect(x: width * 0.2, y: y, width: width * 0.6, height: 3))
        }

        return path
    }
}

struct GridIconShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height
        let squareSize = min(width, height) * 0.25
        let spacing: CGFloat = squareSize * 0.3
        let offsetX = (width - (squareSize * 2 + spacing)) / 2
        let offsetY = (height - (squareSize * 2 + spacing)) / 2

        // Draw 4 squares in a 2x2 grid
        // Top left
        path.addRect(CGRect(x: offsetX, y: offsetY, width: squareSize, height: squareSize))
        // Top right
        path.addRect(CGRect(x: offsetX + squareSize + spacing, y: offsetY, width: squareSize, height: squareSize))
        // Bottom left
        path.addRect(CGRect(x: offsetX, y: offsetY + squareSize + spacing, width: squareSize, height: squareSize))
        // Bottom right
        path.addRect(CGRect(x: offsetX + squareSize + spacing, y: offsetY + squareSize + spacing, width: squareSize, height: squareSize))

        return path
    }
}

// MARK: - Waveform Shapes

struct SquareWaveShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height
        let midY = height / 2
        let amplitude = height * 0.35
        let cycles = 2.5

        path.move(to: CGPoint(x: 0, y: midY + amplitude))

        let segmentWidth = width / cycles

        for i in 0..<Int(cycles) {
            let x = CGFloat(i) * segmentWidth

            // Vertical line up
            path.addLine(to: CGPoint(x: x, y: midY - amplitude))
            // Horizontal line right (top)
            path.addLine(to: CGPoint(x: x + segmentWidth/2, y: midY - amplitude))
            // Vertical line down
            path.addLine(to: CGPoint(x: x + segmentWidth/2, y: midY + amplitude))
            // Horizontal line right (bottom)
            path.addLine(to: CGPoint(x: x + segmentWidth, y: midY + amplitude))
        }

        return path
    }
}

struct SawtoothWaveShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height
        let midY = height / 2
        let amplitude = height * 0.35
        let cycles = 2.5

        path.move(to: CGPoint(x: 0, y: midY + amplitude))

        let segmentWidth = width / cycles

        for i in 0..<Int(cycles) {
            let startX = CGFloat(i) * segmentWidth
            let endX = CGFloat(i + 1) * segmentWidth

            // Rising diagonal line
            path.addLine(to: CGPoint(x: endX, y: midY - amplitude))
            // Sharp drop down
            path.addLine(to: CGPoint(x: endX, y: midY + amplitude))
        }

        return path
    }
}

struct TriangleWaveShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height
        let midY = height / 2
        let amplitude = height * 0.35
        let cycles = 2.5

        // Start from bottom
        path.move(to: CGPoint(x: 0, y: midY + amplitude))

        let segmentWidth = width / cycles

        for i in 0..<Int(cycles) {
            let x = CGFloat(i) * segmentWidth

            // Rise to peak
            path.addLine(to: CGPoint(x: x + segmentWidth/2, y: midY - amplitude))
            // Fall to trough
            path.addLine(to: CGPoint(x: x + segmentWidth, y: midY + amplitude))
        }

        return path
    }
}

struct SineWaveShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height
        let midY = height / 2
        let amplitude = height * 0.35
        let cycles = 2.5

        let points = 100

        path.move(to: CGPoint(x: 0, y: midY))

        for i in 1...points {
            let x = CGFloat(i) / CGFloat(points) * width
            let angle = (CGFloat(i) / CGFloat(points)) * cycles * 2 * .pi
            let y = midY - sin(angle) * amplitude
            path.addLine(to: CGPoint(x: x, y: y))
        }

        return path
    }
}

struct ReverseSawWaveShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height
        let midY = height / 2
        let amplitude = height * 0.35
        let cycles = 2.5

        path.move(to: CGPoint(x: 0, y: midY - amplitude))

        let segmentWidth = width / cycles

        for i in 0..<Int(cycles) {
            let startX = CGFloat(i) * segmentWidth
            let endX = CGFloat(i + 1) * segmentWidth

            // Falling diagonal line
            path.addLine(to: CGPoint(x: endX, y: midY + amplitude))
            // Sharp rise up
            path.addLine(to: CGPoint(x: endX, y: midY - amplitude))
        }

        return path
    }
}

// MARK: - Retro Buttons

// Retro button with icon support
struct RetroIconButton<Icon: Shape>: View {
    let icon: Icon
    let color: Color
    let iconColor: Color
    let action: () -> Void
    var width: CGFloat? = nil
    var height: CGFloat = 24
    var useStroke: Bool = false

    var body: some View {
        Button(action: {
            action()
        }) {
            Group {
                if useStroke {
                    icon
                        .stroke(iconColor, lineWidth: 2)
                } else {
                    icon
                        .fill(iconColor)
                }
            }
            .frame(width: width, height: height)
                .drawingGroup()  // Force instant redraw
                .background(
                    ZStack {
                        // Main button color
                        Rectangle()
                            .fill(color)

                        // 3D bevel effect for retro look
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
                )
                .overlay(
                    Rectangle()
                        .stroke(Color.black, lineWidth: 2)
                )
        }
        .buttonStyle(PlainButtonStyle())
        .animation(nil, value: color)  // Disable animation for instant updates
        .animation(nil, value: iconColor)
        .transaction { t in t.animation = nil }  // Force-disable inherited animations
    }
}

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
            action()
        }) {
            Text(title)
                .font(.system(size: fontSize, weight: .bold, design: .monospaced))
                .foregroundColor(isDown ? .white : textColor)
                .frame(width: width, height: height)
                .drawingGroup()  // Force instant redraw
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
        .animation(nil, value: color)  // Disable animation for instant updates
        .animation(nil, value: textColor)
        .animation(nil, value: isDown)
        .transaction { t in t.animation = nil }  // Force-disable inherited animations
    }
}

// Pattern slot button with retro style
struct RetroPatternButton: View {
    let number: Int
    let isSelected: Bool
    var isDupTarget: Bool = false
    let action: () -> Void

    var body: some View {
        Text("\(number)")
            .font(.system(size: 16, weight: .bold, design: .monospaced))
            .foregroundColor(isSelected ? .black : (isDupTarget ? .yellow : .black))
            .frame(width: 56, height: 56)
            .background(
                Rectangle()
                    .fill(isSelected ? Color.yellow : (isDupTarget ? Color.black : Color.white))
                    .overlay(
                        Rectangle()
                            .stroke(isDupTarget ? Color.yellow : Color.black, lineWidth: isSelected ? 3 : 2)
                    )
            )
            .contentShape(Rectangle())
            .onTapGesture {
                action()
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
        .animation(nil, value: isOn)  // Disable animation for instant updates
        .transaction { t in t.animation = nil }  // Force-disable inherited animations
    }
}