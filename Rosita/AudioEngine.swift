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
    
    // Track effects nodes (existing per-track effects)
    private var delayNode: AVAudioUnitDelay?
    private var reverbNode: AVAudioUnitReverb?
    private var chorusNode: AVAudioUnitEffect?
    private var flangerNode: AVAudioUnitEffect?
    var effectsMixer = AVAudioMixerNode() // Made accessible to instruments

    // Pre-allocated performance FX nodes (always in signal path, controlled via wet/dry)
    let perfDelay = AVAudioUnitDelay()
    let perfReverb = AVAudioUnitReverb()
    let perfDistortion = AVAudioUnitDistortion()
    let perfTimePitch = AVAudioUnitTimePitch()
    let perfVarispeed = AVAudioUnitVarispeed()
    let perfEQ = AVAudioUnitEQ(numberOfBands: 10)

    // Effect preset system
    struct EffectPreset {
        let name: String
        let category: String
        // Delay parameters
        let delayTime: TimeInterval
        let delayFeedback: Float
        let delayMix: Float
        // Reverb parameters
        let reverbPreset: AVAudioUnitReverbPreset
        let reverbMix: Float
        // Distortion parameters
        let distortionPreset: AVAudioUnitDistortionPreset
        let distortionMix: Float
        // Time/Pitch parameters
        let pitch: Float  // Semitones
        let timePitchRate: Float
        let varispeedRate: Float
        // EQ parameters (simplified - bass/mid/treble)
        let eqBass: Float  // dB at 100Hz
        let eqMid: Float   // dB at 1kHz
        let eqTreble: Float  // dB at 10kHz
        // Master mix (how much to blend dry vs wet signal)
        let masterMix: Float  // 0.0 = dry, 1.0 = full wet
    }

    // 128 performance FX presets (8 categories × 16 variations)
    lazy var effectPresets: [EffectPreset] = self.buildEffectPresets()

    // Sequencer - High-precision audio-thread scheduling
    private var sequencerTimer: DispatchSourceTimer?
    private var currentStep = 0
    private var playbackSteps = [0, 0, 0, 0]  // Per-instrument playback step counters
    private var pendulumDirections = [1, 1, 1, 1]  // 1=forward, -1=backward for pendulum mode
    private var trackStepCounters = [0, 0, 0, 0]  // Counters for track speed implementation
    private var nextSampleTime: AVAudioFramePosition = 0
    private var isFirstScheduleTick = true  // Flag to handle initial timing correctly
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

    // FX Grid Controls
    @Published var activeFXPitchRow: Int? = nil  // Column 0: Pitch control (+12 to -12)
    @Published var activeFXFilterRow: Int? = nil  // Column 1: Low pass filter (open to closed)

    // Drum sample selection (which sample variant is selected for each drum type)
    @Published var selectedDrumSamples = [0, 0, 0, 0] // [kick, snare, hat, perc]

    // Drum kit system - 16 kits, each storing 4 sound indices
    @Published var currentKitIndex = 0 // Currently selected kit (0-15)
    @Published var drumKits: [[Int]] = {
        // Initialize 16 kits with default sounds [0, 0, 0, 0]
        var kits = [[Int]]()
        for _ in 0..<16 {
            kits.append([0, 0, 0, 0]) // Default: first sample for each drum type
        }
        return kits
    }()

    // Continuous random mode - per track
    @Published var continuousRandomEnabled = [false, false, false, false]  // One for each instrument

    // Sequence direction - per track (0=Forward, 1=Backward, 2=Pendulum, 3=Random)
    @Published var sequenceDirections = [0, 0, 0, 0]  // One for each instrument

    // Track speed/scale - per track (0=1/2x, 1=1x, 2=2x, 3=4x)
    @Published var trackSpeeds = [1, 1, 1, 1]  // Default to 1x (normal speed)

    // Mute state - per track (melodic: 0-2, drums: 3, individual drum rows: 0-3 within drums)
    @Published var trackMuted = [false, false, false, false]  // Melodic tracks 1-3 + drums track
    @Published var drumRowsMuted = [false, false, false, false]  // Individual drum rows: Kick, Snare, Hat, Perc
    @Published var allDrumsMuted = false  // Master mute for all drums

    // Solo state - which track is soloed (0-7 for buttons 1-8, nil if none)
    @Published var soloedTrack: Int? = nil

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

    // Multi-select in step edit mode
    @Published var selectedSteps: Set<String> = [] // Set of "row_col" keys for selected steps

    // Scale selection mode (activated by tap on SCALE button)
    @Published var isScaleSelectionMode = false
    @Published var isScaleSelectionLocked = false  // Green border, stays open until scale button pressed again

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
        trackStepCounters = [0, 0, 0, 0]  // Reset track speed counters
        currentInstrumentPlayingStep = 0  // Initialize playback cursor to step 1 (index 0)
        isFirstScheduleTick = true  // Reset first tick flag
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
            if isFirstScheduleTick {
                // On the very first tick, start ahead by one step duration
                // This prevents rushing through multiple steps on startup
                nextSampleTime = currentSampleTime + samplesPerStep
                isFirstScheduleTick = false
            } else {
                nextSampleTime = currentSampleTime
            }
        }

        // Schedule all upcoming notes within the lookahead window
        while nextSampleTime < currentSampleTime + scheduleAhead {
            // Schedule notes for this step
            scheduleNotesForStep(currentStep, at: nextSampleTime)

            // Update UI immediately for the FIRST scheduled step (the one actually playing now)
            // This ensures step 0 doesn't get skipped visually
            if nextSampleTime <= currentSampleTime + samplesPerStep {
                let stepToDisplay = currentStep
                DispatchQueue.main.async {
                    self.currentPlayingStep = stepToDisplay
                }
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
            let speedIndex = trackSpeeds[instrument]

            // Determine how many times to trigger this instrument on this global step
            var triggerCount = 1
            var shouldTrigger = true

            switch speedIndex {
            case 0: // 1/2x speed - trigger every 2 global steps
                trackStepCounters[instrument] += 1
                shouldTrigger = (trackStepCounters[instrument] % 2 == 0)
            case 1: // 1x speed - normal, trigger every global step
                triggerCount = 1
            case 2: // 2x speed - trigger twice per global step
                triggerCount = 2
            case 3: // 4x speed - trigger 4 times per global step
                triggerCount = 4
            default:
                triggerCount = 1
            }

            if !shouldTrigger {
                continue
            }

            // Execute trigger(s) based on speed
            for _ in 0..<triggerCount {
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
                        // Check mute state
                        var isMuted = trackMuted[instrument]

                        // Check solo state
                        if let soloed = soloedTrack {
                            // Solo mode is active
                            if instrument == 3 {
                                // Drums
                                if soloed == 7 {
                                    // Button 8 (index 7) = all drums soloed, so drums are not muted
                                    isMuted = false
                                } else if soloed >= 3 && soloed <= 6 {
                                    // Buttons 4-7 (indices 3-6) = individual drum rows
                                    let soloedDrumRow = soloed - 3
                                    isMuted = (row != soloedDrumRow)
                                } else {
                                    // Melodic track is soloed, mute all drums
                                    isMuted = true
                                }
                            } else {
                                // Melodic instruments (0-2)
                                isMuted = (instrument != soloed)
                            }
                        } else {
                            // No solo - use normal mute logic
                            if instrument == 3 {
                                // Drums - check both all drums mute and individual drum row mute
                                isMuted = isMuted || allDrumsMuted || (row < 4 && drumRowsMuted[row])
                            }
                        }

                        if instrument == 3 {

                            if !isMuted {
                                let drumNote = drumRowToNote(row: row)
                                let pitch = getDrumPitch(row: row, col: instrumentStep)
                                playDrumSound(drumType: drumNote, pitch: pitch)
                            }
                        } else {
                            // Melodic instruments
                            if !isMuted {
                                let baseNote = instrumentNotes[key] ?? rowToNote(row: row, instrument: instrument)
                                let octaveOffset = trackOctaveOffsets[instrument] * 12  // Apply per-track octave offset
                                let pitchOffset = Int(getMelodicPitch(row: row, col: instrumentStep, instrument: instrument))  // Apply per-step pitch offset
                                let fxPitchOffset = getFXPitchOffset()  // Apply FX pitch control from column 0
                                let note = baseNote + gridTranspose + octaveOffset + pitchOffset + fxPitchOffset  // Apply all offsets

                                // Get per-step ADSR for this note
                                let stepADSR = getStepADSR(row: row, col: instrumentStep, instrument: instrument)
                                playNote(instrument: instrument, note: note, adsr: stepADSR)
                            }
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

    // Map keyboard key index (0-23 for 24 keys) to scale note
    func keyboardIndexToScaleNote(index: Int) -> Int {
        let scaleNotes: [Int]
        switch currentScale {
        case 0: scaleNotes = [0, 2, 4, 5, 7, 9, 11, 12] // Major
        case 1: scaleNotes = [0, 2, 3, 5, 7, 8, 10, 12] // Minor
        case 2: scaleNotes = [0, 2, 4, 7, 9, 12, 14, 16] // Pentatonic
        case 3: scaleNotes = [0, 3, 5, 6, 7, 10, 12, 15] // Blues
        case 4: scaleNotes = [0, 1, 2, 3, 4, 5, 6, 7]     // Chromatic
        case 5: scaleNotes = [0, 2, 3, 5, 7, 9, 10, 12] // Dorian
        case 6: scaleNotes = [0, 2, 4, 5, 7, 9, 10, 12] // Mixolydian
        case 7: scaleNotes = [0, 2, 3, 5, 7, 8, 11, 12] // Harmonic Minor
        default: scaleNotes = [0, 2, 4, 5, 7, 9, 11, 12]
        }

        // Map key index to scale degree
        // Each octave has 8 scale degrees
        let octaveOffset = (index / 8) * 12  // Which octave (0, 12, 24)
        let scaleIndex = index % 8           // Which degree within the scale (0-7)
        let noteOffset = scaleNotes[scaleIndex]

        let baseNote = 60 // C4
        return baseNote + noteOffset + octaveOffset
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

    // MARK: - Drum Kit Management

    // Select a kit and load its sounds
    func selectKit(_ kitIndex: Int) {
        guard kitIndex >= 0 && kitIndex < 16 else { return }
        currentKitIndex = kitIndex
        // Load this kit's sounds into selectedDrumSamples
        selectedDrumSamples = drumKits[kitIndex]
    }

    // Update a specific drum sound for the current kit
    func updateCurrentKitSound(drumType: Int, sampleIndex: Int) {
        guard drumType >= 0 && drumType < 4 else { return }
        // Update the kit's sound
        drumKits[currentKitIndex][drumType] = sampleIndex
        // Update selectedDrumSamples to reflect the change
        selectedDrumSamples[drumType] = sampleIndex
    }

    // Get the current kit's sounds
    func getCurrentKitSounds() -> [Int] {
        return drumKits[currentKitIndex]
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
            // Save current pattern to its own slot first (IMPORTANT!)
            patterns[currentPatternSlot] = instrumentSteps
            patternNotes[currentPatternSlot] = instrumentNotes
            patternVelocities[currentPatternSlot] = instrumentVelocities

            // Now duplicate current pattern to selected slot
            patterns[index] = instrumentSteps
            patternNotes[index] = instrumentNotes
            patternVelocities[index] = instrumentVelocities
            isDupMode = false

            // Switch to the duplicated pattern
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

        // Track effects: effectsMixer -> Delay -> Reverb -> Performance FX chain -> Main
        // Single path architecture - use performance FX wet/dry controls for bypass
        if let delay = delayNode, let reverb = reverbNode {
            audioEngine.connect(effectsMixer, to: delay, format: format)
            audioEngine.connect(delay, to: reverb, format: format)

            // Attach performance effect nodes
            audioEngine.attach(perfDelay)
            audioEngine.attach(perfReverb)
            audioEngine.attach(perfDistortion)
            audioEngine.attach(perfTimePitch)
            audioEngine.attach(perfVarispeed)
            audioEngine.attach(perfEQ)

            // Single path: reverb → performance FX chain → main
            // Performance FX always connected, controlled via wet/dry mix
            audioEngine.connect(reverb, to: perfDelay, format: format)
            audioEngine.connect(perfDelay, to: perfReverb, format: format)
            audioEngine.connect(perfReverb, to: perfDistortion, format: format)
            audioEngine.connect(perfDistortion, to: perfTimePitch, format: format)
            audioEngine.connect(perfTimePitch, to: perfVarispeed, format: format)
            audioEngine.connect(perfVarispeed, to: perfEQ, format: format)
            audioEngine.connect(perfEQ, to: audioEngine.mainMixerNode, format: format)

            // Initialize performance effects to 100% dry (bypass) - no processing
            perfDelay.delayTime = 0.0
            perfDelay.feedback = 0
            perfDelay.wetDryMix = 0  // 0% wet = 100% dry = bypass

            perfReverb.loadFactoryPreset(.smallRoom)
            perfReverb.wetDryMix = 0  // 0% wet = bypass

            perfDistortion.loadFactoryPreset(.drumsBitBrush)
            perfDistortion.wetDryMix = 0  // 0% wet = bypass

            perfTimePitch.pitch = 0
            perfTimePitch.rate = 1.0

            perfVarispeed.rate = 1.0
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

    // Convenience functions for current track
    func increaseTrackOctave() {
        increaseOctave(for: selectedInstrument)
    }

    func decreaseTrackOctave() {
        decreaseOctave(for: selectedInstrument)
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

    // MARK: - Multi-Select Step Functions

    func toggleStepSelection(row: Int, col: Int) {
        let key = "\(row)_\(col)"
        if selectedSteps.contains(key) {
            selectedSteps.remove(key)
        } else {
            selectedSteps.insert(key)
        }
    }

    func isStepSelected(row: Int, col: Int) -> Bool {
        let key = "\(row)_\(col)"
        return selectedSteps.contains(key)
    }

    func clearStepSelection() {
        selectedSteps.removeAll()
    }

    func selectAllActiveSteps() {
        // Select all active steps in the current instrument's pattern
        selectedSteps.removeAll()

        for row in 0..<8 {
            for col in 0..<16 {
                if getGridCell(row: row, col: col) {
                    let key = "\(row)_\(col)"
                    selectedSteps.insert(key)
                }
            }
        }
    }

    func adjustSelectedStepsOctave(by semitones: Int) {
        guard !selectedSteps.isEmpty else { return }

        // Adjust pitch for all selected steps
        for stepKey in selectedSteps {
            let components = stepKey.split(separator: "_")
            guard components.count == 2,
                  let row = Int(components[0]),
                  let col = Int(components[1]) else { continue }

            let key = "\(selectedInstrument)_\(row)_\(col)"
            let currentPitch = melodicPitches[key] ?? 0.0
            let newPitch = currentPitch + Double(semitones)

            // Clamp to reasonable range (-24 to +24 semitones)
            let clampedPitch = max(-24.0, min(24.0, newPitch))
            melodicPitches[key] = clampedPitch
        }
    }

    func resetSelectedStepsPitch() {
        guard !selectedSteps.isEmpty else { return }

        // Reset pitch to 0 for all selected steps
        for stepKey in selectedSteps {
            let components = stepKey.split(separator: "_")
            guard components.count == 2,
                  let row = Int(components[0]),
                  let col = Int(components[1]) else { continue }

            let key = "\(selectedInstrument)_\(row)_\(col)"
            melodicPitches[key] = 0.0
        }
    }

    func getAverageSelectedStepsPitch() -> Int {
        guard !selectedSteps.isEmpty else { return 0 }

        var totalPitch: Double = 0.0
        var count = 0

        for stepKey in selectedSteps {
            let components = stepKey.split(separator: "_")
            guard components.count == 2,
                  let row = Int(components[0]),
                  let col = Int(components[1]) else { continue }

            let key = "\(selectedInstrument)_\(row)_\(col)"
            totalPitch += melodicPitches[key] ?? 0.0
            count += 1
        }

        return count > 0 ? Int(totalPitch / Double(count)) : 0
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

            // Store the actual note played (what the user heard)
            // This ensures the recorded note sounds the same as when it was played
            instrumentNotes[key] = note

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

                // Store the actual note played (what the user heard)
                instrumentNotes[key] = note
                
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

    // MARK: - Performance FX Presets

    private func buildEffectPresets() -> [EffectPreset] {
        // BETTER THAN POLYEND PLAY: 16 columns × 8 rows = 128 distinct, musical effects
        // Each column is a unique effect type, 8 variations going DOWN
        var presets = Array(repeating: EffectPreset(name: "", category: "", delayTime: 0, delayFeedback: 0, delayMix: 0, reverbPreset: .smallRoom, reverbMix: 0, distortionPreset: .multiEcho1, distortionMix: 0, pitch: 0, timePitchRate: 1.0, varispeedRate: 1.0, eqBass: 0, eqMid: 0, eqTreble: 0, masterMix: 0.5), count: 128)

        let distortions: [AVAudioUnitDistortionPreset] = [.drumsBitBrush, .drumsBufferBeats, .drumsLoFi, .multiBrokenSpeaker, .multiCellphoneConcert, .multiDecimated1, .multiDecimated2, .multiDecimated3]
        let rooms: [AVAudioUnitReverbPreset] = [.smallRoom, .smallRoom, .mediumRoom, .mediumRoom, .mediumHall, .mediumHall, .mediumChamber, .mediumChamber]
        let halls: [AVAudioUnitReverbPreset] = [.mediumHall, .mediumHall2, .largeHall, .largeHall2, .plate, .plate, .cathedral, .cathedral]

        for col in 0..<16 {
            for row in 0..<8 {
                let idx = row * 16 + col
                let t = Float(row) / 7.0

                switch col {
                // RED COLUMNS (0-1): TUNE/PITCH
                case 0: // Pitch Down (-12 to -1)
                    presets[idx] = EffectPreset(name: "Dn\(12-row)", category: "Tune", delayTime: 0, delayFeedback: 0, delayMix: 0, reverbPreset: .smallRoom, reverbMix: 0.05, distortionPreset: .multiEcho1, distortionMix: 0, pitch: Float(-12 + row), timePitchRate: 1.0, varispeedRate: 1.0, eqBass: 0, eqMid: 0, eqTreble: 0, masterMix: 0.8)

                case 1: // Pitch Up (+1 to +8)
                    presets[idx] = EffectPreset(name: "Up\(row+1)", category: "Tune", delayTime: 0, delayFeedback: 0, delayMix: 0, reverbPreset: .smallRoom, reverbMix: 0.05, distortionPreset: .multiEcho1, distortionMix: 0, pitch: Float(row + 1), timePitchRate: 1.0, varispeedRate: 1.0, eqBass: 0, eqMid: 0, eqTreble: 0, masterMix: 0.8)

                // ORANGE COLUMNS (2-3): FILTERS
                case 2: // Low-Pass (bright to dark)
                    presets[idx] = EffectPreset(name: "LP\(row+1)", category: "Filter", delayTime: 0, delayFeedback: 0, delayMix: 0, reverbPreset: .smallRoom, reverbMix: 0, distortionPreset: .drumsLoFi, distortionMix: 0.1, pitch: 0, timePitchRate: 1.0, varispeedRate: 1.0, eqBass: 0, eqMid: -5 - t * 10, eqTreble: -15 - t * 10, masterMix: 0.75)

                case 3: // High-Pass (full to thin)
                    presets[idx] = EffectPreset(name: "HP\(row+1)", category: "Filter", delayTime: 0, delayFeedback: 0, delayMix: 0, reverbPreset: .smallRoom, reverbMix: 0, distortionPreset: .multiEcho1, distortionMix: 0, pitch: 0, timePitchRate: 1.0, varispeedRate: 1.0, eqBass: -15 - t * 10, eqMid: -5 - t * 5, eqTreble: 5, masterMix: 0.75)

                // YELLOW COLUMNS (4-5): OVERDRIVE/DISTORTION
                case 4: // Light Saturation
                    presets[idx] = EffectPreset(name: "Sat\(row+1)", category: "Drive", delayTime: 0, delayFeedback: 0, delayMix: 0, reverbPreset: .smallRoom, reverbMix: 0, distortionPreset: distortions[row], distortionMix: 0.15 + t * 0.35, pitch: 0, timePitchRate: 1.0, varispeedRate: 1.0, eqBass: 0, eqMid: 0, eqTreble: 0, masterMix: 0.7)

                case 5: // Heavy Distortion/Bitcrush
                    presets[idx] = EffectPreset(name: "Crush\(row+1)", category: "Drive", delayTime: 0, delayFeedback: 0, delayMix: 0, reverbPreset: .smallRoom, reverbMix: 0, distortionPreset: distortions[row], distortionMix: 0.5 + t * 0.5, pitch: 0, timePitchRate: 1.0, varispeedRate: 1.0, eqBass: 0, eqMid: 0, eqTreble: -5 - t * 10, masterMix: 0.75 + t * 0.2)

                // GREEN COLUMNS (6-7): REARRANGE/TIME MANIPULATION
                case 6: // Slow Down (varispeed)
                    presets[idx] = EffectPreset(name: "Slow\(row+1)", category: "Rearrange", delayTime: 0, delayFeedback: 0, delayMix: 0, reverbPreset: .smallRoom, reverbMix: 0, distortionPreset: .multiEcho1, distortionMix: 0, pitch: 0, timePitchRate: 1.0, varispeedRate: 1.0 - t * 0.7, eqBass: 0, eqMid: 0, eqTreble: -5 - t * 10, masterMix: 0.9)

                case 7: // Speed Up (varispeed)
                    presets[idx] = EffectPreset(name: "Fast\(row+1)", category: "Rearrange", delayTime: 0, delayFeedback: 0, delayMix: 0, reverbPreset: .smallRoom, reverbMix: 0, distortionPreset: .multiEcho1, distortionMix: 0, pitch: 0, timePitchRate: 1.0, varispeedRate: 1.0 + t * 2.5, eqBass: 0, eqMid: 0, eqTreble: 5 + t * 10, masterMix: 0.9)

                // CYAN COLUMNS (8-9): REPEAT/STUTTER
                case 8: // Short Stutter (tight repeats)
                    presets[idx] = EffectPreset(name: "Stut\(row+1)", category: "Repeat", delayTime: 0.01 + Double(t) * 0.04, delayFeedback: 0.7 + t * 0.25, delayMix: 0.6 + t * 0.3, reverbPreset: .smallRoom, reverbMix: 0, distortionPreset: .multiEcho1, distortionMix: 0, pitch: 0, timePitchRate: 1.0, varispeedRate: 1.0, eqBass: 0, eqMid: 0, eqTreble: 0, masterMix: 0.8)

                case 9: // Rhythmic Repeat (tempo-synced)
                    presets[idx] = EffectPreset(name: "Rpt\(row+1)", category: "Repeat", delayTime: 0.08 + Double(t) * 0.16, delayFeedback: 0.8, delayMix: 0.65, reverbPreset: .smallRoom, reverbMix: 0.1, distortionPreset: .multiEcho1, distortionMix: 0, pitch: 0, timePitchRate: 1.0, varispeedRate: 1.0, eqBass: 0, eqMid: -3, eqTreble: -5, masterMix: 0.75)

                // VIOLET COLUMNS (10-11): DELAY
                case 10: // Clean Echo
                    presets[idx] = EffectPreset(name: "Echo\(row+1)", category: "Delay", delayTime: 0.06 + Double(t) * 1.0, delayFeedback: 0.2 + t * 0.5, delayMix: 0.4 + t * 0.4, reverbPreset: .smallRoom, reverbMix: 0, distortionPreset: .multiEcho1, distortionMix: 0, pitch: 0, timePitchRate: 1.0, varispeedRate: 1.0, eqBass: 0, eqMid: 0, eqTreble: 0, masterMix: 0.65 + t * 0.25)

                case 11: // Tape Echo (warm/degraded)
                    presets[idx] = EffectPreset(name: "Tape\(row+1)", category: "Delay", delayTime: 0.08 + Double(t) * 0.7, delayFeedback: 0.4 + t * 0.4, delayMix: 0.5, reverbPreset: .smallRoom, reverbMix: 0.15, distortionPreset: .drumsLoFi, distortionMix: 0.2 + t * 0.2, pitch: 0, timePitchRate: 1.0, varispeedRate: 1.0, eqBass: -5, eqMid: -5 - t * 5, eqTreble: -10 - t * 10, masterMix: 0.7)

                // PURPLE COLUMNS (12-13): REVERB
                case 12: // Small Spaces
                    presets[idx] = EffectPreset(name: "Room\(row+1)", category: "Reverb", delayTime: 0, delayFeedback: 0, delayMix: 0, reverbPreset: rooms[row], reverbMix: 0.25 + t * 0.5, distortionPreset: .multiEcho1, distortionMix: 0, pitch: 0, timePitchRate: 1.0, varispeedRate: 1.0, eqBass: 0, eqMid: 0, eqTreble: 0, masterMix: 0.5 + t * 0.4)

                case 13: // Large Spaces
                    presets[idx] = EffectPreset(name: "Hall\(row+1)", category: "Reverb", delayTime: 0, delayFeedback: 0, delayMix: 0, reverbPreset: halls[row], reverbMix: 0.35 + t * 0.55, distortionPreset: .multiEcho1, distortionMix: 0, pitch: 0, timePitchRate: 1.0, varispeedRate: 1.0, eqBass: 0, eqMid: 0, eqTreble: 0, masterMix: 0.6 + t * 0.35)

                // PINK COLUMNS (14-15): LOOP/GRANULAR
                case 14: // Shimmer (reverb + pitch up)
                    presets[idx] = EffectPreset(name: "Shim\(row+1)", category: "Loop", delayTime: 0, delayFeedback: 0, delayMix: 0, reverbPreset: .largeHall2, reverbMix: 0.65 + t * 0.3, distortionPreset: .multiEcho1, distortionMix: 0, pitch: Float(row * 2), timePitchRate: 1.0, varispeedRate: 1.0, eqBass: 0, eqMid: 0, eqTreble: 8 + t * 10, masterMix: 0.75)

                case 15: // Scatter/Granular (wild delays + pitch)
                    let scatterPitches: [Float] = [-12, -7, -5, 0, 3, 5, 7, 12]
                    presets[idx] = EffectPreset(name: "Scatter\(row+1)", category: "Loop", delayTime: 0.02 + Double(sin(Double(t) * .pi)) * 0.35, delayFeedback: 0.7 + t * 0.2, delayMix: 0.7, reverbPreset: [.largeHall2, .cathedral, .plate][row % 3], reverbMix: 0.45 + t * 0.4, distortionPreset: distortions[row], distortionMix: 0.2, pitch: scatterPitches[row], timePitchRate: 1.0, varispeedRate: 0.6 + t * 2.4, eqBass: Float(sin(Double(row) * .pi / 3) * 12), eqMid: 0, eqTreble: Float(cos(Double(row) * .pi / 3) * 12), masterMix: 0.85 + t * 0.15)

                default:
                    break
                }
            }
        }

        return presets
    }

    // Activate a performance FX preset
    func activatePerformanceFX(presetIndex: Int) {
        guard presetIndex >= 0 && presetIndex < effectPresets.count else { return }

        let preset = effectPresets[presetIndex]

        // Update activePerformanceFX state
        activePerformanceFX = presetIndex

        // Apply effect parameters immediately (audio thread-safe)
        applyPresetParameters(preset)
    }

    // Deactivate performance FX (return to dry/bypass)
    func deactivatePerformanceFX() {
        activePerformanceFX = nil

        // Bypass all performance FX nodes by setting wetDryMix to 0 (100% dry)
        perfDelay.wetDryMix = 0
        perfReverb.wetDryMix = 0
        perfDistortion.wetDryMix = 0
        // TimePitch and Varispeed don't have wetDryMix, reset to neutral
        perfTimePitch.pitch = 0
        perfTimePitch.rate = 1.0
        perfVarispeed.rate = 1.0
        // Reset EQ
        if perfEQ.bands.count >= 10 {
            for i in 0..<10 {
                perfEQ.bands[i].bypass = true
            }
        }
    }

    // Get FX pitch offset from active row
    // Row 0 = +12 semitones, Row 7 = -12 semitones, linear interpolation
    func getFXPitchOffset() -> Int {
        guard let row = activeFXPitchRow else { return 0 }
        // Map row 0-7 to +12 to -12 semitones
        // row 0 → +12
        // row 7 → -12
        // Formula: pitch = 12 - (row * 3)
        let pitch = 12 - (row * 3)
        return pitch
    }

    // Apply low pass filter based on row
    // Row 0 = fully open (20kHz), Row 7 = closed (200Hz)
    func applyLowPassFilter(row: Int) {
        guard perfEQ.bands.count >= 10 else { return }

        // Map row 0-7 to cutoff frequency (20000Hz to 200Hz)
        // Logarithmic scaling for more natural sound
        let minFreq: Float = 200.0   // Row 7 - very muffled
        let maxFreq: Float = 20000.0 // Row 0 - fully open

        // Invert row so row 0 = high freq, row 7 = low freq
        let normalizedRow = Float(7 - row) / 7.0

        // Logarithmic interpolation
        let logMin = log10(minFreq)
        let logMax = log10(maxFreq)
        let logFreq = logMin + (logMax - logMin) * normalizedRow
        let cutoffFreq = pow(10, logFreq)

        // Apply low pass filter using EQ band 9 (highest frequency band)
        perfEQ.bands[9].filterType = .lowPass
        perfEQ.bands[9].frequency = cutoffFreq
        perfEQ.bands[9].bandwidth = 0.5
        perfEQ.bands[9].bypass = false
        perfEQ.bands[9].gain = 0
    }

    // Clear low pass filter
    func clearLowPassFilter() {
        guard perfEQ.bands.count >= 10 else { return }
        perfEQ.bands[9].bypass = true
    }

    // Apply all effect parameters from a preset
    private func applyPresetParameters(_ preset: EffectPreset) {
        // Delay
        perfDelay.delayTime = preset.delayTime
        perfDelay.feedback = preset.delayFeedback * 100
        perfDelay.wetDryMix = preset.delayMix * 100

        // Reverb
        perfReverb.loadFactoryPreset(preset.reverbPreset)
        perfReverb.wetDryMix = preset.reverbMix * 100

        // Distortion
        perfDistortion.loadFactoryPreset(preset.distortionPreset)
        perfDistortion.wetDryMix = preset.distortionMix * 100

        // Pitch/Time
        perfTimePitch.pitch = preset.pitch
        perfTimePitch.rate = preset.timePitchRate
        perfVarispeed.rate = preset.varispeedRate

        // EQ (10-band EQ: bass at band 0, mid at band 5, treble at band 9)
        if perfEQ.bands.count >= 10 {
            // Bass (100Hz)
            perfEQ.bands[0].frequency = 100
            perfEQ.bands[0].gain = preset.eqBass
            perfEQ.bands[0].filterType = .parametric
            perfEQ.bands[0].bypass = false

            // Mid (1kHz)
            perfEQ.bands[5].frequency = 1000
            perfEQ.bands[5].gain = preset.eqMid
            perfEQ.bands[5].filterType = .parametric
            perfEQ.bands[5].bypass = false

            // Treble (10kHz)
            perfEQ.bands[9].frequency = 10000
            perfEQ.bands[9].gain = preset.eqTreble
            perfEQ.bands[9].filterType = .parametric
            perfEQ.bands[9].bypass = false
        }
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
