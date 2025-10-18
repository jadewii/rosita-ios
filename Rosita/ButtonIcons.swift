import SwiftUI

// MARK: - Transport Button Icons

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
        let spacing = width * 0.15
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

        // Dice dots pattern - show 3 dots like a die (diagonal pattern)
        let dotSize = width * 0.18  // Larger dots to match REC button dice
        let padding = width * 0.22

        // Top-left dot
        path.addEllipse(in: CGRect(x: padding, y: padding, width: dotSize, height: dotSize))

        // Center dot
        path.addEllipse(in: CGRect(x: width/2 - dotSize/2, y: height/2 - dotSize/2, width: dotSize, height: dotSize))

        // Bottom-right dot
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

struct ArrowUpShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height

        // Up arrow
        path.move(to: CGPoint(x: width * 0.5, y: height * 0.25))
        path.addLine(to: CGPoint(x: width * 0.75, y: height * 0.5))
        path.addLine(to: CGPoint(x: width * 0.6, y: height * 0.5))
        path.addLine(to: CGPoint(x: width * 0.6, y: height * 0.75))
        path.addLine(to: CGPoint(x: width * 0.4, y: height * 0.75))
        path.addLine(to: CGPoint(x: width * 0.4, y: height * 0.5))
        path.addLine(to: CGPoint(x: width * 0.25, y: height * 0.5))
        path.closeSubpath()

        return path
    }
}

struct ArrowDownShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height

        // Down arrow
        path.move(to: CGPoint(x: width * 0.5, y: height * 0.75))
        path.addLine(to: CGPoint(x: width * 0.75, y: height * 0.5))
        path.addLine(to: CGPoint(x: width * 0.6, y: height * 0.5))
        path.addLine(to: CGPoint(x: width * 0.6, y: height * 0.25))
        path.addLine(to: CGPoint(x: width * 0.4, y: height * 0.25))
        path.addLine(to: CGPoint(x: width * 0.4, y: height * 0.5))
        path.addLine(to: CGPoint(x: width * 0.25, y: height * 0.5))
        path.closeSubpath()

        return path
    }
}

struct ArrowRightShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height

        // Right arrow (for Forward)
        path.move(to: CGPoint(x: width * 0.75, y: height * 0.5))
        path.addLine(to: CGPoint(x: width * 0.5, y: height * 0.75))
        path.addLine(to: CGPoint(x: width * 0.5, y: height * 0.6))
        path.addLine(to: CGPoint(x: width * 0.25, y: height * 0.6))
        path.addLine(to: CGPoint(x: width * 0.25, y: height * 0.4))
        path.addLine(to: CGPoint(x: width * 0.5, y: height * 0.4))
        path.addLine(to: CGPoint(x: width * 0.5, y: height * 0.25))
        path.closeSubpath()

        return path
    }
}

struct ArrowLeftShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height

        // Left arrow (for Backward)
        path.move(to: CGPoint(x: width * 0.25, y: height * 0.5))
        path.addLine(to: CGPoint(x: width * 0.5, y: height * 0.75))
        path.addLine(to: CGPoint(x: width * 0.5, y: height * 0.6))
        path.addLine(to: CGPoint(x: width * 0.75, y: height * 0.6))
        path.addLine(to: CGPoint(x: width * 0.75, y: height * 0.4))
        path.addLine(to: CGPoint(x: width * 0.5, y: height * 0.4))
        path.addLine(to: CGPoint(x: width * 0.5, y: height * 0.25))
        path.closeSubpath()

        return path
    }
}

struct ArrowPendulumShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height

        // Stacked arrows: forward (right) on top, reverse (left) on bottom
        // Using smaller versions of ArrowRightShape and ArrowLeftShape

        // Forward arrow (top half) - scaled down version of ArrowRightShape
        let topRect = CGRect(x: width * 0.15, y: height * 0.1, width: width * 0.7, height: height * 0.35)
        // Right arrow pointing forward
        path.move(to: CGPoint(x: topRect.maxX, y: topRect.midY))
        path.addLine(to: CGPoint(x: topRect.midX, y: topRect.maxY))
        path.addLine(to: CGPoint(x: topRect.midX, y: topRect.midY + topRect.height * 0.1))
        path.addLine(to: CGPoint(x: topRect.minX, y: topRect.midY + topRect.height * 0.1))
        path.addLine(to: CGPoint(x: topRect.minX, y: topRect.midY - topRect.height * 0.1))
        path.addLine(to: CGPoint(x: topRect.midX, y: topRect.midY - topRect.height * 0.1))
        path.addLine(to: CGPoint(x: topRect.midX, y: topRect.minY))
        path.closeSubpath()

        // Reverse arrow (bottom half) - scaled down version of ArrowLeftShape
        let bottomRect = CGRect(x: width * 0.15, y: height * 0.55, width: width * 0.7, height: height * 0.35)
        // Left arrow pointing backward
        path.move(to: CGPoint(x: bottomRect.minX, y: bottomRect.midY))
        path.addLine(to: CGPoint(x: bottomRect.midX, y: bottomRect.maxY))
        path.addLine(to: CGPoint(x: bottomRect.midX, y: bottomRect.midY + bottomRect.height * 0.1))
        path.addLine(to: CGPoint(x: bottomRect.maxX, y: bottomRect.midY + bottomRect.height * 0.1))
        path.addLine(to: CGPoint(x: bottomRect.maxX, y: bottomRect.midY - bottomRect.height * 0.1))
        path.addLine(to: CGPoint(x: bottomRect.midX, y: bottomRect.midY - bottomRect.height * 0.1))
        path.addLine(to: CGPoint(x: bottomRect.midX, y: bottomRect.minY))
        path.closeSubpath()

        return path
    }
}
