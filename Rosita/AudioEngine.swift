import SwiftUI
import AVFoundation
// TODO: Re-enable AudioKit when dependencies are properly configured
// import AudioKit
// import SoundpipeAudioKit
// import AudioKitEX

class AudioEngine: ObservableObject {
    // Simplified audio engine for UI testing
    private var audioEngine = AVAudioEngine()
    private var instruments: [SimpleInstrument] = []
    
    // Sequencer
    private var sequencerTimer: Timer?
    private var currentStep = 0
    
    // Published properties
    @Published var isPlaying = false
    @Published var bpm: Double = 120
    @Published var selectedInstrument = 0
    @Published var transpose = 0
    @Published var arpeggiatorMode = 0
    @Published var currentPattern = 0
    
    // Pattern storage
    @Published var patterns: [Pattern] = Array(repeating: Pattern(), count: 8)
    
    // ADSR values
    @Published var attack: Double = 0.01
    @Published var decay: Double = 0.1
    @Published var sustain: Double = 0.8
    @Published var release: Double = 0.3
    
    // Effects parameters
    @Published var effectsEnabled = [true, true, true, true]
    @Published var effectAmounts: [Double] = [0.3, 0.3, 0.2, 0.3]
    
    init() {
        setupAudio()
    }
    
    private func setupAudio() {
        // Create a simple mixer node to ensure the audio engine has proper input/output connections
        let mixerNode = AVAudioMixerNode()
        audioEngine.attach(mixerNode)
        
        // Connect mixer to main mixer to output - this ensures proper node graph
        let format = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 2)
        audioEngine.connect(mixerNode, to: audioEngine.mainMixerNode, format: format)
        
        // Create instruments without starting the audio engine immediately
        for i in 0..<4 {
            let instrument = SimpleInstrument(type: InstrumentType(rawValue: i) ?? .synth, audioEngine: audioEngine)
            instruments.append(instrument)
        }
        
