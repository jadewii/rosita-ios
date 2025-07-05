import Foundation
import AVFoundation
import Accelerate

struct DrumTrack {
    var steps: [Bool] = Array(repeating: false, count: 16)
    var isMuted: Bool = false
    var isSolo: Bool = false
}

struct DrumPattern {
    var tracks: [DrumTrack] = Array(repeating: DrumTrack(), count: 6)
}

struct SynthParameters {
    var frequency: Double = 60.0
    var decay: Double = 0.3
    var tone: Double = 0.5
    var attack: Double = 0.001
    var sustain: Double = 0.1
    var release: Double = 0.2
    var noiseAmount: Double = 0.0
    var pitchDecay: Double = 0.1
}

class DrumMachine: ObservableObject {
    @Published var isPlaying = false
    @Published var currentStep = 0
    @Published var bpm: Double = 120
    @Published var currentPattern = 0
    
    @Published var tracks: [DrumTrack] = Array(repeating: DrumTrack(), count: 6)
    @Published var patterns: [DrumPattern] = []
    @Published var synthParams: [SynthParameters] = []
    
    private var audioEngine = AVAudioEngine()
    private var playerNodes: [AVAudioPlayerNode] = []
    private var timer: Timer?
    private var audioFormat: AVAudioFormat!
    
    init() {
        setupAudio()
        initializePatterns()
        initializeSynthParams()
        loadDefaultPattern()
    }
    
    private func setupAudio() {
        // Configure audio session
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to setup audio session: \(error)")
        }
        
