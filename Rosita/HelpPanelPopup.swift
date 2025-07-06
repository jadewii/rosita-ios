import SwiftUI

struct HelpPanelPopup: View {
    @Binding var isShowing: Bool
    @State private var showHowToPlay = false
    @State private var scaleEffect: CGFloat = 0.8
    @State private var opacity: Double = 0
    
    var body: some View {
        ZStack {
            // Semi-transparent background
            if isShowing {
                Color.black.opacity(0.6)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.spring(response: 0.3)) {
                            isShowing = false
                        }
                    }
                    .transition(.opacity)
            }
            
            // Popup panel
            if isShowing {
                VStack(spacing: 0) {
                    // Header
                    HStack {
                        Text(showHowToPlay ? "HOW TO PLAY" : "ROSITA MENU")
                            .font(.system(size: 18, weight: .bold, design: .monospaced))
                            .foregroundColor(.black)
                        
                        Spacer()
                        
                        Button("✕") {
                            withAnimation(.spring(response: 0.3)) {
                                isShowing = false
                            }
                        }
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.black)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color(hex: "FFB6C1"))
                    
                    // Content
                    if showHowToPlay {
                        // How to Play content
                        ScrollView {
                            VStack(alignment: .leading, spacing: 12) {
                                Button(action: {
                                    withAnimation {
                                        showHowToPlay = false
                                    }
                                }) {
                                    HStack {
                                        Image(systemName: "chevron.left")
                                            .font(.system(size: 14, weight: .bold))
                                        Text("Back to Menu")
                                            .font(.system(size: 14, weight: .semibold))
                                    }
                                    .foregroundColor(Color(hex: "FF1493"))
                                    .padding(.bottom, 8)
                                }
                                
                                Group {
                                    helpSection(
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
                                    
                                    helpSection(
                                        title: "🎙️ RECORDING MODES",
                                        content: """
                                        • REC (red) - Real-time recording, plays notes as you press them
                                        • TR (dark red) - Step recording, each key press advances to next step
                                        """
                                    )
                                    
                                    helpSection(
                                        title: "🎹 INSTRUMENTS",
                                        content: """
                                        • Buttons 1,2,3,4 - Select instrument track
                                        • Tap again - Cycle waveforms: Square→Saw→Triangle→Sine→Reverse Saw
                                        • Colors: Pink=Square, Green=Saw, Blue=Triangle, Gold=Sine, Orange=Reverse Saw
                                        """
                                    )
                                    
                                    helpSection(
                                        title: "🎯 SEQUENCER GRID",
                                        content: """
                                        • Grid cells - Tap to activate/deactivate steps
                                        • 8 rows - Different notes/drums per row
                                        • 16 columns - 16 step sequence
                                        • White highlight - Shows current playing step
                                        """
                                    )
                                    
                                    helpSection(
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
                            .padding(16)
                        }
                        .background(Color.white)
                    } else {
                        // Main menu
                        VStack(spacing: 12) {
                            menuButton(
                                icon: "lock.open.fill",
                                title: "Unlock Rosita Pro",
                                color: Color(hex: "FFD700"),
                                action: {
                                    print("Unlock Pro tapped")
                                }
                            )
                            
                            menuButton(
                                icon: "cart.fill",
                                title: "Buy Expansions",
                                color: Color(hex: "00CED1"),
                                action: {
                                    print("Buy Expansions tapped")
                                }
                            )
                            
                            menuButton(
                                icon: "ticket.fill",
                                title: "Get the Jam Pass",
                                color: Color(hex: "9370DB"),
                                action: {
                                    print("Jam Pass tapped")
                                }
                            )
                            
                            menuButton(
                                icon: "questionmark.circle.fill",
                                title: "How to Play",
                                color: Color(hex: "32CD32"),
                                action: {
                                    withAnimation {
                                        showHowToPlay = true
                                    }
                                }
                            )
                        }
                        .padding(20)
                        .background(Color.white)
                    }
                }
                .frame(maxWidth: 600, maxHeight: showHowToPlay ? 500 : 400)
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.black, lineWidth: 2)
                )
                .scaleEffect(scaleEffect)
                .opacity(opacity)
                .onAppear {
                    withAnimation(.spring(response: 0.3)) {
                        scaleEffect = 1.0
                        opacity = 1.0
                    }
                }
                .onDisappear {
                    scaleEffect = 0.8
                    opacity = 0
                }
            }
        }
    }
    
    private func helpSection(title: String, content: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 14, weight: .bold, design: .monospaced))
                .foregroundColor(.black)
            
            Text(content)
                .font(.system(size: 11))
                .foregroundColor(.black)
                .lineSpacing(2)
        }
        .padding(.vertical, 4)
    }
    
    private func menuButton(icon: String, title: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(color)
                    .frame(width: 32)
                
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.black)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.gray)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(color.opacity(0.3), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}