        print("Audio engine setup complete with \(instruments.count) instruments and mixer node")
    }
    
    private func startAudioEngineIfNeeded() {
        guard !audioEngine.isRunning else { return }
        
        do {
            // Configure audio session for playback
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playback, mode: .default)
            try audioSession.setActive(true)
            
            audioEngine.prepare()
            try audioEngine.start()
            print("AVAudioEngine started successfully")
        } catch {
            print("Failed to start audio engine: \(error)")
        }
    }
    
    // MARK: - Playback Control
    
    func togglePlayback() {
        if isPlaying {
            stop()
        } else {
            play()
        }
    }
    
    func play() {
        startAudioEngineIfNeeded()
        isPlaying = true
        currentStep = 0
        startSequencer()
    }
    
    func stop() {
        isPlaying = false
        sequencerTimer?.invalidate()
        sequencerTimer = nil
        stopAllNotes()
    }
    
    private func startSequencer() {
        let interval = 60.0 / bpm / 4.0 // 16th notes
        sequencerTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { _ in
            self.processStep()
        }
    }
    
    private func processStep() {
        let pattern = patterns[currentPattern]
        
        for (trackIndex, track) in pattern.tracks.enumerated() {
            if track.steps[currentStep] {
                playNote(instrument: trackIndex, note: track.notes[currentStep])
            }
        }
        
        currentStep = (currentStep + 1) % 16
    }
    
    // MARK: - Note Playing
    
    func playNote(instrument: Int, note: Int) {
        guard instrument < instruments.count else { return }
        
        let adjustedNote = note + transpose
        instruments[instrument].play(note: adjustedNote, velocity: 127)
        
        // Schedule note off
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.instruments[instrument].stop(note: adjustedNote)
        }
    }
    
    func noteOn(note: Int) {
        startAudioEngineIfNeeded()
        let adjustedNote = note + transpose
        instruments[selectedInstrument].play(note: adjustedNote, velocity: 127)
    }
    
    func noteOff(note: Int) {
        let adjustedNote = note + transpose
        instruments[selectedInstrument].stop(note: adjustedNote)
    }
    
    func stopAllNotes() {
        for instrument in instruments {
            instrument.stopAll()
        }
    }
    
    // MARK: - Pattern Management
    
    func clearPattern() {
        patterns[currentPattern] = Pattern()
    }
    
    func clearAllPatterns() {
        patterns = Array(repeating: Pattern(), count: 8)
    }
    
    func randomizePattern() {
        // Only randomize the selected track
        var currentPatternCopy = patterns[currentPattern]
        let trackIndex = selectedInstrument
        
        // Clear existing steps for this track
        for step in 0..<16 {
            currentPatternCopy.tracks[trackIndex].steps[step] = false
        }
        
        // Add random steps (about 25% density for musicality)
        for step in 0..<16 {
            if Double.random(in: 0...1) < 0.25 {
                currentPatternCopy.tracks[trackIndex].steps[step] = true
                // Use appropriate note range based on instrument
                let noteRange: ClosedRange<Int>
                switch trackIndex {
                case 1: // Bass
                    noteRange = 36...48
                case 3: // Drums
                    noteRange = 36...51  // Standard drum kit range
                default: // Melody instruments
                    noteRange = 48...72
                }
                currentPatternCopy.tracks[trackIndex].notes[step] = Int.random(in: noteRange)
            }
        }
        
        patterns[currentPattern] = currentPatternCopy
    }
    
    func duplicatePattern() {
        let nextPattern = (currentPattern + 1) % 8
        patterns[nextPattern] = patterns[currentPattern]
    }
    
    // MARK: - Grid Management
    
    func toggleGridCell(track: Int, step: Int, note: Int = 60) {
        guard track < patterns[currentPattern].tracks.count,
              step < patterns[currentPattern].tracks[track].steps.count else {
            return
        }
        patterns[currentPattern].tracks[track].steps[step].toggle()
        if patterns[currentPattern].tracks[track].steps[step] {
            patterns[currentPattern].tracks[track].notes[step] = note
        }
    }
    
    func getGridCell(track: Int, step: Int) -> Bool {
        guard track < patterns[currentPattern].tracks.count,
              step < patterns[currentPattern].tracks[track].steps.count else {
            return false
        }
        return patterns[currentPattern].tracks[track].steps[step]
    }
    
    // MARK: - Effects Control
    
    func updateEffects() {
        // TODO: Implement effects when AudioKit is configured
        print("Effects updated: \(effectAmounts)")
    }
    
    // MARK: - ADSR Control
    
    func updateADSR() {
        // TODO: Implement ADSR when AudioKit is configured
        print("ADSR updated: A:\(attack) D:\(decay) S:\(sustain) R:\(release)")
    }
}

// MARK: - Supporting Types

enum InstrumentType: Int {
    case synth = 0
    case bass = 1
    case keys = 2
    case drums = 3
    
    var waveformType: String {
        switch self {
        case .synth: return "sawtooth"
        case .bass: return "square"
        case .keys: return "sine"
        case .drums: return "triangle"
        }
    }
    
    var color: Color {
        switch self {
        case .synth: return Color(hex: "FFB6C1")  // Light pink like web version
        case .bass: return Color(hex: "87CEEB")   // Sky blue like web version
        case .keys: return Color(hex: "DDA0DD")   // Plum purple like web version
        case .drums: return Color(hex: "FFD700")  // Gold yellow like web version
        }
    }
    
    var name: String {
        switch self {
        case .synth: return "1"
        case .bass: return "2"
        case .keys: return "3"
        case .drums: return "Kit 4"
        }
    }
    
    var displayNumber: String {
        switch self {
        case .synth: return "1"
        case .bass: return "2"
        case .keys: return "3"
        case .drums: return "4"
        }
    }
}

struct Pattern {
    var tracks: [Track] = Array(repeating: Track(), count: 8)
}

