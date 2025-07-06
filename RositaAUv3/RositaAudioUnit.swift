import AudioToolbox
import AVFoundation
import CoreAudioKit

public class RositaAudioUnit: AUAudioUnit {
    private var _currentMIDIVelocity: UInt8 = 127
    private var _inputBusArray: AUAudioUnitBusArray?
    private var _outputBusArray: AUAudioUnitBusArray?
    
    // Audio format
    private var format: AVAudioFormat
    
    // DSP state
    private var sampleRate: Double = 44100.0
    private var currentStep = 0
    private var stepCounter = 0
    private var isPlaying = false
    private var bpm: Double = 120.0
    
    // Grid state (8 tracks x 16 steps)
    private var grid: [[Bool]] = Array(repeating: Array(repeating: false, count: 16), count: 8)
    
    // Simple oscillators for each track
    private var trackPhases: [Double] = Array(repeating: 0.0, count: 8)
    private var trackEnvelopes: [Double] = Array(repeating: 0.0, count: 8)
    private var trackTriggers: [Bool] = Array(repeating: false, count: 8)
    
    // Initialize with default format
    public override init(componentDescription: AudioComponentDescription,
                         options: AudioComponentInstantiationOptions = []) throws {
        self.format = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 2)!
        
        try super.init(componentDescription: componentDescription, options: options)
        
        // Create the output bus
        let outputBus = try AUAudioUnitBus(format: format)
        self._outputBusArray = AUAudioUnitBusArray(audioUnit: self,
                                                   busType: .output,
                                                   busses: [outputBus])
        
        // Set default pattern (basic drum beat)
        grid[0][0] = true  // Kick on 1
        grid[0][4] = true  // Kick on 2
        grid[0][8] = true  // Kick on 3
        grid[0][12] = true // Kick on 4
        grid[1][4] = true  // Snare on 2
        grid[1][12] = true // Snare on 4
        
        self.maximumFramesToRender = 512
    }
    
    public override var outputBusses: AUAudioUnitBusArray {
        return _outputBusArray!
    }
    
    public override var internalRenderBlock: AUInternalRenderBlock {
        return { [weak self] (actionFlags, timestamp, frameCount, outputBusNumber, outputData, realtimeEventListHead, pullInputBlock) in
            guard let self = self else { return kAudioUnitErr_NoConnection }
            
            let ablPointer = UnsafeMutableAudioBufferListPointer(outputData)
            let samplesPerStep = Int(self.sampleRate * 60.0 / self.bpm / 4.0) // 16th notes
            
            for frame in 0..<Int(frameCount) {
                var sampleL: Float = 0.0
                var sampleR: Float = 0.0
                
                // Process each track
                for track in 0..<8 {
                    if self.trackTriggers[track] {
                        let env = Float(self.trackEnvelopes[track])
                        var trackSample: Float = 0.0
                        
                        // Simple drum synthesis
                        switch track {
                        case 0: // Kick
                            let freq = 60.0 * (1.0 + self.trackEnvelopes[track] * 0.5)
                            trackSample = Float(sin(self.trackPhases[track])) * env
                            self.trackPhases[track] += 2.0 * Double.pi * freq / self.sampleRate
                            self.trackEnvelopes[track] *= 0.995
                            
                        case 1: // Snare
                            let tone = Float(sin(self.trackPhases[track] * 200.0))
                            let noise = Float.random(in: -1...1) * 0.3
                            trackSample = (tone * 0.5 + noise) * env
                            self.trackPhases[track] += 1.0
                            self.trackEnvelopes[track] *= 0.99
                            
                        case 2: // Hi-hat
                            trackSample = Float.random(in: -1...1) * env * 0.5
                            self.trackEnvelopes[track] *= 0.98
                            
                        default: // Other percussion
                            let freq = 440.0 * Double(track)
                            trackSample = Float(sin(self.trackPhases[track])) * env * 0.7
                            self.trackPhases[track] += 2.0 * Double.pi * freq / self.sampleRate
                            self.trackEnvelopes[track] *= 0.992
                        }
                        
                        sampleL += trackSample * 0.5
                        sampleR += trackSample * 0.5
                        
                        // Stop trigger when envelope is low
                        if self.trackEnvelopes[track] < 0.001 {
                            self.trackTriggers[track] = false
                            self.trackEnvelopes[track] = 0.0
                        }
                    }
                }
                
                // Write to output buffers
                for buffer in ablPointer {
                    let buf: UnsafeMutableBufferPointer<Float> = UnsafeMutableBufferPointer(buffer)
                    buf[frame] = buffer.mNumberChannels > 1 ? (buffer.mData == ablPointer[0].mData ? sampleL : sampleR) : sampleL
                }
                
                // Advance sequencer
                if self.isPlaying {
                    self.stepCounter += 1
                    if self.stepCounter >= samplesPerStep {
                        self.stepCounter = 0
                        self.advanceSequencer()
                    }
                }
            }
            
            return noErr
        }
    }
    
    private func advanceSequencer() {
        // Trigger active steps
        for track in 0..<8 {
            if grid[track][currentStep] {
                trackTriggers[track] = true
                trackEnvelopes[track] = 1.0
                trackPhases[track] = 0.0
            }
        }
        
        currentStep = (currentStep + 1) % 16
    }
    
    public override func allocateRenderResources() throws {
        try super.allocateRenderResources()
        sampleRate = format.sampleRate
    }
    
    public override func deallocateRenderResources() {
        super.deallocateRenderResources()
    }
    
    // MIDI handling
    public override var canProcessInPlace: Bool { return true }
    
    // Handle MIDI events
    public func handleMIDIEvent(eventType: UInt8, data1: UInt8, data2: UInt8, data3: UInt8) {
        if eventType == 0x90 { // Note On
            let note = Int(data1)
            let velocity = Int(data2)
            if velocity > 0 {
                let track = note % 8
                trackTriggers[track] = true
                trackEnvelopes[track] = Double(velocity) / 127.0
                trackPhases[track] = 0.0
            }
        } else if eventType == 0x80 { // Note Off
            // Could implement note off if needed
        }
    }
    
    // Transport control
    public func startPlayback() {
        isPlaying = true
        currentStep = 0
        stepCounter = 0
    }
    
    public func stopPlayback() {
        isPlaying = false
    }
    
    // Grid control
    public func setStep(track: Int, step: Int, active: Bool) {
        if track >= 0 && track < 8 && step >= 0 && step < 16 {
            grid[track][step] = active
        }
    }
}