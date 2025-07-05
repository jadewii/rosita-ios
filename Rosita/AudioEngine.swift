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
    
    // Effects nodes
    private var delayNode: AVAudioUnitDelay?
    private var reverbNode: AVAudioUnitReverb?
    private var distortionNode: AVAudioUnitDistortion?
    var effectsMixer = AVAudioMixerNode() // Made accessible to instruments
    
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
    @Published var currentPlayingStep = -1 // Track current step for UI
    
    // Pattern storage
    @Published var patterns: [Pattern] = (0..<8).map { _ in Pattern() }
    @Published var currentPatternSlot: Int = 0
    
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
        
        // Set up effects chain
        setupEffects()
        
        // Connect mixer to effects mixer
        let format = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 2)
        audioEngine.connect(mixerNode, to: effectsMixer, format: format)
        
        // Create instruments without starting the audio engine immediately
        for i in 0..<4 {
            let instrument = SimpleInstrument(type: InstrumentType(rawValue: i) ?? .synth, audioEngine: audioEngine, parentEngine: self)
            instruments.append(instrument)
        }
        
        print("Audio engine setup complete with \(instruments.count) instruments and effects")
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
        currentStep = 0
        currentPlayingStep = -1
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
        // Update UI with current step
        DispatchQueue.main.async {
            self.currentPlayingStep = self.currentStep
        }
        
        // Play notes for all instruments at current step
        for instrument in 0..<4 {
            for row in 0..<8 {
                let key = "\(instrument)_\(row)_\(currentStep)"
                if instrumentSteps[key] == true {
                    if instrument == 3 {
                        // Drums
                        let drumNote = drumRowToNote(row: row)
                        playDrumSound(drumType: drumNote)
                    } else {
                        // Melodic instruments
                        let note = rowToNote(row: row, instrument: instrument)
                        playNote(instrument: instrument, note: note)
                    }
                }
            }
        }
        
        currentStep = (currentStep + 1) % 16
    }
    
    private func rowToNote(row: Int, instrument: Int) -> Int {
        // Map grid row to MIDI note (8 rows)
        // Row 0 is at the top (highest note), Row 7 is at the bottom (lowest note)
        let scaleNotes = [0, 2, 4, 5, 7, 9, 11, 12] // C major scale intervals
        let noteOffset = scaleNotes[7 - row] // Invert row for bottom-to-top
        
        let baseNote: Int
        switch instrument {
        case 0: baseNote = 60 // C4 for synth
        case 1: baseNote = 36 // C2 for bass  
        case 2: baseNote = 48 // C3 for keys
        default: baseNote = 60
        }
        
        return baseNote + noteOffset
    }
    
    private func drumRowToNote(row: Int) -> Int {
        switch row {
        case 0: return 36 // Kick
        case 1: return 38 // Snare
        case 2: return 42 // Hi-hat closed
        case 3: return 46 // Hi-hat open
        default: return 36
        }
    }
    
    // MARK: - Note Playing
    
    func playNote(instrument: Int, note: Int) {
        guard instrument < instruments.count else { return }
        
        // Special handling for drums
        if instrument == 3 {
            // For drums, the note determines which drum sound to play
            playDrumSound(drumType: note)
        } else {
            // Regular instruments play notes normally
            let adjustedNote = note + transpose
            instruments[instrument].play(note: adjustedNote, velocity: 127)
            
            // Schedule note off
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.instruments[instrument].stop(note: adjustedNote)
            }
        }
    }
    
    // Play specific drum sounds based on the note/track
    private func playDrumSound(drumType: Int) {
        // Map MIDI notes to drum sounds
        let drumSound: Int
        switch drumType {
        case 36: drumSound = 0 // Kick
        case 38: drumSound = 1 // Snare
        case 42: drumSound = 2 // Hi-hat closed
        case 46: drumSound = 3 // Hi-hat open
        case 49: drumSound = 4 // Crash
        case 51: drumSound = 5 // Ride
        case 47: drumSound = 6 // Mid tom
        case 43: drumSound = 7 // High tom
        default: drumSound = drumType % 8
        }
        
        // Play the drum using the drums instrument
        instruments[3].playDrum(sound: drumSound)
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
        clearGrid()
    }
    
    func clearAllPatterns() {
        // Clear all instrument steps
        instrumentSteps.removeAll()
    }
    
    
    func randomizePattern() {
        // Clear current instrument's pattern first
        clearGrid()
        
        if selectedInstrument == 3 {
            // Generate classic drum patterns
            generateClassicDrumPattern()
        } else {
            // Generate melodic pattern for current instrument only
            generateMelodicPattern()
        }
    }
    
    private func generateClassicDrumPattern() {
        // Classic drum patterns from web version
        let classicPatterns = [
            // Basic Rock Pattern
            (kick: [0, 4, 8, 12], snare: [4, 12], hat1: [0, 2, 4, 6, 8, 10, 12, 14], hat2: [1, 3, 5, 7, 9, 11, 13, 15]),
            // Funk Pattern  
            (kick: [0, 3, 6, 10], snare: [4, 12], hat1: [2, 6, 10, 14], hat2: [0, 4, 8, 12]),
            // Disco Pattern
            (kick: [0, 4, 8, 12], snare: [4, 12], hat1: [2, 6, 10, 14], hat2: Array(0..<16)),
            // Breakbeat Pattern
            (kick: [0, 10], snare: [4, 7, 12], hat1: [0, 2, 8, 14], hat2: [0, 4, 8, 12])
        ]
        
        // Select a random pattern
        let selectedPattern = classicPatterns.randomElement()!
        
        // Apply kick pattern (row 0)
        for step in selectedPattern.kick {
            let key = "3_0_\(step)"
            instrumentSteps[key] = true
        }
        
        // Apply snare pattern (row 1)
        for step in selectedPattern.snare {
            let key = "3_1_\(step)"
            instrumentSteps[key] = true
        }
        
        // Apply hat1 pattern (row 2)
        for step in selectedPattern.hat1 {
            let key = "3_2_\(step)"
            instrumentSteps[key] = true
        }
        
        // Apply hat2 pattern (row 3)
        for step in selectedPattern.hat2 {
            let key = "3_3_\(step)"
            instrumentSteps[key] = true
        }
    }
    
    private func generateMelodicPattern() {
        // Musical scales
        let majorScale = [0, 2, 4, 5, 7]
        let minorScale = [0, 2, 3, 5, 7]
        let scale = Bool.random() ? majorScale : minorScale
        
        // Generate a melodic pattern
        for step in 0..<16 {
            if Double.random(in: 0...1) < 0.3 { // 30% density
                // Pick a random row from the scale
                let row = scale.randomElement()!
                let key = "\(selectedInstrument)_\(row)_\(step)"
                instrumentSteps[key] = true
            }
        }
    }
    
    func duplicatePattern() {
        let nextPattern = (currentPattern + 1) % 8
        patterns[nextPattern] = Pattern(copying: patterns[currentPattern])
    }
    
    // MARK: - Grid Management (Simple Per-Instrument View)
    
    func toggleGridCell(row: Int, col: Int) {
        guard row >= 0 && row < 8 && col >= 0 && col < 16 else { return }
        
        // For the simplified version, we'll use the row/col directly
        // but store per instrument
        let key = "\(selectedInstrument)_\(row)_\(col)"
        if instrumentSteps[key] == nil {
            instrumentSteps[key] = true
        } else {
            instrumentSteps[key] = nil
        }
    }
    
    func getGridCell(row: Int, col: Int) -> Bool {
        guard row >= 0 && row < 8 && col >= 0 && col < 16 else { return false }
        
        // Only show steps for current instrument
        let key = "\(selectedInstrument)_\(row)_\(col)"
        return instrumentSteps[key] ?? false
    }
    
    func clearGrid() {
        // Clear only current instrument's steps
        let keysToRemove = instrumentSteps.keys.filter { $0.hasPrefix("\(selectedInstrument)_") }
        for key in keysToRemove {
            instrumentSteps.removeValue(forKey: key)
        }
    }
    
    // Simple storage for instrument steps
    @Published private var instrumentSteps: [String: Bool] = [:]
    
    // MARK: - Effects Control
    
    private func setupEffects() {
        // Attach effects mixer
        audioEngine.attach(effectsMixer)
        
        // Create and attach delay
        delayNode = AVAudioUnitDelay()
        if let delay = delayNode {
            audioEngine.attach(delay)
            delay.delayTime = 0.2 // 200ms delay
            delay.feedback = 30    // 30% feedback
            delay.wetDryMix = 0   // Start with 0% wet
        }
        
        // Create and attach reverb
        reverbNode = AVAudioUnitReverb()
        if let reverb = reverbNode {
            audioEngine.attach(reverb)
            reverb.loadFactoryPreset(.mediumHall)
            reverb.wetDryMix = 0  // Start with 0% wet
        }
        
        // Create and attach distortion
        distortionNode = AVAudioUnitDistortion()
        if let distortion = distortionNode {
            audioEngine.attach(distortion)
            distortion.loadFactoryPreset(.drumsBitBrush)
            distortion.wetDryMix = 0  // Start with 0% wet
        }
        
        // Connect effects chain
        let format = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 2)
        
        // Effects mixer -> Delay -> Reverb -> Distortion -> Main output
        if let delay = delayNode, let reverb = reverbNode, let distortion = distortionNode {
            audioEngine.connect(effectsMixer, to: delay, format: format)
            audioEngine.connect(delay, to: reverb, format: format)
            audioEngine.connect(reverb, to: distortion, format: format)
            audioEngine.connect(distortion, to: audioEngine.mainMixerNode, format: format)
        }
    }
    
    func updateEffects() {
        // Update effect parameters based on slider values
        // Effect A: Delay
        if effectsEnabled[0], let delay = delayNode {
            delay.wetDryMix = Float(effectAmounts[0] * 50) // 0-50% wet
        } else {
            delayNode?.wetDryMix = 0
        }
        
        // Effect B: Reverb
        if effectsEnabled[1], let reverb = reverbNode {
            reverb.wetDryMix = Float(effectAmounts[1] * 50) // 0-50% wet
        } else {
            reverbNode?.wetDryMix = 0
        }
        
        // Effect C: Distortion
        if effectsEnabled[2], let distortion = distortionNode {
            distortion.wetDryMix = Float(effectAmounts[2] * 30) // 0-30% wet (distortion is intense)
        } else {
            distortionNode?.wetDryMix = 0
        }
        
        // Effect D: Chorus (using delay with modulation for simple chorus)
        if effectsEnabled[3], let delay = delayNode {
            delay.delayTime = 0.02 + (effectAmounts[3] * 0.03) // 20-50ms for chorus effect
            delay.feedback = Float(effectAmounts[3] * 20) // 0-20% feedback
        }
    }
    
    // MARK: - ADSR Control
    
    func updateADSR() {
        // TODO: Implement ADSR when AudioKit is configured
        print("ADSR updated: A:\(attack) D:\(decay) S:\(sustain) R:\(release)")
    }
    
    // MARK: - Pattern Management
    
    func switchToPattern(_ slot: Int) {
        guard slot >= 0 && slot < patterns.count else { return }
        currentPatternSlot = slot
        currentPattern = slot
    }
    
    func duplicateCurrentPattern() {
        guard currentPatternSlot < patterns.count - 1 else { return }
        let nextSlot = currentPatternSlot + 1
        patterns[nextSlot] = patterns[currentPatternSlot]
        switchToPattern(nextSlot)
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

class Pattern {
    // Each instrument has its own 12x8 grid (12 rows, 8 steps)
    var synthGrid: [[Bool]] = Array(repeating: Array(repeating: false, count: 8), count: 12)
    var bassGrid: [[Bool]] = Array(repeating: Array(repeating: false, count: 8), count: 12)
    var keysGrid: [[Bool]] = Array(repeating: Array(repeating: false, count: 8), count: 12)
    var drumsGrid: [[Bool]] = Array(repeating: Array(repeating: false, count: 8), count: 12)
    
    init() {}
    
    // Copy constructor for pattern duplication
    init(copying other: Pattern) {
        self.synthGrid = other.synthGrid
        self.bassGrid = other.bassGrid
        self.keysGrid = other.keysGrid
        self.drumsGrid = other.drumsGrid
    }
    
    // Get grid for specific instrument
    func getGrid(for instrument: Int) -> [[Bool]] {
        switch instrument {
        case 0: return synthGrid
        case 1: return bassGrid
        case 2: return keysGrid
        case 3: return drumsGrid
        default: return synthGrid
        }
    }
    
    // Set grid for specific instrument
    func setGrid(for instrument: Int, grid: [[Bool]]) {
        switch instrument {
        case 0: synthGrid = grid
        case 1: bassGrid = grid
        case 2: keysGrid = grid
        case 3: drumsGrid = grid
        default: break
        }
    }
}

struct Track {
    var steps: [Bool] = Array(repeating: false, count: 16)
    var notes: [Int] = Array(repeating: 60, count: 16)
    var instruments: [Int] = Array(repeating: -1, count: 16) // -1 means no instrument assigned
}

// MARK: - Simplified Instrument Class for UI Testing

class SimpleInstrument {
    private let type: InstrumentType
    private var oscillatorNodes: [Int: AVAudioPlayerNode] = [:]
    private let audioEngine: AVAudioEngine
    private let mixer: AVAudioMixerNode
    private weak var parentEngine: AudioEngine?
    
    init(type: InstrumentType, audioEngine: AVAudioEngine, parentEngine: AudioEngine? = nil) {
        self.type = type
        self.audioEngine = audioEngine
        self.mixer = AVAudioMixerNode()
        self.parentEngine = parentEngine
        
        print("Created \(type.name) instrument with \(type.waveformType) waveform")
    }
    
    private func setupMixerIfNeeded() {
        guard !audioEngine.attachedNodes.contains(mixer) else { return }
        
        audioEngine.attach(mixer)
        
        // Use a proper audio format
        let format = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 1)
        
        // Connect to effects mixer if available, otherwise main mixer
        if let parent = parentEngine {
            audioEngine.connect(mixer, to: parent.effectsMixer, format: format)
        } else {
            audioEngine.connect(mixer, to: audioEngine.mainMixerNode, format: format)
        }
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
            
            // Different waveforms and characteristics for different instruments
            let value: Float
            switch type {
            case .synth:
                // Sawtooth wave with slight detuning for richness
                let detune = 1.002
                let saw1 = Float(2.0 * (time * frequency).truncatingRemainder(dividingBy: 1.0) - 1.0)
                let saw2 = Float(2.0 * (time * frequency * detune).truncatingRemainder(dividingBy: 1.0) - 1.0)
                value = amplitude * (saw1 + saw2 * 0.5) / 1.5
                
            case .bass:
                // Square wave with sub-oscillator
                let fundamental = Float(sin(time * frequency * 2 * .pi) > 0 ? 1.0 : -1.0)
                let subOsc = Float(sin(time * frequency * 0.5 * 2 * .pi)) * 0.3 // Sub oscillator
                value = amplitude * (fundamental + subOsc) * 0.8
                
            case .keys:
                // Electric piano-like sound (multiple harmonics)
                let fundamental = Float(sin(time * frequency * 2 * .pi))
                let harmonic2 = Float(sin(time * frequency * 2 * 2 * .pi)) * 0.5
                let harmonic3 = Float(sin(time * frequency * 3 * 2 * .pi)) * 0.25
                value = amplitude * (fundamental + harmonic2 + harmonic3) / 1.75
                
            case .drums:
                // Noise with envelope for drums
                let envelope = Float(exp(-time * 5)) // Quick decay
                value = amplitude * envelope * Float.random(in: -1...1)
            }
            
            // Apply ADSR envelope from the parent audio engine
            let attack = parentEngine?.attack ?? 0.01
            let decay = parentEngine?.decay ?? 0.1
            let sustain = Float(parentEngine?.sustain ?? 0.8)
            let release = parentEngine?.release ?? 0.3
            
            let envelope: Float
            if time < attack {
                envelope = Float(time / attack)
            } else if time < attack + decay {
                let decayTime = time - attack
                let sustainDiff = 1.0 - Double(sustain)
                envelope = Float(1.0 - (sustainDiff * decayTime / decay))
            } else if time < duration - release {
                envelope = sustain
            } else {
                let releaseTime = time - (duration - release)
                envelope = sustain * Float(1.0 - releaseTime / release)
            }
            
            data[i] = value * envelope
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
        for (_, playerNode) in oscillatorNodes {
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
    
    // Sample buffers cache
    private var drumSamples: [Int: AVAudioPCMBuffer] = [:]
    
    private func loadDrumSamples() {
        // Map sound indices to sample filenames
        let sampleFiles = [
            0: "FB Kick 1",    // Kick
            1: "FB Snare 6",   // Snare
            2: "FB Hat 1",     // Hi-hat closed
            3: "FB Hat 5"      // Hi-hat open
        ]
        
        for (index, filename) in sampleFiles {
            if let url = Bundle.main.url(forResource: filename, withExtension: "wav", subdirectory: "Samples") {
                do {
                    let file = try AVAudioFile(forReading: url)
                    let format = file.processingFormat
                    let frameCount = AVAudioFrameCount(file.length)
                    
                    if let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) {
                        try file.read(into: buffer)
                        drumSamples[index] = buffer
                    }
                } catch {
                    print("Failed to load drum sample \(filename): \(error)")
                }
            }
        }
    }
    
    // Play drum sounds (for drums instrument only)
    func playDrum(sound: Int) {
        guard type == .drums else { return }
        setupMixerIfNeeded()
        
        // Load samples if not already loaded
        if drumSamples.isEmpty {
            loadDrumSamples()
        }
        
        let playerNode = AVAudioPlayerNode()
        audioEngine.attach(playerNode)
        
        // Use sample if available, otherwise fall back to synthesis
        if let sampleBuffer = drumSamples[sound] {
            // Play the actual sample
            let format = sampleBuffer.format
            audioEngine.connect(playerNode, to: mixer, format: format)
            playerNode.scheduleBuffer(sampleBuffer, at: nil, options: .interrupts, completionHandler: nil)
            playerNode.play()
            
            // Clean up after sample finishes
            let duration = Double(sampleBuffer.frameLength) / format.sampleRate
            DispatchQueue.main.asyncAfter(deadline: .now() + duration + 0.1) {
                playerNode.stop()
                self.audioEngine.detach(playerNode)
            }
        } else {
            // Fall back to synthesis for sounds without samples
            let format = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 1)!
            audioEngine.connect(playerNode, to: mixer, format: format)
            
            // Generate different drum sounds based on the sound parameter
            let sampleRate = 44100.0
            let duration: Double
            let frequency: Double
            let noiseAmount: Double
            
            switch sound {
            case 0: // Kick
                duration = 0.2
                frequency = 60.0
                noiseAmount = 0.1
            case 1: // Snare
                duration = 0.15
                frequency = 200.0
                noiseAmount = 0.8
            case 2: // Hi-hat closed
                duration = 0.05
                frequency = 8000.0
                noiseAmount = 0.9
            case 3: // Hi-hat open
                duration = 0.2
                frequency = 8000.0
                noiseAmount = 0.9
            case 4: // Crash
                duration = 0.5
                frequency = 5000.0
                noiseAmount = 0.95
            case 5: // Ride
                duration = 0.3
                frequency = 6000.0
                noiseAmount = 0.7
            case 6, 7: // Toms
                duration = 0.15
                frequency = 100.0 + Double(sound - 6) * 50.0
                noiseAmount = 0.2
            default:
                duration = 0.1
                frequency = 1000.0
                noiseAmount = 0.5
            }
            
            let frameCount = AVAudioFrameCount(sampleRate * duration)
            guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else { return }
            
            buffer.frameLength = frameCount
            let data = buffer.floatChannelData![0]
            
            // Generate drum sound (combination of tone and noise)
            for i in 0..<Int(frameCount) {
                let time = Double(i) / sampleRate
                let envelope = exp(-time * 10.0) // Exponential decay
                
                // Tone component
                let tone = sin(2.0 * Double.pi * frequency * time) * (1.0 - noiseAmount)
                
                // Noise component
                let noise = (Double.random(in: -1...1)) * noiseAmount
                
                // Combine and apply envelope
                data[i] = Float((tone + noise) * envelope * 0.5)
            }
            
            playerNode.scheduleBuffer(buffer, at: nil, options: .interrupts, completionHandler: nil)
            playerNode.play()
            
            // Clean up after a delay
            DispatchQueue.main.asyncAfter(deadline: .now() + duration + 0.1) {
                playerNode.stop()
                self.audioEngine.detach(playerNode)
            }
        }
    }
}