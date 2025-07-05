import SwiftUI
import AVFoundation

@main
struct RositaApp: App {
    @StateObject private var audioEngine = AudioEngine()
    
    init() {
        configureAudioSession()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(audioEngine)
                .preferredColorScheme(.light)
                .statusBar(hidden: true)
        }
    }
    
    private func configureAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try session.setActive(true)
            try session.setPreferredIOBufferDuration(0.005) // 5ms for low latency
        } catch {
            print("Failed to configure audio session: \(error)")
        }
    }
}