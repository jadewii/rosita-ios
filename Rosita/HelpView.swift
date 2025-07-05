import SwiftUI

struct HelpView: View {
    @Binding var isPresented: Bool
    
    var body: some View {
        ZStack {
            // Semi-transparent background
            Color.black.opacity(0.6)
                .ignoresSafeArea()
                .onTapGesture {
                    isPresented = false
                }
            
            // Help modal
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("ROSITA HELP")
                        .font(.system(size: 18, weight: .bold, design: .monospaced))
                        .foregroundColor(.black)
                    
                    Spacer()
                    
                    Button("✕") {
                        isPresented = false
                    }
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.black)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color(hex: "FFB6C1"))
                
                // Help content
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        
                        HelpSection(title: "🎵 BASIC CONTROLS") {
                            HelpItem(label: "PLAY/STOP", description: "Start and stop the sequencer")
                            HelpItem(label: "BPM", description: "Tempo control (tap +/- to change)")
                            HelpItem(label: "CLEAR", description: "Clear current instrument pattern")
                            HelpItem(label: "CLR ALL", description: "Clear all instrument patterns")
                            HelpItem(label: "RANDOM", description: "Generate random pattern for selected instrument")
                        }
                        
                        HelpSection(title: "🎹 INSTRUMENTS") {
                            HelpItem(label: "1, 2, 3, 4", description: "Select instrument track (Synth, Bass, Keys, Drums)")
                            HelpItem(label: "Tap again", description: "Cycle through waveforms: Square → Saw → Triangle → Sine → Reverse Saw")
                            HelpItem(label: "Colors", description: "Pink=Square, Green=Saw, Blue=Triangle, Gold=Sine, Orange=Reverse Saw")
                        }
                        
                        HelpSection(title: "🎯 SEQUENCER GRID") {
                            HelpItem(label: "Grid cells", description: "Tap to activate/deactivate steps")
                            HelpItem(label: "8 rows", description: "Different notes/drums per row")
                            HelpItem(label: "16 columns", description: "16 step sequence")
                            HelpItem(label: "Playing indicator", description: "White highlight shows current step")
                        }
                        
                        HelpSection(title: "🎼 PIANO KEYBOARD") {
                            HelpItem(label: "White keys", description: "Play notes for selected instrument")
                            HelpItem(label: "Black keys", description: "Sharps/flats for melodic instruments")
                            HelpItem(label: "Real-time", description: "Play while sequencer is running")
                        }
                        
                        HelpSection(title: "🔄 ARPEGGIATOR") {
                            HelpItem(label: "ARP 1,2,3", description: "Different arpeggiator patterns")
                            HelpItem(label: "Hold keys", description: "Arpeggiator plays held notes automatically")
                        }
                        
                        HelpSection(title: "📊 PATTERNS") {
                            HelpItem(label: "1-8 slots", description: "Save different pattern arrangements")
                            HelpItem(label: "DUP", description: "Duplicate current pattern to next slot")
                        }
                        
                        HelpSection(title: "🎛️ EFFECTS & ENVELOPE") {
                            HelpItem(label: "ADSR", description: "Attack, Decay, Sustain, Release envelope")
                            HelpItem(label: "Effects", description: "Delay, Reverb, Distortion, Chorus")
                            HelpItem(label: "Sliders", description: "Adjust effect amounts and ADSR values")
                        }
                        
                        HelpSection(title: "💾 EXPORT") {
                            HelpItem(label: "WAV button", description: "Export your composition as WAV file")
                            HelpItem(label: "Full mix", description: "Records all active instruments and effects")
                        }
                        
                    }
                    .padding(16)
                }
                .background(Color.white)
            }
            .frame(maxWidth: 600, maxHeight: 500)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.black, lineWidth: 2)
            )
        }
    }
}

struct HelpSection<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 14, weight: .bold, design: .monospaced))
                .foregroundColor(.black)
                .padding(.bottom, 4)
            
            content
        }
    }
}

struct HelpItem: View {
    let label: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text("•")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.gray)
            
            Text(label)
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundColor(.black)
                .frame(width: 80, alignment: .leading)
            
            Text(description)
                .font(.system(size: 12))
                .foregroundColor(.black)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}