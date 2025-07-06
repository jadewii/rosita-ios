import SwiftUI

struct HelpPanel: View {
    @Binding var isShowing: Bool
    @State private var showHowToPlay = false
    @State private var panelOffset: CGFloat = -UIScreen.main.bounds.width
    
    var body: some View {
        ZStack {
            // Semi-transparent backdrop
            if isShowing {
                Color.black.opacity(0.5)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.spring()) {
                            isShowing = false
                        }
                    }
                    .transition(.opacity)
            }
            
            // Side panel
            HStack {
                // Panel content
                VStack(spacing: 0) {
                    // Header
                    HStack {
                        Text("ROSITA MENU")
                            .font(.system(size: 20, weight: .bold, design: .monospaced))
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Button(action: {
                            withAnimation(.spring()) {
                                isShowing = false
                            }
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 28))
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 20)
                    .background(Color(hex: "FF1493").opacity(0.8))
                    
                    // Menu buttons or How to Play content
                    if showHowToPlay {
                        // How to Play content
                        ScrollView {
                            VStack(alignment: .leading, spacing: 16) {
                                Button(action: {
                                    withAnimation {
                                        showHowToPlay = false
                                    }
                                }) {
                                    HStack {
                                        Image(systemName: "chevron.left")
                                            .font(.system(size: 16, weight: .bold))
                                        Text("Back to Menu")
                                            .font(.system(size: 16, weight: .semibold))
                                    }
                                    .foregroundColor(.white)
                                    .padding(.bottom, 8)
                                }
                                
                                // Help content
                                helpContentView
                            }
                            .padding(24)
                        }
                    } else {
                        // Main menu buttons
                        VStack(spacing: 16) {
                            MenuButton(
                                icon: "lock.open.fill",
                                title: "Unlock Rosita Pro",
                                subtitle: "Get all features & updates",
                                color: Color(hex: "FFD700"),
                                action: {
                                    // TODO: Implement pro unlock
                                    print("Unlock Pro tapped")
                                }
                            )
                            
                            MenuButton(
                                icon: "cart.fill",
                                title: "Buy Expansions",
                                subtitle: "New sounds & presets",
                                color: Color(hex: "00CED1"),
                                action: {
                                    // TODO: Implement expansions
                                    print("Buy Expansions tapped")
                                }
                            )
                            
                            MenuButton(
                                icon: "ticket.fill",
                                title: "Get the Jam Pass",
                                subtitle: "All Wiistruments apps",
                                color: Color(hex: "9370DB"),
                                action: {
                                    // TODO: Implement jam pass
                                    print("Jam Pass tapped")
                                }
                            )
                            
                            MenuButton(
                                icon: "questionmark.circle.fill",
                                title: "How to Play",
                                subtitle: "Learn the basics",
                                color: Color(hex: "32CD32"),
                                action: {
                                    withAnimation {
                                        showHowToPlay = true
                                    }
                                }
                            )
                            
                            Spacer()
                        }
                        .padding(24)
                    }
                }
                .frame(width: min(400, UIScreen.main.bounds.width * 0.85))
                .frame(maxHeight: .infinity)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(hex: "FFB6C1"),
                            Color(hex: "FF69B4")
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .cornerRadius(0)
                .shadow(radius: 20)
                .offset(x: isShowing ? 0 : -UIScreen.main.bounds.width)
                .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isShowing)
                
                Spacer()
            }
        }
    }
    
    var helpContentView: some View {
        VStack(alignment: .leading, spacing: 20) {
            Group {
                HelpSection(
                    title: "🎵 BASIC CONTROLS",
                    content: """
                    • PLAY/STOP - Start and stop the sequencer
                    • REC - Record in real-time (looper mode)
                    • TR - Step recording mode (shows instead of REC)
                    • Long press REC/TR to switch modes
                    • CLEAR - Clear current instrument pattern
                    • CLR ALL - Clear all instrument patterns
                    • RANDOM - Generate random pattern
                    """
                )
                
                HelpSection(
                    title: "🎙️ RECORDING MODES",
                    content: """
                    • REC (red) - Real-time recording, plays notes as you press them
                    • TR (dark red) - Step recording, each key press advances to next step
                    """
                )
                
                HelpSection(
                    title: "🎹 INSTRUMENTS",
                    content: """
                    • Buttons 1,2,3,4 - Select instrument track
                    • Tap again - Cycle waveforms: Square→Saw→Triangle→Sine→Reverse Saw
                    • Colors: Pink=Square, Green=Saw, Blue=Triangle, Gold=Sine, Orange=Reverse Saw
                    """
                )
                
                HelpSection(
                    title: "🎯 SEQUENCER GRID",
                    content: """
                    • Grid cells - Tap to activate/deactivate steps
                    • 8 rows - Different notes/drums per row
                    • 16 columns - 16 step sequence
                    • White highlight - Shows current playing step
                    """
                )
                
                HelpSection(
                    title: "🎼 PIANO & EFFECTS",
                    content: """
                    • Piano keys - Play notes for selected instrument
                    • ADSR - Attack, Decay, Sustain, Release envelope
                    • Effects - Delay, Reverb, Distortion, Chorus
                    • WAV - Export your composition as audio file
                    """
                )
            }
        }
    }
}

struct MenuButton: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Icon background
                ZStack {
                    Circle()
                        .fill(color)
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: icon)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                }
                
                // Text content
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text(subtitle)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                }
                
                Spacer()
                
                // Arrow
                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white.opacity(0.6))
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.2))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                    )
            )
            .scaleEffect(isPressed ? 0.95 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = pressing
            }
        }, perform: {})
    }
}

struct HelpSection: View {
    let title: String
    let content: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 16, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
            
            Text(content)
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.9))
                .lineSpacing(4)
        }
        .padding(.vertical, 4)
    }
}