        // Setup audio engine
        audioFormat = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 2)
        
        // Create player nodes for each drum track
        for _ in 0..<6 {
            let playerNode = AVAudioPlayerNode()
            audioEngine.attach(playerNode)
            audioEngine.connect(playerNode, to: audioEngine.mainMixerNode, format: audioFormat)
            playerNodes.append(playerNode)
        }
        
        // Start the engine
        do {
            try audioEngine.start()
        } catch {
            print("Failed to start audio engine: \(error)")
        }
    }
    
    private func initializePatterns() {
        // Initialize 4 empty patterns
        for _ in 0..<4 {
            patterns.append(DrumPattern())
        }
        tracks = patterns[0].tracks
    }
    
    private func initializeSynthParams() {
        // Default parameters for each drum type
        synthParams = [
            // Kick
            SynthParameters(frequency: 60, decay: 0.4, tone: 0.2, attack: 0.001, sustain: 0.1, release: 0.3, noiseAmount: 0.1, pitchDecay: 0.1),
            // Snare
            SynthParameters(frequency: 200, decay: 0.1, tone: 0.7, attack: 0.001, sustain: 0.0, release: 0.15, noiseAmount: 0.8, pitchDecay: 0.05),
            // Hi-Hat
            SynthParameters(frequency: 8000, decay: 0.05, tone: 0.9, attack: 0.001, sustain: 0.0, release: 0.08, noiseAmount: 0.9, pitchDecay: 0.02),
            // Open Hat
            SynthParameters(frequency: 6000, decay: 0.3, tone: 0.8, attack: 0.001, sustain: 0.1, release: 0.4, noiseAmount: 0.85, pitchDecay: 0.05),
            // Crash
            SynthParameters(frequency: 4000, decay: 1.0, tone: 0.6, attack: 0.001, sustain: 0.2, release: 1.5, noiseAmount: 0.7, pitchDecay: 0.1),
            // Bass
            SynthParameters(frequency: 80, decay: 0.2, tone: 0.3, attack: 0.001, sustain: 0.2, release: 0.15, noiseAmount: 0.0, pitchDecay: 0.08)
        ]
    }
    
    private func loadDefaultPattern() {
        // Load a basic house pattern
        patterns[0].tracks[0].steps = [true, false, false, false, true, false, false, false, true, false, false, false, true, false, false, false] // Kick
        patterns[0].tracks[1].steps = [false, false, false, false, true, false, false, false, false, false, false, false, true, false, false, false] // Snare
        patterns[0].tracks[2].steps = [false, false, true, false, false, false, true, false, false, false, true, false, false, false, true, false] // Hi-hat
        
        tracks = patterns[0].tracks
    }
    
    func togglePlayback() {
        if isPlaying {
            stop()
        } else {
            play()
        }
    }
    
    func play() {
        isPlaying = true
        scheduleTimer()
    }
    
    func stop() {
        isPlaying = false
        timer?.invalidate()
        timer = nil
        currentStep = 0
    }
    
    private func scheduleTimer() {
        let stepInterval = 60.0 / bpm / 4.0 // 16th notes
        timer = Timer.scheduledTimer(withTimeInterval: stepInterval, repeats: true) { _ in
            self.tick()
        }
    }
    
    private func tick() {
        // Play sounds for current step
        for (trackIndex, track) in tracks.enumerated() {
            if track.steps[currentStep] && !track.isMuted {
                let hasSolo = tracks.contains { $0.isSolo }
                if !hasSolo || track.isSolo {
                    playDrumSound(track: trackIndex)
                }
            }
        }
        
        // Advance to next step
        currentStep = (currentStep + 1) % 16
    }
    
    private func playDrumSound(track: Int) {
        let buffer = generateDrumBuffer(for: track)
        
        if playerNodes[track].isPlaying {
            playerNodes[track].stop()
        }
        
        playerNodes[track].scheduleBuffer(buffer, at: nil, options: [], completionHandler: nil)
        playerNodes[track].play()
    }
    
    private func generateDrumBuffer(for track: Int) -> AVAudioPCMBuffer {
        let params = synthParams[track]
        let sampleRate = audioFormat.sampleRate
        let duration = params.attack + params.decay + params.release
        let frameCount = AVAudioFrameCount(duration * sampleRate)
        
        let buffer = AVAudioPCMBuffer(pcmFormat: audioFormat, frameCapacity: frameCount)!
        buffer.frameLength = frameCount
        
        let leftChannel = buffer.floatChannelData![0]
        let rightChannel = buffer.floatChannelData![1]
        
        for i in 0..<Int(frameCount) {
            let time = Double(i) / sampleRate
            let sample = generateDrumSample(track: track, time: time, params: params)
            
            leftChannel[i] = Float(sample)
            rightChannel[i] = Float(sample)
        }
        
        return buffer
    }
    
    private func generateDrumSample(track: Int, time: Double, params: SynthParameters) -> Double {
        let envelope = calculateEnvelope(time: time, params: params)
        
        switch track {
        case 0: // Kick
            return generateKick(time: time, params: params, envelope: envelope)
        case 1: // Snare
            return generateSnare(time: time, params: params, envelope: envelope)
        case 2: // Hi-Hat
            return generateHiHat(time: time, params: params, envelope: envelope)
        case 3: // Open Hat
            return generateOpenHat(time: time, params: params, envelope: envelope)
        case 4: // Crash
            return generateCrash(time: time, params: params, envelope: envelope)
        case 5: // Bass
            return generateBass(time: time, params: params, envelope: envelope)
        default:
            return 0.0
        }
    }
    
    private func calculateEnvelope(time: Double, params: SynthParameters) -> Double {
        if time <= params.attack {
            return time / params.attack
        } else if time <= params.attack + params.decay {
            let decayTime = time - params.attack
            let decayProgress = decayTime / params.decay
            return 1.0 - (1.0 - params.sustain) * decayProgress
        } else {
            let releaseTime = time - params.attack - params.decay
            let releaseProgress = min(releaseTime / params.release, 1.0)
            return params.sustain * (1.0 - releaseProgress)
        }
    }
    
    private func generateKick(time: Double, params: SynthParameters, envelope: Double) -> Double {
        let pitchEnv = exp(-time / params.pitchDecay)
        let frequency = params.frequency * (1.0 + pitchEnv * 2.0)
        let sine = sin(2.0 * Double.pi * frequency * time)
        let noise = (Double.random(in: -1...1) * params.noiseAmount)
        return (sine * (1.0 - params.noiseAmount) + noise) * envelope * 0.8
    }
    
    private func generateSnare(time: Double, params: SynthParameters, envelope: Double) -> Double {
        let tone = sin(2.0 * Double.pi * params.frequency * time) * (1.0 - params.noiseAmount)
        let noise = Double.random(in: -1...1) * params.noiseAmount
        return (tone + noise) * envelope * 0.6
    }
    
    private func generateHiHat(time: Double, params: SynthParameters, envelope: Double) -> Double {
        let noise = Double.random(in: -1...1)
        let filtered = noise * (1.0 - exp(-time * params.frequency / 1000))
        return filtered * envelope * 0.4
    }
    
    private func generateOpenHat(time: Double, params: SynthParameters, envelope: Double) -> Double {
        let noise = Double.random(in: -1...1)
        let filtered = noise * (1.0 - exp(-time * params.frequency / 2000))
        return filtered * envelope * 0.3
    }
    
    private func generateCrash(time: Double, params: SynthParameters, envelope: Double) -> Double {
        let noise = Double.random(in: -1...1)
        let shimmer = sin(2.0 * Double.pi * params.frequency * time * 0.1)
        return (noise * 0.8 + shimmer * 0.2) * envelope * 0.5
    }
    
    private func generateBass(time: Double, params: SynthParameters, envelope: Double) -> Double {
        let pitchEnv = exp(-time / params.pitchDecay)
        let frequency = params.frequency * (1.0 + pitchEnv * 1.5)
        let square = sin(2.0 * Double.pi * frequency * time) > 0 ? 1.0 : -1.0
        let filtered = square * exp(-time * 5.0)
        return filtered * envelope * 0.7
    }
    
    func testSound(track: Int) {
        playDrumSound(track: track)
    }
    
    func toggleStep(track: Int, step: Int) {
        tracks[track].steps[step].toggle()
        patterns[currentPattern].tracks[track].steps[step] = tracks[track].steps[step]
    }
    
    func toggleMute(track: Int) {
        tracks[track].isMuted.toggle()
        patterns[currentPattern].tracks[track].isMuted = tracks[track].isMuted
    }
    
    func toggleSolo(track: Int) {
        tracks[track].isSolo.toggle()
        patterns[currentPattern].tracks[track].isSolo = tracks[track].isSolo
    }
    
    func clear() {
        for i in 0..<tracks.count {
            tracks[i].steps = Array(repeating: false, count: 16)
            patterns[currentPattern].tracks[i].steps = tracks[i].steps
        }
    }
    
    func randomFill() {
        for i in 0..<tracks.count {
            for j in 0..<16 {
                tracks[i].steps[j] = Double.random(in: 0...1) > 0.7
                patterns[currentPattern].tracks[i].steps[j] = tracks[i].steps[j]
            }
        }
    }
    
    func switchPattern(to index: Int) {
        patterns[currentPattern] = DrumPattern(tracks: tracks)
        currentPattern = index
        tracks = patterns[currentPattern].tracks
    }
}