//
//  ControlsModel.swift
//  MusicalEventsPhrasing
//
//  Created by Thom Jordan on 3/17/19.
//  Copyright © 2019 Thom Jordan. All rights reserved.
//

import Foundation
import ReactiveKit
import MidiPlex

public class ControlsModel {
    var sliderCell1 = SliderCell()
    var sliderCell2 = SliderCell()
    var sliderCell3 = SliderCell()
    var sliderCell4 = SliderCell()
    let playingStatus: Property<Bool> = Property(false)
    var bpmTempo: Double = 135
    
    public init() {
        onMidiReceive { nodeMsg in
            let msg = nodeMsg.midi
            guard msg.type() == MidiType.controlChangeVal.rawValue else { return }
            switch msg.data1() {
            case  0: self.sliderCell1.value = Double(msg.data2())
            case  1: self.sliderCell2.value = Double(msg.data2())
            case  2: self.sliderCell3.value = Double(msg.data2())
            case  3: self.sliderCell4.value = Double(msg.data2())
            case 41: if msg.data2() == 127 { self.playingStatus.next(true)  } // play
            case 42: if msg.data2() == 127 { self.playingStatus.next(false) } // stop
            default: break
            }
        }
    }
}


