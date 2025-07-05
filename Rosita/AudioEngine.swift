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
    @Published var transpose = 0  // Keyboard transpose
    @Published var gridTranspose = 0  // Grid transpose
    @Published var arpeggiatorMode = 0
    @Published var currentPattern = 0
    @Published var currentPlayingStep = -1 // Track current step for UI
    
    // Track waveform/kit for each instrument
    @Published var instrumentWaveforms = [0, 0, 0, 0] // 0=square, 1=saw, 2=triangle, 3=sine, 4=reverse saw
    
    // Pattern storage
    @Published var patterns: [Pattern] = (0..<8).map { _ in Pattern() }
    @Published var currentPatternSlot: Int = 0
    
    // ADSR values per track
    @Published var trackADSR: [[Double]] = [
        [0.01, 0.1, 0.8, 0.3], // Track 0: [attack, decay, sustain, release]
        [0.01, 0.1, 0.8, 0.3], // Track 1
        [0.01, 0.1, 0.8, 0.3], // Track 2
        [0.01, 0.1, 0.0, 0.1]  // Track 3 (drums - shorter envelope)
    ]
    
    // Effects parameters per track
    @Published var trackEffectsEnabled: [[Bool]] = [
        [true, true, true, true],  // Track 0: [delay, reverb, distortion, chorus]
        [true, true, true, true],  // Track 1
        [true, true, true, true],  // Track 2
        [true, true, true, true]   // Track 3
    ]
    @Published var trackEffectAmounts: [[Double]] = [
        [0.3, 0.3, 0.2, 0.3], // Track 0
        [0.3, 0.3, 0.2, 0.3], // Track 1
        [0.3, 0.3, 0.2, 0.3], // Track 2
        [0.3, 0.3, 0.2, 0.3]  // Track 3
    ]
    
    // Step recording
    @Published var isRecording = false
    @Published var currentRecordingStep = 0
    @Published var recordingMode: RecordingMode = .freeForm
    
    // Track recently recorded notes to prevent double triggering
    private var recentlyRecordedNotes: Set<String> = []
    
    
    enum RecordingMode: String {
        case freeForm = "FREE"
        case trStyle = "TR"
    }
    
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
        
        // print("Audio engine setup complete with \(instruments.count) instruments and effects")
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
            // print("AVAudioEngine started successfully")
        } catch {
            // print("Failed to start audio engine: \(error)")
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
        
        // Use CADisplayLink for better timing accuracy
        sequencerTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            self?.processStep()
        }
        
        // Set timer tolerance for better performance
        sequencerTimer?.tolerance = interval * 0.1
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
                
                // Skip if this was just recorded to prevent double triggering
                if recentlyRecordedNotes.contains(key) {
                    continue
                }
                
                if instrumentSteps[key] == true {
                    if instrument == 3 {
                        // Drums
                        let drumNote = drumRowToNote(row: row)
                        playDrumSound(drumType: drumNote)
                    } else {
                        // Melodic instruments - use stored note or default
                        let note = instrumentNotes[key] ?? rowToNote(row: row, instrument: instrument)
                        playNote(instrument: instrument, note: note + gridTranspose)
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
        
        // Update effects for the instrument being played
        updateTrackEffects(track: instrument)
        
        // Special handling for drums
        if instrument == 3 {
            // For drums, the note determines which drum sound to play
            playDrumSound(drumType: note)
        } else {
            // Regular instruments play notes normally
            let adjustedNote = note + transpose
            instruments[instrument].play(note: adjustedNote, velocity: 127)
            
            // Schedule note off based on release time
            let releaseTime = trackADSR[instrument][3] // Get release time for this track
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1 + releaseTime) {
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
        
        // Update effects for the current instrument
        updateTrackEffects(track: selectedInstrument)
        
        let adjustedNote = note + transpose
        instruments[selectedInstrument].play(note: adjustedNote, velocity: 127)
    }
    
    func noteOff(note: Int) {
        let adjustedNote = note + transpose
        
        // Add a small delay based on release time for smoother sound
        let releaseTime = trackADSR[selectedInstrument][3]
        if releaseTime > 0.05 {
            DispatchQueue.main.asyncAfter(deadline: .now() + releaseTime * 0.5) {
                self.instruments[self.selectedInstrument].stop(note: adjustedNote)
            }
        } else {
            instruments[selectedInstrument].stop(note: adjustedNote)
        }
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
    
    func getGridCellOctave(row: Int, col: Int) -> Int {
        guard row >= 0 && row < 8 && col >= 0 && col < 16 else { return 0 }
        
        let key = "\(selectedInstrument)_\(row)_\(col)"
        if let note = instrumentNotes[key] {
            // Calculate octave relative to the instrument's base octave
            let baseNote: Int
            switch selectedInstrument {
            case 0: baseNote = 60 // C4
            case 1: baseNote = 36 // C2
            case 2: baseNote = 48 // C3
            default: baseNote = 60
            }
            return (note - baseNote) / 12
        }
        return 0 // Default octave
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
    // Store actual note values for each step
    private var instrumentNotes: [String: Int] = [:]
    
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
    
    func updateTrackEffects(track: Int) {
        guard track >= 0 && track < 4 else { return }
        
        let effectsEnabled = trackEffectsEnabled[track]
        let effectAmounts = trackEffectAmounts[track]
        
        // Update effect parameters based on slider values for the specific track
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
    
    func updateTrackEffect(track: Int, effect: Int, enabled: Bool, amount: Double) {
        guard track >= 0 && track < 4 && effect >= 0 && effect < 4 else { return }
        trackEffectsEnabled[track][effect] = enabled
        trackEffectAmounts[track][effect] = amount
        updateTrackEffects(track: track)
    }
    
    // MARK: - ADSR Control
    
    func updateTrackADSR(track: Int, attack: Double, decay: Double, sustain: Double, release: Double) {
        guard track >= 0 && track < 4 else { return }
        trackADSR[track] = [attack, decay, sustain, release]
        
        // Clear buffer cache for this instrument to regenerate with new ADSR
        if track < instruments.count {
            instruments[track].clearBufferCache()
        }
        // print("Track \(track) ADSR updated: A:\(attack) D:\(decay) S:\(sustain) R:\(release)")
    }
    
    func getTrackADSR(track: Int) -> [Double] {
        guard track >= 0 && track < 4 else { return [0.01, 0.1, 0.8, 0.3] }
        return trackADSR[track]
    }
    
    // MARK: - Instrument Waveform Control
    
    func cycleInstrumentWaveform(_ instrument: Int) {
        guard instrument >= 0 && instrument < 4 else { return }
        
        if instrument == 3 {
            // Cycle through 4 drum kits
            instrumentWaveforms[instrument] = (instrumentWaveforms[instrument] + 1) % 4
        } else {
            // Cycle through 5 waveforms for melodic instruments
            instrumentWaveforms[instrument] = (instrumentWaveforms[instrument] + 1) % 5
        }
        
        // Update the actual instrument waveform
        if instrument < instruments.count {
            // let waveformNames = ["square", "sine", "sawtooth", "triangle"]
            // let drumKitNames = ["kit1", "kit2", "kit3", "kit4"]
            
            if instrument == 3 {
                // For drums, switch between kits
                // print("Switched drums to \(drumKitNames[instrumentWaveforms[instrument]])")
            } else {
                // For melodic instruments, switch waveforms
                // print("Switched \(InstrumentType(rawValue: instrument)?.name ?? "instrument") to \(waveformNames[instrumentWaveforms[instrument]])")
            }
        }
    }
    
    // MARK: - Step Recording
    
    func toggleRecording() {
        isRecording.toggle()
        if isRecording {
            // Don't clear the grid - keep existing steps
            
            if recordingMode == .trStyle {
                // TR style - step by step
                currentRecordingStep = 0
            } else {
                // Free form - real time recording
                // If not playing, start playback for free form recording
                if !isPlaying {
                    play()
                }
            }
        }
    }
    
    func toggleRecordingMode() {
        recordingMode = recordingMode == .freeForm ? .trStyle : .freeForm
        // Stop recording when switching modes
        if isRecording {
            isRecording = false
        }
    }
    
    
    func recordNoteToStep(note: Int) {
        guard isRecording else { return }
        
        if recordingMode == .trStyle {
            // TR-style step recording
            guard currentRecordingStep < 16 else { return }
            
            // Convert MIDI note to grid row for the selected instrument
            let row = noteToGridRow(note: note, instrument: selectedInstrument)
            
            // Set the step in the grid
            let key = "\(selectedInstrument)_\(row)_\(currentRecordingStep)"
            instrumentSteps[key] = true
            instrumentNotes[key] = note  // Store the actual note value
            
            // Move to next step
            currentRecordingStep += 1
            
            // Stop recording when we reach step 16
            if currentRecordingStep >= 16 {
                isRecording = false
                currentRecordingStep = 0
            }
        } else {
            // Free form recording - add note immediately to current playing step
            if isPlaying {
                let row = noteToGridRow(note: note, instrument: selectedInstrument)
                let key = "\(selectedInstrument)_\(row)_\(currentPlayingStep)"
                instrumentSteps[key] = true
                instrumentNotes[key] = note  // Store the actual note value
                
                // Mark this note as recently recorded to prevent double triggering
                recentlyRecordedNotes.insert(key)
                
                // Clear it after a short delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                    self?.recentlyRecordedNotes.remove(key)
                }
            }
        }
    }
    
    private func noteToGridRow(note: Int, instrument: Int) -> Int {
        if instrument == 3 {
            // For drums, map notes to specific drum sounds (0-3 for basic kit)
            switch note {
            case 36, 48, 60, 72: return 0 // Kick (C notes)
            case 38, 50, 62, 74: return 1 // Snare (D notes)
            case 42, 54, 66, 78: return 2 // Hi-hat closed (F# notes)
            case 46, 58, 70, 82: return 3 // Hi-hat open (A# notes)
            default: return note % 4 // Map other notes to available drum sounds
            }
        } else {
            // For melodic instruments, use the C major scale
            let scaleNotes = [0, 2, 4, 5, 7, 9, 11, 12] // C major scale intervals
            // let octave = (note - 60) / 12
            let noteInOctave = (note - 60) % 12
            
            // Find closest note in scale
            var closestScaleIndex = 0
            var minDistance = 12
            for (index, scaleNote) in scaleNotes.enumerated() {
                let distance = abs(noteInOctave - scaleNote)
                if distance < minDistance {
                    minDistance = distance
                    closestScaleIndex = index
                }
            }
            
            // Map to row (0-7, with 0 at top)
            let row = 7 - closestScaleIndex
            return max(0, min(7, row))
        }
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
    
    // Pre-computed buffer cache
    private var bufferCache: [String: AVAudioPCMBuffer] = [:]
    private let bufferCacheQueue = DispatchQueue(label: "buffer.cache.queue", attributes: .concurrent)
    
    init(type: InstrumentType, audioEngine: AVAudioEngine, parentEngine: AudioEngine? = nil) {
        self.type = type
        self.audioEngine = audioEngine
        self.mixer = AVAudioMixerNode()
        self.parentEngine = parentEngine
        
        // print("Created \(type.name) instrument with \(type.waveformType) waveform")
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
    
    private func getOrCreateBuffer(note: Int, velocity: Int, waveformIndex: Int) -> AVAudioPCMBuffer? {
        let cacheKey = "\(type.rawValue)_\(note)_\(velocity)_\(waveformIndex)"
        
        // Check cache first
        if let cachedBuffer = bufferCacheQueue.sync(execute: { bufferCache[cacheKey] }) {
            return cachedBuffer
        }
        
        // Create buffer
        let format = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 1)!
        let sampleRate = 44100.0
        let duration = 0.2 // Shorter buffer for less lag
        let frameCount = AVAudioFrameCount(sampleRate * duration)
        
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else { return nil }
        buffer.frameLength = frameCount
        
        let frequency = noteToFrequency(note)
        let data = buffer.floatChannelData![0]
        let amplitude = Float(0.3 * pow(Double(velocity) / 127.0, 0.5))
        
        // Generate waveform in background
        generateWaveform(data: data, frameCount: Int(frameCount), frequency: frequency, amplitude: amplitude, waveformIndex: waveformIndex, sampleRate: sampleRate, duration: duration)
        
        // Cache the buffer
        bufferCacheQueue.async(flags: .barrier) {
            self.bufferCache[cacheKey] = buffer
            // Limit cache size
            if self.bufferCache.count > 100 {
                self.bufferCache.removeAll()
            }
        }
        
        return buffer
    }
    
    func play(note: Int, velocity: Int) {
        setupMixerIfNeeded()
        
        // Get waveform index from parent engine
        let waveformIndex = parentEngine?.instrumentWaveforms[type.rawValue] ?? 0
        
        // Get or create buffer from cache
        guard let buffer = getOrCreateBuffer(note: note, velocity: velocity, waveformIndex: waveformIndex) else { return }
        
        // Create a simple tone using AVAudioPlayerNode and AVAudioPCMBuffer
        let playerNode = AVAudioPlayerNode()
        
        // Safely attach and connect the player node
        audioEngine.attach(playerNode)
        
        let format = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 1)!
        audioEngine.connect(playerNode, to: mixer, format: format)
        
        // Store player node reference and play
        oscillatorNodes[note] = playerNode
        playerNode.scheduleBuffer(buffer, at: nil, options: [], completionHandler: nil)
        playerNode.play()
        
        // Auto-stop after duration
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            self.stop(note: note)
        }
        
        // print("Playing \(type.name): note \(note), frequency \(String(format: "%.1f", frequency))Hz")
    }
    
    private func generateWaveform(data: UnsafeMutablePointer<Float>, frameCount: Int, frequency: Double, amplitude: Float, waveformIndex: Int, sampleRate: Double, duration: Double) {
        for i in 0..<frameCount {
            let time = Double(i) / sampleRate
            
            // Different waveforms and characteristics for different instruments
            let value: Float
            
            switch type {
            case .synth, .bass, .keys:
                // Generate waveform based on selected type
                switch waveformIndex {
                case 0: // Square wave
                    value = amplitude * Float(sin(time * frequency * 2 * .pi) > 0 ? 1.0 : -1.0)
                case 1: // Sawtooth wave
                    value = amplitude * Float(2.0 * (time * frequency).truncatingRemainder(dividingBy: 1.0) - 1.0)
                case 2: // Triangle wave
                    let phase = (time * frequency).truncatingRemainder(dividingBy: 1.0)
                    value = amplitude * Float(phase < 0.5 ? 4.0 * phase - 1.0 : 3.0 - 4.0 * phase)
                case 3: // Sine wave
                    value = amplitude * Float(sin(time * frequency * 2 * .pi))
                case 4: // Reverse sawtooth wave
                    value = amplitude * Float(1.0 - 2.0 * (time * frequency).truncatingRemainder(dividingBy: 1.0))
                default:
                    value = amplitude * Float(sin(time * frequency * 2 * .pi))
                }
                
            case .drums:
                // Different drum synthesis based on kit
                switch waveformIndex {
                case 0: // Kit 1 - Classic
                    let envelope = Float(exp(-time * 5))
                    value = amplitude * envelope * Float.random(in: -1...1)
                case 1: // Kit 2 - Punchy
                    let envelope = Float(exp(-time * 8))
                    let tone = Float(sin(time * frequency * 0.5 * 2 * .pi))
                    value = amplitude * envelope * (tone * 0.3 + Float.random(in: -1...1) * 0.7)
                case 2: // Kit 3 - Electronic
                    let envelope = Float(exp(-time * 10))
                    let tone = Float(sin(time * frequency * 2 * .pi) > 0 ? 1.0 : -1.0)
                    value = amplitude * envelope * tone
                case 3: // Kit 4 - Soft
                    let envelope = Float(exp(-time * 3))
                    value = amplitude * envelope * Float(sin(time * frequency * 2 * .pi)) * 0.8
                default:
                    let envelope = Float(exp(-time * 5))
                    value = amplitude * envelope * Float.random(in: -1...1)
                }
            }
            
            // Apply ADSR envelope from the parent audio engine (per-track)
            let trackADSR = parentEngine?.getTrackADSR(track: type.rawValue) ?? [0.01, 0.1, 0.8, 0.3]
            let attack = trackADSR[0]
            let decay = trackADSR[1]
            let sustain = Float(trackADSR[2])
            let release = trackADSR[3]
            
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
    }
    
    func stop(note: Int) {
        if let playerNode = oscillatorNodes[note] {
            playerNode.stop()
            audioEngine.detach(playerNode)
            oscillatorNodes.removeValue(forKey: note)
        }
        // print("Stopping \(type.name): note \(note)")
    }
    
    func stopAll() {
        for (_, playerNode) in oscillatorNodes {
            playerNode.stop()
            audioEngine.detach(playerNode)
        }
        oscillatorNodes.removeAll()
        // print("Stopping all notes for \(type.name)")
    }
    
    func clearBufferCache() {
        bufferCacheQueue.async(flags: .barrier) {
            self.bufferCache.removeAll()
        }
    }
    
    func updateEnvelope(attack: Double, decay: Double, sustain: Double, release: Double) {
        // print("Updated \(type.name) envelope: A:\(attack) D:\(decay) S:\(sustain) R:\(release)")
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
                    // print("Failed to load drum sample \(filename): \(error)")
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
        
        // Get the kit index from parent engine  
        // let kitIndex = parentEngine?.instrumentWaveforms[3] ?? 0
        // TODO: Use different drum samples based on kit selection
        
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