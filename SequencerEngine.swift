import SwiftUI
import AVFoundation

struct Track {
    let name: String
    var isMuted: Bool = false
    var isSolo: Bool = false
}

struct Pattern {
    var tracks: [TrackPattern]
}

struct TrackPattern {
    var steps: [Bool] = Array(repeating: false, count: 16)
}

class SequencerEngine: ObservableObject {
    @Published var isPlaying = false
    @Published var currentStep = 0
    @Published var tempo: Double = 120
    @Published var swing: Double = 0
    @Published var currentPattern = 0
    
    @Published var tracks: [Track] = [
        Track(name: "Kick"),
        Track(name: "Snare"),
        Track(name: "Hi-Hat"),
        Track(name: "Open Hat"),
        Track(name: "Crash"),
        Track(name: "Bass")
    ]
    
    @Published var patterns: [Pattern] = []
    
    private var timer: Timer?
    private var audioPlayers: [String: AVAudioPlayer] = [:]
    private let audioEngine = AVAudioEngine()
    
    init() {
        setupAudio()
        setupPatterns()
        loadDefaultPattern()
    }
    
    private func setupAudio() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to setup audio session: \(error)")
        }
    }
    
    private func setupPatterns() {
        // Initialize 4 empty patterns
        for _ in 0..<4 {
            var pattern = Pattern(tracks: [])
            for _ in 0..<6 {
                pattern.tracks.append(TrackPattern())
            }
            patterns.append(pattern)
        }
    }
    
    private func loadDefaultPattern() {
        // Basic house pattern
        patterns[0].tracks[0].steps = [true, false, false, false, true, false, false, false, true, false, false, false, true, false, false, false] // Kick
        patterns[0].tracks[1].steps = [false, false, false, false, true, false, false, false, false, false, false, false, true, false, false, false] // Snare
        patterns[0].tracks[2].steps = [false, false, true, false, false, false, true, false, false, false, true, false, false, false, true, false] // Hi-hat
    }
    
    func play() {
        isPlaying = true
        scheduleTimer()
        playSystemSound() // Play a click to confirm it's working
    }
    
    func stop() {
        isPlaying = false
        timer?.invalidate()
        timer = nil
        currentStep = 0
    }
    
    private func scheduleTimer() {
        let interval = 60.0 / tempo / 4.0 // 16th notes
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { _ in
            self.tick()
        }
    }
    
    private func tick() {
        // Play sounds for current step
        for (trackIndex, track) in tracks.enumerated() {
            if patterns[currentPattern].tracks[trackIndex].steps[currentStep] {
                if !track.isMuted {
                    let hasSolo = tracks.contains { $0.isSolo }
                    if !hasSolo || track.isSolo {
                        playSound(for: trackIndex)
                    }
                }
            }
        }
        
        // Move to next step
        currentStep = (currentStep + 1) % 16
    }
    
    private func playSound(for trackIndex: Int) {
        // For now, play system sounds as placeholders
        let soundID: SystemSoundID
        switch trackIndex {
        case 0: soundID = 1104 // Kick-like
        case 1: soundID = 1105 // Snare-like
        case 2: soundID = 1106 // Hi-hat-like
        case 3: soundID = 1107 // Open hat-like
        case 4: soundID = 1108 // Crash-like
        case 5: soundID = 1109 // Bass-like
        default: soundID = 1104
        }
        AudioServicesPlaySystemSound(soundID)
    }
    
    private func playSystemSound() {
        AudioServicesPlaySystemSound(1104)
    }
    
    func toggleStep(track: Int, step: Int) {
        patterns[currentPattern].tracks[track].steps[step].toggle()
    }
    
    func toggleMute(track: Int) {
        tracks[track].isMuted.toggle()
    }
    
    func toggleSolo(track: Int) {
        tracks[track].isSolo.toggle()
    }
    
    func clear() {
        for trackIndex in 0..<patterns[currentPattern].tracks.count {
            patterns[currentPattern].tracks[trackIndex].steps = Array(repeating: false, count: 16)
        }
    }
    
    func randomFill() {
        for trackIndex in 0..<patterns[currentPattern].tracks.count {
            for step in 0..<16 {
                patterns[currentPattern].tracks[trackIndex].steps[step] = Double.random(in: 0...1) > 0.7
            }
        }
    }
    
    func switchPattern(to index: Int) {
        currentPattern = index
    }
}