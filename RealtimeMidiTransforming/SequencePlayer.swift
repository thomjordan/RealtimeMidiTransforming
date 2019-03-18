//
//  SequencePlayer.swift
//  MusicalEventsPhrasing
//
//  Created by Thom Jordan on 3/17/19.
//  Copyright © 2019 Thom Jordan. All rights reserved.
//

import Foundation
import Prelude
import ReactiveKit
import MidiPlex
import MidiToolbox
import FunctionalAlgebraicMusic

public class SequencePlayer {
    let model: ControlsModel
    let track: MTMusicTrack
    let seqPlayer = MTMusicPlayer()
    let seq       = MTMusicSequence()
    let bag       = DisposeBag()
    public init(_ model: ControlsModel) {
        self.track = seq.newTrack()
        self.model = model
        DispatchQueue.global(qos: .userInteractive).async { [weak self] in
            guard let self = self else { return }
            self.model.playingStatus.observeNext { status in
                if status { self.seqPlayer.start()    }
                else      { self.seqPlayer.fullStop() }
                }.dispose(in: self.bag)
            self.seq.setTempo(model.bpmTempo)
            self.track |> {
                $0.changeNumberOfLoops(0)
                $0.changeLoopDuration(2.0)
                $0.changeTrackLength(2.0)
            }
            self.seqPlayer.setSequence(self.seq)
        }
    }
    public func connectsTo(target: UInt32) { // UInt32 is a typealias for MIDIEndpointRef
        track.setDestMIDIEndpoint(target)
    }
    public func render(_ perf: Performance) -> () {
        let _ = perf.map {
            let ev = $0.rendered
            self.track.add(
                event: .makeNote(ch: UInt8(ev.eInst-1), nn: UInt8(ev.ePch), vl: UInt8(ev.eVol), rv: UInt8(ev.eVol), du: Float32(ev.eDur)),
                at: ev.eTime
            )
        }
    }
}

