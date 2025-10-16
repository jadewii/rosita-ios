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
    private var chorusNode: AVAudioUnitEffect?
    private var flangerNode: AVAudioUnitEffect?
    var effectsMixer = AVAudioMixerNode() // Made accessible to instruments
    
    // Sequencer - High-precision audio-thread scheduling
    private var sequencerTimer: DispatchSourceTimer?
    private var currentStep = 0
    private var playbackSteps = [0, 0, 0, 0]  // Per-instrument playback step counters
    private var pendulumDirections = [1, 1, 1, 1]  // 1=forward, -1=backward for pendulum mode
    private var nextSampleTime: AVAudioFramePosition = 0
    private let sampleRate: Double = 44100.0
    private let audioQueue = DispatchQueue(label: "com.rosita.audio", qos: .userInteractive)
    
    // Published properties
    @Published var isPlaying = false
    @Published var bpm: Double = 120 {
        didSet {
            // Restart sequencer with new BPM if currently playing
            // Use the audio queue to avoid race conditions
            if isPlaying {
                audioQueue.async { [weak self] in
                    self?.restartSequencer()
                }
            }
        }
    }
    @Published var selectedInstrument = 0
    @Published var transpose = 0  // Keyboard transpose
    @Published var gridTranspose = 0  // Grid transpose
    @Published var arpeggiatorMode = 0
    @Published var currentPlayingStep = -1 // Track current step for UI (global forward step)
    @Published var currentInstrumentPlayingStep = -1 // Playback step for selected instrument
    
    // Track waveform/kit for each instrument
    @Published var instrumentWaveforms = [0, 0, 0, 0] // 0=square, 1=saw, 2=triangle, 3=sine, 4=reverse saw

    // Per-track octave offsets - each track can have its own octave setting
    @Published var trackOctaveOffsets = [0, 0, 0, 0] // -2 to +2 octaves

    // Current scale: 0=Major, 1=Minor, 2=Pentatonic, 3=Blues, 4=Chromatic
    @Published var currentScale = 0

    // Pattern storage - each pattern stores the complete state
    @Published var patterns: [[String: Bool]] = Array(repeating: [:], count: 8)
    @Published var patternNotes: [[String: Int]] = Array(repeating: [:], count: 8)
    @Published var patternVelocities: [[String: Float]] = Array(repeating: [:], count: 8)
    @Published var currentPatternSlot: Int = 0
    @Published var isDupMode: Bool = false
    
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
        [0.0, 0.0, 0.0, 0.0], // Track 0 - all effects start at 0
        [0.0, 0.0, 0.0, 0.0], // Track 1
        [0.0, 0.0, 0.0, 0.0], // Track 2
        [0.0, 0.0, 0.0, 0.0]  // Track 3
    ]
    
    // Step recording
    @Published var isRecording = false
    @Published var currentRecordingStep = 0
    @Published var recordingMode: RecordingMode = .freeForm

    // UI Modes
    @Published var isMixerMode = false
    @Published var isKitBrowserMode = false
    @Published var isFXMode = false
    @Published var activePerformanceFX: Int? = nil  // nil = no FX active, 0-63 = grid position

    // Drum sample selection (which sample variant is selected for each drum type)
    @Published var selectedDrumSamples = [0, 0, 0, 0] // [kick, snare, hat, perc]

    // Continuous random mode - per track
    @Published var continuousRandomEnabled = [false, false, false, false]  // One for each instrument

    // Sequence direction - per track (0=Forward, 1=Backward, 2=Pendulum, 3=Random)
    @Published var sequenceDirections = [0, 0, 0, 0]  // One for each instrument

    // Track speed/scale - per track (0=1/2x, 1=1x, 2=2x, 3=4x)
    @Published var trackSpeeds = [1, 1, 1, 1]  // Default to 1x (normal speed)

    // Drum pitch editing mode
    @Published var isDrumPitchEditMode = false
    @Published var editingDrumStep: (row: Int, col: Int)? = nil
    @Published var drumStepPitch: Double = 1.0 // 0.5 to 2.0 (half speed to double speed)

    // Storage for drum step pitches
    private var drumPitches: [String: Double] = [:] // key: "row_col", value: pitch (0.5-2.0)

    // Step edit mode (for melodic pitch editing)
    @Published var isStepEditMode = false
    @Published var editingStep: (row: Int, col: Int)? = nil
    @Published var stepPitch: Double = 0.0 // -24 to +24 semitones (octave changes only)

    // Storage for melodic step pitches
    private var melodicPitches: [String: Double] = [:] // key: "instrument_row_col", value: pitch offset in semitones

    // Storage for per-step ADSR settings (in STEP EDIT mode)
    private var stepADSR: [String: [Double]] = [:] // key: "instrument_row_col", value: [attack, decay, sustain, release]
    @Published var currentStepADSR: [Double] = [0.01, 0.1, 0.8, 0.3] // ADSR for currently selected step in STEP EDIT

    // Track length per track (2, 4, 6, 8, 10, 12, 14, 16 steps)
    @Published var trackLengths = [16, 16, 16, 16] // Default to full length (16 steps)

    // Retrig state - per step retrig count (1x, 2x, or 3x)
    @Published var currentRetrigCount = 1 // Current retrig count being set
    private var retrigCounts: [String: Int] = [:] // key: "instrument_row_col", value: retrig count (1, 2, or 3)

    // Track recently recorded notes to prevent double triggering
    private var recentlyRecordedNotes: Set<String> = []

    // Oscilloscope data
    @Published var oscilloscopeBuffer: [Float] = []
    private var audioTap: AVAudioNodeTapBlock?
    
    
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
        
        // Create instruments
        for i in 0..<4 {
            let instrument = SimpleInstrument(type: InstrumentType(rawValue: i) ?? .synth, audioEngine: audioEngine, parentEngine: self)
            instruments.append(instrument)
        }
        
        // Start audio engine immediately
        startAudioEngineIfNeeded()
        
        // print("Audio engine setup complete with \(instruments.count) instruments and effects")
    }
    
    private func startAudioEngineIfNeeded() {
        guard !audioEngine.isRunning else { return }

        do {
            // Configure audio session for low-latency playback
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playback, mode: .default, options: [.mixWithOthers])

            // Pro audio settings for minimal latency
            try audioSession.setPreferredSampleRate(44100)
            try audioSession.setPreferredIOBufferDuration(0.0029) // ~3ms latency (128 samples at 44.1kHz)

            try audioSession.setActive(true)

            audioEngine.prepare()
            try audioEngine.start()
            // print("AVAudioEngine started successfully with low-latency settings")

            // Set up audio tap for oscilloscope after engine is running
            setupOscilloscopeTap()
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

        // Make sure engine is running before starting sequencer
        guard audioEngine.isRunning else {
            print("Audio engine not running, cannot start sequencer")
            return
        }

        isPlaying = true
        currentStep = 0
        playbackSteps = [0, 0, 0, 0]  // Reset all instrument playback positions
        pendulumDirections = [1, 1, 1, 1]  // Reset pendulum directions to forward
        startSequencer()
    }

    func stop() {
        isPlaying = false
        currentStep = 0
        playbackSteps = [0, 0, 0, 0]  // Reset all instrument playback positions
        currentPlayingStep = -1

        // Cancel dispatch timer properly
        sequencerTimer?.cancel()
        sequencerTimer = nil

        stopAllNotes()
    }
    
    private func startSequencer() {
        // Initialize sample time based on mach_absolute_time
        nextSampleTime = 0

        // Create high-priority dispatch timer for checking schedule
        let timer = DispatchSource.makeTimerSource(flags: [], queue: audioQueue)
        timer.schedule(deadline: .now(), repeating: .milliseconds(10), leeway: .milliseconds(1))

        timer.setEventHandler { [weak self] in
            self?.checkAndScheduleNotes()
        }

        sequencerTimer = timer
        timer.resume()
    }

    private func restartSequencer() {
        // Stop current timer
        sequencerTimer?.cancel()
        sequencerTimer = nil

        // Reset timing
        nextSampleTime = 0

        // Restart with new BPM
        startSequencer()
    }

    private func checkAndScheduleNotes() {
        // Safety check: ensure we're still playing
        guard isPlaying else { return }

        // Use sample-based timing for precision
        let samplesPerStep = AVAudioFramePosition(sampleRate * 60.0 / bpm / 4.0) // 16th notes
        let scheduleAhead: AVAudioFramePosition = 4410 // ~100ms lookahead at 44.1kHz

        // Get current sample time from last render
        let currentSampleTime: AVAudioFramePosition
        if let lastRenderTime = audioEngine.mainMixerNode.lastRenderTime {
            currentSampleTime = lastRenderTime.sampleTime
        } else {
            // If no render time available yet, use elapsed time estimation
            currentSampleTime = nextSampleTime
        }

        // Initialize nextSampleTime on first run
        if nextSampleTime == 0 && currentSampleTime > 0 {
            nextSampleTime = currentSampleTime
        }

        // Schedule all upcoming notes within the lookahead window
        while nextSampleTime < currentSampleTime + scheduleAhead {
            // Schedule notes for this step
            scheduleNotesForStep(currentStep, at: nextSampleTime)

            // Update UI on main thread (slightly ahead for visual feedback)
            let stepToDisplay = currentStep
            DispatchQueue.main.async {
                self.currentPlayingStep = stepToDisplay
            }

            // Advance to next step
            nextSampleTime += samplesPerStep
            let previousStep = currentStep
            currentStep = (currentStep + 1) % 16

            // Check if we've looped back to step 0 (end of sequence)
            if previousStep == 15 && currentStep == 0 {
                // Trigger continuous random for enabled tracks
                if continuousRandomEnabled[selectedInstrument] {
                    DispatchQueue.main.async {
                        self.randomizePattern()
                    }
                }
            }
        }
    }

    // Get next step for an instrument based on its sequence direction
    private func advanceInstrumentStep(_ instrument: Int) {
        let direction = sequenceDirections[instrument]
        let trackLength = trackLengths[instrument]

        print("🎵 Inst \(instrument): direction=\(direction) step=\(playbackSteps[instrument]) length=\(trackLength)")

        switch direction {
        case 0: // Forward
            playbackSteps[instrument] = (playbackSteps[instrument] + 1) % trackLength
        case 1: // Backward
            playbackSteps[instrument] = playbackSteps[instrument] - 1
            if playbackSteps[instrument] < 0 {
                playbackSteps[instrument] = trackLength - 1
            }
        case 2: // Pendulum
            if pendulumDirections[instrument] == 1 {
                // Going forward
                playbackSteps[instrument] += 1
                if playbackSteps[instrument] >= trackLength {
                    playbackSteps[instrument] = trackLength - 2
                    pendulumDirections[instrument] = -1  // Reverse direction
                    if playbackSteps[instrument] < 0 {
                        playbackSteps[instrument] = 0
                    }
                }
            } else {
                // Going backward
                playbackSteps[instrument] -= 1
                if playbackSteps[instrument] < 0 {
                    playbackSteps[instrument] = 1
                    pendulumDirections[instrument] = 1  // Reverse direction
                    if playbackSteps[instrument] >= trackLength {
                        playbackSteps[instrument] = trackLength - 1
                    }
                }
            }
        case 3: // Random
            playbackSteps[instrument] = Int.random(in: 0..<trackLength)
        default:
            playbackSteps[instrument] = (playbackSteps[instrument] + 1) % trackLength
        }
    }

    private func scheduleNotesForStep(_ step: Int, at sampleTime: AVAudioFramePosition) {
        // Play notes for all instruments at their individual steps
        for instrument in 0..<4 {
            let instrumentStep = playbackSteps[instrument]

            // Skip if this step is beyond the track's length
            if instrumentStep >= trackLengths[instrument] {
                continue
            }

            for row in 0..<8 {
                let key = "\(instrument)_\(row)_\(instrumentStep)"

                // Skip if this was just recorded to prevent double triggering
                if recentlyRecordedNotes.contains(key) {
                    continue
                }

                if self.instrumentSteps[key] == true {
                    if instrument == 3 {
                        // Drums - with pitch
                        let drumNote = drumRowToNote(row: row)
                        let pitch = getDrumPitch(row: row, col: instrumentStep)
                        playDrumSound(drumType: drumNote, pitch: pitch)
                    } else {
                        // Melodic instruments - use stored note or default
                        let baseNote = instrumentNotes[key] ?? rowToNote(row: row, instrument: instrument)
                        let octaveOffset = trackOctaveOffsets[instrument] * 12  // Apply per-track octave offset
                        let pitchOffset = Int(getMelodicPitch(row: row, col: instrumentStep, instrument: instrument))  // Apply per-step pitch offset
                        let note = baseNote + gridTranspose + octaveOffset + pitchOffset  // Apply all offsets

                        // Get per-step ADSR for this note
                        let stepADSR = getStepADSR(row: row, col: instrumentStep, instrument: instrument)
                        playNote(instrument: instrument, note: note, adsr: stepADSR)
                    }
                }
            }

            // Advance this instrument's step
            advanceInstrumentStep(instrument)

            // Update UI with selected instrument's current step
            if instrument == selectedInstrument {
                DispatchQueue.main.async {
                    self.currentInstrumentPlayingStep = self.playbackSteps[instrument]
                }
            }
        }
    }
    
    func rowToNote(row: Int, instrument: Int) -> Int {
        // Map grid row to MIDI note (8 rows)
        // Row 0 is at the top (highest note), Row 7 is at the bottom (lowest note)
        let scaleNotes: [Int]
        switch currentScale {
        case 0: scaleNotes = [0, 2, 4, 5, 7, 9, 11, 12] // Major
        case 1: scaleNotes = [0, 2, 3, 5, 7, 8, 10, 12] // Minor
        case 2: scaleNotes = [0, 2, 4, 7, 9, 12, 14, 16] // Pentatonic
        case 3: scaleNotes = [0, 3, 5, 6, 7, 10, 12, 15] // Blues
        case 4: scaleNotes = [0, 1, 2, 3, 4, 5, 6, 7]     // Chromatic
        default: scaleNotes = [0, 2, 4, 5, 7, 9, 11, 12]
        }

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

    // MARK: - Scale Management

    func changeScale(to newScale: Int) {
        currentScale = newScale
        // No need to update notes - they will play differently automatically
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

    func playNote(instrument: Int, note: Int, adsr: [Double]? = nil) {
        guard instrument < instruments.count else { return }

        // Update effects for the instrument being played
        updateTrackEffects(track: instrument)

        // Special handling for drums
        if instrument == 3 {
            // For drums, the note determines which drum sound to play
            playDrumSound(drumType: note)
        } else {
            // Use provided ADSR or fall back to track ADSR
            let effectiveADSR = adsr ?? trackADSR[instrument]

            // Regular instruments play notes normally (NO transpose here - it's already applied where needed)
            instruments[instrument].play(note: note, velocity: 127, adsr: effectiveADSR)

            // Schedule note off based on release time
            let releaseTime = effectiveADSR[3] // Get release time
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1 + releaseTime) {
                self.instruments[instrument].stop(note: note)
            }
        }
    }
    
    // Play specific drum sounds based on the note/track
    func playDrumSound(drumType: Int, pitch: Double = 1.0) {
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

        // Play the drum using the drums instrument with pitch
        instruments[3].playDrum(sound: drumSound, pitch: pitch)
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
            if Double.random(in: 0...1) < 0.8 { // 80% density
                // Pick a random row from the scale
                let row = scale.randomElement()!
                let key = "\(selectedInstrument)_\(row)_\(step)"
                instrumentSteps[key] = true
            }
        }
    }
    
    func selectPattern(_ index: Int) {
        guard index >= 0 && index < 8 else { return }
        
        if isDupMode {
            // Duplicate current pattern to selected slot
            patterns[index] = instrumentSteps
            patternNotes[index] = instrumentNotes
            patternVelocities[index] = instrumentVelocities
            isDupMode = false
            
            // Now switch to the duplicated pattern
            currentPatternSlot = index
        } else {
            // Save current pattern
            patterns[currentPatternSlot] = instrumentSteps
            patternNotes[currentPatternSlot] = instrumentNotes
            patternVelocities[currentPatternSlot] = instrumentVelocities
            
            // Load selected pattern
            currentPatternSlot = index
            instrumentSteps = patterns[index]
            instrumentNotes = patternNotes[index]
            instrumentVelocities = patternVelocities[index]
        }
    }
    
    func duplicatePattern() {
        isDupMode = true
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
    
    func getGridCellVelocity(row: Int, col: Int) -> Float {
        guard row >= 0 && row < 8 && col >= 0 && col < 16 else { return 0.8 }
        
        let key = "\(selectedInstrument)_\(row)_\(col)_vel"
        return instrumentVelocities[key] ?? 0.8 // Default velocity 80%
    }
    
    func setGridCellVelocity(row: Int, col: Int, velocity: Float) {
        guard row >= 0 && row < 8 && col >= 0 && col < 16 else { return }
        
        let key = "\(selectedInstrument)_\(row)_\(col)_vel"
        instrumentVelocities[key] = velocity
    }
    
    func showVelocityEditor(row: Int, col: Int) {
        // Cycle through velocity values: 0.2, 0.4, 0.6, 0.8, 1.0
        let currentVelocity = getGridCellVelocity(row: row, col: col)
        let velocityLevels: [Float] = [0.2, 0.4, 0.6, 0.8, 1.0]
        
        if let currentIndex = velocityLevels.firstIndex(of: currentVelocity) {
            let nextIndex = (currentIndex + 1) % velocityLevels.count
            setGridCellVelocity(row: row, col: col, velocity: velocityLevels[nextIndex])
        } else {
            setGridCellVelocity(row: row, col: col, velocity: 0.8)
        }
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
    // Store velocity values for each step
    private var instrumentVelocities: [String: Float] = [:]
    
    // MARK: - Effects Control
    
    private func setupEffects() {
        // Attach effects mixer
        audioEngine.attach(effectsMixer)

        // Create and attach delay
        delayNode = AVAudioUnitDelay()
        if let delay = delayNode {
            audioEngine.attach(delay)
            delay.delayTime = 0.0 // 0ms delay initially
            delay.feedback = 0    // 0% feedback
            delay.wetDryMix = 0   // Start with 0% wet (100% dry)
        }

        // Create and attach reverb
        reverbNode = AVAudioUnitReverb()
        if let reverb = reverbNode {
            audioEngine.attach(reverb)
            reverb.loadFactoryPreset(.mediumHall)
            reverb.wetDryMix = 0  // Start with 0% wet (100% dry)
        }

        // Connect effects chain - SIMPLIFIED: just delay and reverb
        let format = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 2)

        // Effects mixer -> Delay -> Reverb -> Main output
        if let delay = delayNode, let reverb = reverbNode {
            audioEngine.connect(effectsMixer, to: delay, format: format)
            audioEngine.connect(delay, to: reverb, format: format)
            audioEngine.connect(reverb, to: audioEngine.mainMixerNode, format: format)
        }
    }
    
    func updateTrackEffects(track: Int) {
        guard track >= 0 && track < 4 else { return }

        let effectAmounts = trackEffectAmounts[track]

        // Update effect parameters based on slider values for the specific track
        // Effect A: Tempo-synced Delay
        if let delay = delayNode {
            if effectAmounts[0] > 0.01 {
                // Musical delay synced to tempo
                let tempo = bpm / 60.0 // beats per second
                let delayBeats = 0.375 + (effectAmounts[0] * 0.125) // Dotted eighth to half note
                delay.delayTime = delayBeats / tempo
                delay.feedback = Float(35 + effectAmounts[0] * 40) // 35-75% feedback
                delay.wetDryMix = Float(effectAmounts[0] * 40) // 0-40% wet
                delay.lowPassCutoff = Float(1000 + effectAmounts[0] * 3000) // 1-4kHz filter
            } else {
                // Completely disable delay
                delay.delayTime = 0.0
                delay.feedback = 0
                delay.wetDryMix = 0
            }
        }

        // Effect B: Lush Reverb
        if let reverb = reverbNode {
            if effectAmounts[1] > 0.01 {
                reverb.wetDryMix = Float(effectAmounts[1] * 60) // 0-60% wet for spaciousness
            } else {
                reverb.wetDryMix = 0
            }
        }

        // Effect C & D: Placeholder for future effects
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
    
    // MARK: - Octave Control

    func increaseOctave(for track: Int) {
        guard track >= 0 && track < 4 else { return }
        if trackOctaveOffsets[track] < 2 {
            trackOctaveOffsets[track] += 1
        }
    }

    func decreaseOctave(for track: Int) {
        guard track >= 0 && track < 4 else { return }
        if trackOctaveOffsets[track] > -2 {
            trackOctaveOffsets[track] -= 1
        }
    }

    // MARK: - Drum Pitch Control

    func startDrumPitchEdit(row: Int, col: Int) {
        guard selectedInstrument == 3 else { return } // Only for drums
        isDrumPitchEditMode = true
        editingDrumStep = (row, col)

        // Load existing pitch for this step, or default to 1.0
        let key = "\(row)_\(col)"
        drumStepPitch = drumPitches[key] ?? 1.0

        // Load ADSR for this step
        loadStepADSR(row: row, col: col, instrument: selectedInstrument)
    }

    func stopDrumPitchEdit() {
        // Save the pitch before exiting
        if let step = editingDrumStep {
            let key = "\(step.row)_\(step.col)"
            drumPitches[key] = drumStepPitch
        }

        isDrumPitchEditMode = false
        editingDrumStep = nil
    }

    func getDrumPitch(row: Int, col: Int) -> Double {
        let key = "\(row)_\(col)"
        return drumPitches[key] ?? 1.0
    }

    func setDrumPitch(row: Int, col: Int, pitch: Double) {
        let key = "\(row)_\(col)"
        drumPitches[key] = pitch
        drumStepPitch = pitch
    }

    // MARK: - Melodic Pitch Control (STEP EDIT mode)

    func startMelodicStepEdit(row: Int, col: Int) {
        guard selectedInstrument != 3 else { return } // Not for drums
        guard isStepEditMode else { return } // Only in step edit mode

        editingStep = (row, col)

        // Load existing pitch offset for this step, or default to 0
        let key = "\(selectedInstrument)_\(row)_\(col)"
        stepPitch = melodicPitches[key] ?? 0.0

        // Load ADSR for this step
        loadStepADSR(row: row, col: col, instrument: selectedInstrument)
    }

    func stopMelodicStepEdit() {
        // Save the pitch offset before exiting
        if let step = editingStep {
            let key = "\(selectedInstrument)_\(step.row)_\(step.col)"
            // Round to nearest 12 (octave) for melodic instruments
            let roundedPitch = round(stepPitch / 12.0) * 12.0
            melodicPitches[key] = roundedPitch
        }

        editingStep = nil
    }

    func getMelodicPitch(row: Int, col: Int, instrument: Int) -> Double {
        let key = "\(instrument)_\(row)_\(col)"
        return melodicPitches[key] ?? 0.0
    }

    func setMelodicPitch(row: Int, col: Int, instrument: Int, pitch: Double) {
        let key = "\(instrument)_\(row)_\(col)"
        // Round to nearest octave
        let roundedPitch = round(pitch / 12.0) * 12.0
        melodicPitches[key] = roundedPitch
        stepPitch = roundedPitch
    }

    // MARK: - Per-Step ADSR Control (STEP EDIT mode)

    func getStepADSR(row: Int, col: Int, instrument: Int) -> [Double] {
        let key = "\(instrument)_\(row)_\(col)"
        // Return step-specific ADSR if it exists, otherwise return track default
        return stepADSR[key] ?? trackADSR[instrument]
    }

    func setStepADSR(row: Int, col: Int, instrument: Int, attack: Double, decay: Double, sustain: Double, release: Double) {
        let key = "\(instrument)_\(row)_\(col)"
        stepADSR[key] = [attack, decay, sustain, release]
        currentStepADSR = [attack, decay, sustain, release]
    }

    func loadStepADSR(row: Int, col: Int, instrument: Int) {
        // Load this step's ADSR into currentStepADSR
        currentStepADSR = getStepADSR(row: row, col: col, instrument: instrument)
    }

    // MARK: - Track Length Control (STEP EDIT mode)

    func setTrackLength(track: Int, length: Int) {
        guard track >= 0 && track < 4 else { return }
        guard [2, 4, 6, 8, 10, 12, 14, 16].contains(length) else { return }
        trackLengths[track] = length
    }

    // MARK: - Retrig Control (STEP EDIT mode)

    func cycleRetrigCount() {
        // Cycle through 1x, 2x, 3x
        currentRetrigCount = (currentRetrigCount % 3) + 1
    }

    func getRetrigCount(row: Int, col: Int, instrument: Int) -> Int {
        let key = "\(instrument)_\(row)_\(col)"
        return retrigCounts[key] ?? 1
    }

    func setRetrigCount(row: Int, col: Int, instrument: Int, count: Int) {
        guard [1, 2, 3].contains(count) else { return }
        let key = "\(instrument)_\(row)_\(col)"
        retrigCounts[key] = count
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
    
    // MARK: - Oscilloscope Support
    
    func generateOscilloscopeData() -> [Float] {
        var buffer: [Float] = []
        let samples = 100
        let waveformIndex = instrumentWaveforms[selectedInstrument]
        
        // Check if any notes are playing for the selected instrument
        let hasActiveNotes = instrumentSteps.contains(where: { key, value in
            let parts = key.split(separator: "_")
            if parts.count == 2, let instrument = Int(parts[0]) {
                return instrument == selectedInstrument && value
            }
            return false
        })
        
        if isPlaying && hasActiveNotes && currentPlayingStep >= 0 {
            // Generate waveform based on instrument type
            for i in 0..<samples {
                let phase = Double(i) * 0.15
                var value: Float = 0
                
                switch selectedInstrument {
                case 0, 1, 2: // Synth instruments
                    switch waveformIndex {
                    case 0: // Square wave
                        value = Float(sin(phase) > 0 ? 0.4 : -0.4)
                    case 1: // Sawtooth wave
                        value = Float((phase.truncatingRemainder(dividingBy: 2 * .pi) / .pi) - 1) * 0.4
                    case 2: // Triangle wave
                        let phase2 = phase.truncatingRemainder(dividingBy: 2 * .pi) / (2 * .pi)
                        value = Float(phase2 < 0.5 ? 4.0 * phase2 - 1.0 : 3.0 - 4.0 * phase2) * 0.4
                    case 3: // Sine wave
                        value = Float(sin(phase)) * 0.4
                    case 4: // Reverse sawtooth
                        value = Float(1.0 - 2.0 * (phase.truncatingRemainder(dividingBy: 2 * .pi) / (2 * .pi))) * 0.4
                    default:
                        value = Float(sin(phase)) * 0.4
                    }
                case 3: // Drums - percussive envelope
                    let envelope = Float(exp(-Double(i) * 0.08))
                    value = envelope * Float.random(in: -0.3...0.3)
                default:
                    value = 0
                }
                
                buffer.append(value)
            }
        } else {
            // Return flat line when not playing
            buffer = Array(repeating: 0, count: samples)
        }
        
        return buffer
    }
    
    // MARK: - Audio Buffer for Oscilloscope
    
    private func setupOscilloscopeTap() {
        // Remove any existing tap first
        audioEngine.mainMixerNode.removeTap(onBus: 0)
        
        // Install tap on the main mixer to capture audio output
        let bufferSize: AVAudioFrameCount = 1024
        let format = audioEngine.mainMixerNode.outputFormat(forBus: 0)
        
        // Only install tap if format is valid
        guard format.channelCount > 0 else { return }
        
        audioEngine.mainMixerNode.installTap(onBus: 0, bufferSize: bufferSize, format: format) { [weak self] buffer, _ in
            guard let self = self else { return }
            
            // Extract audio data from buffer
            if let channelData = buffer.floatChannelData {
                let channelCount = Int(buffer.format.channelCount)
                let frameLength = Int(buffer.frameLength)
                
                var samples: [Float] = []
                
                // Mix stereo to mono if needed
                for frame in 0..<frameLength {
                    var sum: Float = 0
                    for channel in 0..<channelCount {
                        sum += channelData[channel][frame]
                    }
                    samples.append(sum / Float(channelCount))
                }
                
                // Update oscilloscope buffer on main thread
                DispatchQueue.main.async {
                    self.oscilloscopeBuffer = samples
                }
            }
        }
    }
    
    func getAudioBuffer() -> [Float] {
        // Return the real audio buffer captured from the tap
        return oscilloscopeBuffer
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
        
        // Set instrument-specific mix levels for better balance
        switch type {
        case .synth:
            mixer.volume = 0.8  // Slightly quieter for lead
        case .bass:
            mixer.volume = 0.9  // Strong bass presence
        case .keys:
            mixer.volume = 0.7  // Softer for pads
        case .drums:
            mixer.volume = 1.0  // Full volume for punch
        }
        
        // Use a proper audio format
        let format = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 1)
        
        // Connect to effects mixer if available, otherwise main mixer
        if let parent = parentEngine {
            audioEngine.connect(mixer, to: parent.effectsMixer, format: format)
        } else {
            audioEngine.connect(mixer, to: audioEngine.mainMixerNode, format: format)
        }
    }
    
    private func getOrCreateBuffer(note: Int, velocity: Int, waveformIndex: Int, adsr: [Double]) -> AVAudioPCMBuffer? {
        // Include ADSR in cache key so different ADSR settings create different buffers
        let adsrKey = "\(Int(adsr[0]*1000))_\(Int(adsr[1]*1000))_\(Int(adsr[2]*1000))_\(Int(adsr[3]*1000))"
        let cacheKey = "\(type.rawValue)_\(note)_\(velocity)_\(waveformIndex)_\(adsrKey)"

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

        // Generate waveform with ADSR
        generateWaveform(data: data, frameCount: Int(frameCount), frequency: frequency, amplitude: amplitude, waveformIndex: waveformIndex, sampleRate: sampleRate, duration: duration, adsr: adsr)

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
    
    func play(note: Int, velocity: Int, adsr: [Double]? = nil) {
        setupMixerIfNeeded()

        // Get waveform index from parent engine
        let waveformIndex = parentEngine?.instrumentWaveforms[type.rawValue] ?? 0

        // Use provided ADSR or get track ADSR from parent engine
        let effectiveADSR = adsr ?? (parentEngine?.getTrackADSR(track: type.rawValue) ?? [0.01, 0.1, 0.8, 0.3])

        // Get or create buffer from cache
        guard let buffer = getOrCreateBuffer(note: note, velocity: velocity, waveformIndex: waveformIndex, adsr: effectiveADSR) else { return }

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
    
    private func generateWaveform(data: UnsafeMutablePointer<Float>, frameCount: Int, frequency: Double, amplitude: Float, waveformIndex: Int, sampleRate: Double, duration: Double, adsr: [Double]) {
        // Extract ADSR parameters from the passed array
        let attack = adsr[0]
        let decay = adsr[1]
        let sustain = Float(adsr[2])
        let release = adsr[3]

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

            // Apply ADSR envelope using the passed parameters
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
    
    // Sample buffers cache - organized by drum type and sample number
    // drumSamples[drumType][sampleIndex] = buffer
    // drumType: 0=Kick, 1=Snare, 2=Hat, 3=Perc
    private var drumSamples: [[AVAudioPCMBuffer]] = [[], [], [], []]

    private func loadDrumSamples() {
        print("🥁 Loading drum samples from DrumSamples folder...")

        // Load all kick samples (16 kicks, skipping #5 which doesn't exist)
        for i in 1...16 {
            if i == 5 { continue } // Skip kick_5.caf which doesn't exist
            if let url = Bundle.main.url(forResource: "kick_\(i)", withExtension: "caf") {
                if let buffer = loadAudioBuffer(from: url) {
                    drumSamples[0].append(buffer)
                    print("✅ Loaded kick_\(i).caf")
                }
            } else {
                print("❌ Could not find kick_\(i).caf in bundle")
            }
        }
        print("📊 Total kicks loaded: \(drumSamples[0].count)")

        // Load all snare samples (16 snares)
        for i in 1...16 {
            if let url = Bundle.main.url(forResource: "snare_\(i)", withExtension: "caf") {
                if let buffer = loadAudioBuffer(from: url) {
                    drumSamples[1].append(buffer)
                    print("✅ Loaded snare_\(i).caf")
                }
            } else {
                print("❌ Could not find snare_\(i).caf in bundle")
            }
        }
        print("📊 Total snares loaded: \(drumSamples[1].count)")

        // Load all hat samples (16 hats)
        for i in 1...16 {
            if let url = Bundle.main.url(forResource: "hat_\(i)", withExtension: "caf") {
                if let buffer = loadAudioBuffer(from: url) {
                    drumSamples[2].append(buffer)
                    print("✅ Loaded hat_\(i).caf")
                }
            } else {
                print("❌ Could not find hat_\(i).caf in bundle")
            }
        }
        print("📊 Total hats loaded: \(drumSamples[2].count)")

        // Load all perc samples (10 percs)
        for i in 1...10 {
            if let url = Bundle.main.url(forResource: "perc_\(i)", withExtension: "caf") {
                if let buffer = loadAudioBuffer(from: url) {
                    drumSamples[3].append(buffer)
                    print("✅ Loaded perc_\(i).caf")
                }
            } else {
                print("❌ Could not find perc_\(i).caf in bundle")
            }
        }
        print("📊 Total percs loaded: \(drumSamples[3].count)")
    }

    private func loadAudioBuffer(from url: URL) -> AVAudioPCMBuffer? {
        do {
            let file = try AVAudioFile(forReading: url)
            let format = file.processingFormat
            let frameCount = AVAudioFrameCount(file.length)

            if let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) {
                try file.read(into: buffer)
                return buffer
            }
        } catch {
            // print("Failed to load audio file \(url.lastPathComponent): \(error)")
        }
        return nil
    }
    
    // Play drum sounds (for drums instrument only)
    func playDrum(sound: Int, pitch: Double = 1.0) {
        guard type == .drums else { return }
        setupMixerIfNeeded()

        // Load samples if not already loaded
        if drumSamples.isEmpty || drumSamples.allSatisfy({ $0.isEmpty }) {
            print("🔄 Samples not loaded, loading now...")
            loadDrumSamples()
        }

        let playerNode = AVAudioPlayerNode()
        audioEngine.attach(playerNode)

        print("🎵 playDrum called with sound: \(sound), pitch: \(pitch)")

        // Only use samples for the 4 main drum types (0-3)
        // For other sounds (4-7), fall back to synthesis
        if sound >= 0 && sound < 4 && sound < drumSamples.count {
            // Get the selected sample index for this drum type from parent engine
            let sampleIndex = parentEngine?.selectedDrumSamples[sound] ?? 0
            print("   Selected sample index: \(sampleIndex) for drum type: \(sound)")
            print("   Available samples for this type: \(drumSamples[sound].count)")

            // Use sample if available
            if sampleIndex < drumSamples[sound].count {
                let sampleBuffer = drumSamples[sound][sampleIndex]
                print("   ✅ Playing sample \(sampleIndex) for drum \(sound) with pitch \(pitch)")

                // Apply pitch using rate (0.5 to 2.0)
                // rate < 1.0 = lower pitch/slower, rate > 1.0 = higher pitch/faster
                playerNode.rate = Float(pitch)

                // Play the actual sample
                let format = sampleBuffer.format
                audioEngine.connect(playerNode, to: mixer, format: format)
                playerNode.scheduleBuffer(sampleBuffer, at: nil, options: .interrupts, completionHandler: nil)
                playerNode.play()

                // Clean up after sample finishes (adjust duration for pitch)
                let duration = Double(sampleBuffer.frameLength) / format.sampleRate / pitch
                DispatchQueue.main.asyncAfter(deadline: .now() + duration + 0.1) {
                    playerNode.stop()
                    self.audioEngine.detach(playerNode)
                }
                return  // Exit early since we played the sample
            } else {
                print("   ❌ Sample index \(sampleIndex) out of range for drum type \(sound)")
            }
        } else {
            print("   ⚠️ Falling back to synthesis (sound \(sound) not in 0-3 range or no samples loaded)")
        }

        // Fall back to synthesis if no sample available or sound >= 4
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
