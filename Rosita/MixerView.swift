import SwiftUI

// MARK: - Main Mixer View (8x8 grid - one column per instrument)
struct MixerView: View {
    @ObservedObject var audioEngine: AudioEngine

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            // 8 rows x 8 columns - one column per instrument
            ForEach(0..<8, id: \.self) { row in
                HStack(spacing: 2) {
                    ForEach(0..<8) { col in
                        MixerGridCell(
                            row: row,
                            col: col,
                            audioEngine: audioEngine
                        )
                    }
                }
            }
        }
        .padding(EdgeInsets(top: 0, leading: 8, bottom: 8, trailing: 8))
    }
}

// MARK: - Mixer Grid Cell
struct MixerGridCell: View {
    let row: Int
    let col: Int
    @ObservedObject var audioEngine: AudioEngine

    var body: some View {
        // Column mapping (one column per instrument):
        // 0: SYNTH (track 0)
        // 1: BASS (track 1)
        // 2: LEAD (track 2)
        // 3: KICK (drum 0)
        // 4: SNARE (drum 1)
        // 5: HAT (drum 2)
        // 6: PERC (drum 3)
        // 7: MASTER

        let trackInfo = getTrackInfo(col: col)

        Button(action: {
            handleTap()
        }) {
            Rectangle()
                .fill(cellColor)
                .overlay(
                    Rectangle()
                        .stroke(Color.black, lineWidth: 1)
                )
                .aspectRatio(1.0, contentMode: .fit)
        }
        .buttonStyle(PlainButtonStyle())
    }

    private func getTrackInfo(col: Int) -> (track: Int, isDrum: Bool, isMaster: Bool) {
        switch col {
        case 0: return (0, false, false)   // SYNTH
        case 1: return (1, false, false)   // BASS
        case 2: return (2, false, false)   // LEAD
        case 3: return (0, true, false)    // KICK
        case 4: return (1, true, false)    // SNARE
        case 5: return (2, true, false)    // HAT
        case 6: return (3, true, false)    // PERC
        case 7: return (0, false, true)    // MASTER
        default: return (0, false, false)
        }
    }

    private var cellColor: Color {
        let info = getTrackInfo(col: col)
        let trackColor = getTrackColor(info: info)

        // First row shows track name/label
        if row == 0 {
            return trackColor
        }

        // Rows 1-6 are volume faders (6 levels)
        if row >= 1 && row <= 6 {
            let volume = getVolume(info: info)
            let volumeLevel = Int(volume * 6.0)
            let isActive = (6 - row) <= volumeLevel

            if isActive {
                return trackColor
            } else {
                return trackColor.opacity(0.15)
            }
        }

        // Row 7 is mute/solo button
        if row == 7 {
            if info.isMaster {
                // Master: mute button
                return audioEngine.masterMuted ? Color.red : Color.gray.opacity(0.3)
            } else {
                // Mute button (red when muted, yellow when solo active)
                if isSolo(info: info) {
                    return Color.yellow
                } else if isMuted(info: info) {
                    return Color.red
                } else {
                    return Color.gray.opacity(0.3)
                }
            }
        }

        return Color.clear
    }

    private func getTrackColor(info: (track: Int, isDrum: Bool, isMaster: Bool)) -> Color {
        if info.isMaster {
            return Color.white
        }

        if info.isDrum {
            switch info.track {
            case 0: return Color(hex: "FF0000")  // KICK - Red
            case 1: return Color(hex: "00BFFF")  // SNARE - Sky Blue
            case 2: return Color(hex: "00FF00")  // HAT - Green
            case 3: return Color(hex: "FF00FF")  // PERC - Magenta
            default: return Color.gray
            }
        } else {
            switch info.track {
            case 0: return Color(hex: "FFB6C1")  // SYNTH - Pink
            case 1: return Color(hex: "87CEEB")  // BASS - Sky Blue
            case 2: return Color(hex: "DDA0DD")  // LEAD - Plum
            default: return Color.gray
            }
        }
    }

    private func getVolume(info: (track: Int, isDrum: Bool, isMaster: Bool)) -> Double {
        if info.isMaster {
            return audioEngine.masterVolume
        }

        if info.isDrum {
            return audioEngine.drumTrackVolumes[info.track]
        } else {
            return audioEngine.trackVolumes[info.track]
        }
    }

    private func isMuted(info: (track: Int, isDrum: Bool, isMaster: Bool)) -> Bool {
        if info.isMaster {
            return audioEngine.masterMuted
        }

        if info.isDrum {
            return audioEngine.drumTrackMuted[info.track]
        } else {
            return audioEngine.trackMuted[info.track]
        }
    }

    private func isSolo(info: (track: Int, isDrum: Bool, isMaster: Bool)) -> Bool {
        if info.isMaster {
            return false
        }

        if info.isDrum {
            return audioEngine.drumTrackSolo[info.track]
        } else {
            return audioEngine.trackSolo[info.track]
        }
    }

    private func handleTap() {
        let info = getTrackInfo(col: col)

        // Row 0: Track label - do nothing
        if row == 0 {
            return
        }

        // Rows 1-6: Volume control
        if row >= 1 && row <= 6 {
            let volumeLevel = 6 - row  // 0 (bottom) to 6 (top)
            let volume = Double(volumeLevel) / 6.0

            if info.isMaster {
                audioEngine.masterVolume = volume
            } else if info.isDrum {
                audioEngine.drumTrackVolumes[info.track] = volume
            } else {
                audioEngine.trackVolumes[info.track] = volume
            }

            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }

        // Row 7: Mute/Solo toggle
        if row == 7 {
            if info.isMaster {
                // Master mute toggle
                audioEngine.masterMuted.toggle()
            } else {
                // Cycle between: normal -> mute -> solo -> normal
                let isMutedNow = isMuted(info: info)
                let isSoloNow = isSolo(info: info)

                if !isMutedNow && !isSoloNow {
                    // Normal -> Mute
                    if info.isDrum {
                        audioEngine.drumTrackMuted[info.track] = true
                    } else {
                        audioEngine.trackMuted[info.track] = true
                    }
                } else if isMutedNow {
                    // Mute -> Solo
                    if info.isDrum {
                        audioEngine.drumTrackMuted[info.track] = false
                        audioEngine.drumTrackSolo[info.track] = true
                    } else {
                        audioEngine.trackMuted[info.track] = false
                        audioEngine.trackSolo[info.track] = true
                    }
                } else {
                    // Solo -> Normal
                    if info.isDrum {
                        audioEngine.drumTrackSolo[info.track] = false
                    } else {
                        audioEngine.trackSolo[info.track] = false
                    }
                }
            }

            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        }
    }
}