struct Track {
    var steps: [Bool] = Array(repeating: false, count: 16)
    var notes: [Int] = Array(repeating: 60, count: 16)
}

// MARK: - Simplified Instrument Class for UI Testing

class SimpleInstrument {
    private let type: InstrumentType
    private var oscillatorNodes: [Int: AVAudioPlayerNode] = [:]
    private let audioEngine: AVAudioEngine
    private let mixer: AVAudioMixerNode
    
    init(type: InstrumentType, audioEngine: AVAudioEngine) {
        self.type = type
        self.audioEngine = audioEngine
        self.mixer = AVAudioMixerNode()
        
        print("Created \(type.name) instrument with \(type.waveformType) waveform")
    }
    
    private func setupMixerIfNeeded() {
        guard !audioEngine.attachedNodes.contains(mixer) else { return }
        
        audioEngine.attach(mixer)
        
        // Use a proper audio format
        let format = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 1)
        audioEngine.connect(mixer, to: audioEngine.mainMixerNode, format: format)
    }
    
    func play(note: Int, velocity: Int) {
        setupMixerIfNeeded()
        let frequency = noteToFrequency(note)
        
        // Create a simple tone using AVAudioPlayerNode and AVAudioPCMBuffer
        let playerNode = AVAudioPlayerNode()
        
        // Safely attach and connect the player node
        audioEngine.attach(playerNode)
        
        let format = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 1)!
        audioEngine.connect(playerNode, to: mixer, format: format)
        
        // Generate a simple sine wave tone
        let sampleRate = 44100.0
        let duration = 0.5 // Half second note
        let frameCount = AVAudioFrameCount(sampleRate * duration)
        
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else { return }
        
        buffer.frameLength = frameCount
        
        let data = buffer.floatChannelData![0]
        for i in 0..<Int(frameCount) {
            let time = Double(i) / sampleRate
            let amplitude = Float(0.3 * pow(Double(velocity) / 127.0, 0.5)) // Velocity scaling
            
            // Different waveforms for different instruments
            let value: Float
            switch type {
            case .synth:
                // Sawtooth wave
                value = amplitude * Float(2.0 * (time * frequency).truncatingRemainder(dividingBy: 1.0) - 1.0)
            case .bass:
                // Square wave
                value = amplitude * Float(sin(time * frequency * 2 * .pi) > 0 ? 1.0 : -1.0)
            case .keys:
                // Sine wave
                value = amplitude * Float(sin(time * frequency * 2 * .pi))
            case .drums:
                // Noise with envelope for drums
                let envelope = Float(exp(-time * 5)) // Quick decay
                value = amplitude * envelope * Float.random(in: -1...1)
            }
            
            data[i] = value
        }
        
        oscillatorNodes[note] = playerNode
        playerNode.scheduleBuffer(buffer, at: nil, options: [], completionHandler: nil)
        playerNode.play()
        
        // Auto-stop after duration
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            self.stop(note: note)
        }
        
        print("Playing \(type.name): note \(note), frequency \(String(format: "%.1f", frequency))Hz")
    }
    
    func stop(note: Int) {
        if let playerNode = oscillatorNodes[note] {
            playerNode.stop()
            audioEngine.detach(playerNode)
            oscillatorNodes.removeValue(forKey: note)
        }
        print("Stopping \(type.name): note \(note)")
    }
    
    func stopAll() {
        for (note, playerNode) in oscillatorNodes {
            playerNode.stop()
            audioEngine.detach(playerNode)
        }
        oscillatorNodes.removeAll()
        print("Stopping all notes for \(type.name)")
    }
    
    func updateEnvelope(attack: Double, decay: Double, sustain: Double, release: Double) {
        print("Updated \(type.name) envelope: A:\(attack) D:\(decay) S:\(sustain) R:\(release)")
    }
    
    private func noteToFrequency(_ note: Int) -> Double {
        return 440.0 * pow(2.0, Double(note - 69) / 12.0)
    }
}