import CoreAudioKit
import SwiftUI

#if os(iOS)
import UIKit
typealias PlatformViewController = UIViewController
typealias PlatformHostingController = UIHostingController
#elseif os(macOS)
import AppKit
typealias PlatformViewController = NSViewController
typealias PlatformHostingController = NSHostingController
#endif

public class RositaAudioUnitViewController: AUViewController {
    var audioUnit: RositaAudioUnit?
    
    // SwiftUI hosting controller
    private var hostingController: PlatformHostingController<AUv3ContentView>?
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        // Create SwiftUI view with audio unit reference
        let contentView = AUv3ContentView(audioUnit: audioUnit)
        let hosting = PlatformHostingController(rootView: contentView)
        
        // Add as child view controller
        #if os(iOS)
        addChild(hosting)
        view.addSubview(hosting.view)
        hosting.view.frame = view.bounds
        hosting.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        hosting.didMove(toParent: self)
        #elseif os(macOS)
        addChild(hosting)
        view.addSubview(hosting.view)
        hosting.view.frame = view.bounds
        hosting.view.autoresizingMask = [.width, .height]
        #endif
        
        self.hostingController = hosting
        
        // Set preferred content size for the plugin window
        self.preferredContentSize = CGSize(width: 800, height: 600)
    }
}

// Simplified AUv3 UI using SwiftUI
struct AUv3ContentView: View {
    let audioUnit: RositaAudioUnit?
    @State private var isPlaying = false
    @State private var grid: [[Bool]] = Array(repeating: Array(repeating: false, count: 16), count: 8)
    @State private var currentStep = -1
    
    let trackNames = ["Kick", "Snare", "HiHat", "Perc1", "Perc2", "Perc3", "Perc4", "Perc5"]
    let trackColors: [Color] = [.red, .blue, .green, .purple, .orange, .pink, .yellow, .cyan]
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [Color(red: 1.0, green: 0.6, blue: 0.8), Color(red: 0.8, green: 0.4, blue: 0.6)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 20) {
                // Title
                Text("ROSITA DRUM MACHINE")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .shadow(radius: 3)
                
                // Transport controls
                HStack(spacing: 20) {
                    Button(action: togglePlayback) {
                        Text(isPlaying ? "STOP" : "PLAY")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(width: 80, height: 40)
                            .background(isPlaying ? Color.red : Color.green)
                            .cornerRadius(8)
                    }
                    
                    Button(action: clearGrid) {
                        Text("CLEAR")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(width: 80, height: 40)
                            .background(Color.gray)
                            .cornerRadius(8)
                    }
                }
                
                // Grid
                VStack(spacing: 4) {
                    // Step numbers
                    HStack(spacing: 4) {
                        Text("").frame(width: 60)
                        ForEach(0..<16) { step in
                            Text("\(step + 1)")
                                .font(.caption)
                                .foregroundColor(.white)
                                .frame(width: 30, height: 20)
                        }
                    }
                    
                    // Track rows
                    ForEach(0..<8) { track in
                        HStack(spacing: 4) {
                            Text(trackNames[track])
                                .font(.caption)
                                .foregroundColor(.white)
                                .frame(width: 60, alignment: .trailing)
                            
                            ForEach(0..<16) { step in
                                Button(action: {
                                    toggleStep(track: track, step: step)
                                }) {
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(grid[track][step] ? trackColors[track] : Color.white.opacity(0.3))
                                        .frame(width: 30, height: 30)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 4)
                                                .stroke(currentStep == step ? Color.white : Color.clear, lineWidth: 2)
                                        )
                                }
                            }
                        }
                    }
                }
                .padding()
                .background(Color.black.opacity(0.3))
                .cornerRadius(10)
                
                // Info
                Text("Professional Drum Sequencer by Wiistrument")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
                
                Spacer()
            }
            .padding()
        }
        .onAppear {
            loadInitialPattern()
        }
    }
    
    private func togglePlayback() {
        isPlaying.toggle()
        if isPlaying {
            audioUnit?.startPlayback()
            // Start UI update timer
        } else {
            audioUnit?.stopPlayback()
            currentStep = -1
        }
    }
    
    private func clearGrid() {
        for track in 0..<8 {
            for step in 0..<16 {
                grid[track][step] = false
                audioUnit?.setStep(track: track, step: step, active: false)
            }
        }
    }
    
    private func toggleStep(track: Int, step: Int) {
        grid[track][step].toggle()
        audioUnit?.setStep(track: track, step: step, active: grid[track][step])
    }
    
    private func loadInitialPattern() {
        // Load a default pattern
        grid[0][0] = true
        grid[0][4] = true
        grid[0][8] = true
        grid[0][12] = true
        grid[1][4] = true
        grid[1][12] = true
        
        // Sync with audio unit
        for track in 0..<8 {
            for step in 0..<16 {
                audioUnit?.setStep(track: track, step: step, active: grid[track][step])
            }
        }
    }
}