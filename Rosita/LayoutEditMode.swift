import SwiftUI

// MARK: - Layout Configuration
struct LayoutConfig: Codable {
    var sidebarWidth: CGFloat = 190
    var sidebarOffset: CGFloat = -95
    var topControlsHeight: CGFloat = 100
    var topPadding: CGFloat = 12
    var keyboardHeight: CGFloat = 180
    var horizontalSpacing: CGFloat = 31
    var trailingPadding: CGFloat = 12

    static let `default` = LayoutConfig()

    func save() {
        if let data = try? JSONEncoder().encode(self) {
            UserDefaults.standard.set(data, forKey: "rosita_layout_config")
        }
    }

    static func load() -> LayoutConfig {
        if let data = UserDefaults.standard.data(forKey: "rosita_layout_config"),
           let config = try? JSONDecoder().decode(LayoutConfig.self, from: data) {
            return config
        }
        return .default
    }
}

// MARK: - Layout Edit Panel
struct LayoutEditPanel: View {
    @Binding var config: LayoutConfig
    @Binding var isShowing: Bool

    var body: some View {
        ZStack {
            // Semi-transparent background
            Color.black.opacity(0.7)
                .ignoresSafeArea()
                .onTapGesture {
                    isShowing = false
                }

            // Control panel
            VStack(spacing: 16) {
                Text("LAYOUT EDITOR")
                    .font(.system(size: 20, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)

                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        SliderControl(label: "Sidebar Width", value: $config.sidebarWidth, range: 100...300)
                        SliderControl(label: "Sidebar Offset Y", value: $config.sidebarOffset, range: -150...0)
                        SliderControl(label: "Top Height", value: $config.topControlsHeight, range: 80...150)
                        SliderControl(label: "Top Padding", value: $config.topPadding, range: 0...40)
                        SliderControl(label: "Keyboard Height", value: $config.keyboardHeight, range: 120...250)
                        SliderControl(label: "H-Spacing", value: $config.horizontalSpacing, range: 0...60)
                        SliderControl(label: "Trailing Pad", value: $config.trailingPadding, range: 0...40)
                    }
                    .padding()
                }

                HStack(spacing: 12) {
                    Button("RESET") {
                        config = .default
                        config.save()
                    }
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .foregroundColor(.black)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.yellow)
                    .cornerRadius(8)

                    Button("SAVE") {
                        config.save()
                        isShowing = false
                    }
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .foregroundColor(.black)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.green)
                    .cornerRadius(8)

                    Button("CANCEL") {
                        // Reload from saved
                        config = LayoutConfig.load()
                        isShowing = false
                    }
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.red)
                    .cornerRadius(8)
                }
                .padding()
            }
            .frame(width: 400, height: 600)
            .background(Color(hex: "FFB6C1"))
            .overlay(
                Rectangle()
                    .stroke(Color.black, lineWidth: 4)
            )
        }
    }
}

struct SliderControl: View {
    let label: String
    @Binding var value: CGFloat
    let range: ClosedRange<CGFloat>

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label)
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundColor(.black)
                Spacer()
                Text(String(format: "%.0f", value))
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundColor(.black)
                    .frame(width: 50)
                    .padding(4)
                    .background(Color.white)
                    .overlay(
                        Rectangle().stroke(Color.black, lineWidth: 1)
                    )
            }

            Slider(value: $value, in: range, step: 1)
                .accentColor(Color(hex: "FF1493"))
        }
        .padding(8)
        .background(Color.white.opacity(0.8))
        .overlay(
            Rectangle().stroke(Color.black, lineWidth: 2)
        )
    }
}
