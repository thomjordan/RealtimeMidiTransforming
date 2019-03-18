//
//  RawMidiParsing.swift
//  MusicalEventsPhrasing
//
//  Created by Thom Jordan on 3/17/19.
//  Copyright © 2019 Thom Jordan. All rights reserved.
//

import Foundation
import CoreMIDI

extension Numeric where Self: Comparable { var isWithinMidiRange: Bool { return (self >= 0) && (self <= 127) } }

fileprivate extension Int16 { // convenience functions for transforming midi cc values without having to repeatedly cast between types
    static func + (lhs: Int16, rhs: Double) -> Int16 { return Int16(lhs) + Int16(rhs) }
    static func + (lhs: Double, rhs: Int16) -> Int16 { return Int16(lhs) + Int16(rhs) }
}

struct RawMIDIMessage {
    /* The Int16 type provides a wider range within which to transform incoming midi values,
     until the final cast to UInt8 after confirming the result is within valid midi range. */
    var data: [Int16] = []
    var timeStamp: MIDITimeStamp = 0
    
    subscript(index: Int) -> Int16 {
        get { return index < data.count ? data[index] : 0 }
        set(newValue) { index < data.count ? data[index] = newValue : () }
    }
}

extension RawMIDIMessage {
    var asRawMIDIPacket: MIDIPacket? {
        guard isWithinMidiRange else { return nil }
        var p = MIDIPacket()
        p.timeStamp = self.timeStamp
        switch data.count {
        case 2: p.length = 2; p.data.0 = UInt8(data[0]); p.data.1 = UInt8(data[1]); return p
        case 3: p.length = 3; p.data.0 = UInt8(data[0]); p.data.1 = UInt8(data[1]); p.data.2 = UInt8(data[2]); return p
        default: return nil
        }
    }
    var isWithinMidiRange: Bool {
        var result = true
        for index in 1..<data.count { result = result && data[index].isWithinMidiRange }
        return result
    }
}

extension RawMIDIMessage {
    var isNoteOn: Bool {
        guard data.count == 3 else { return false }
        return ((data[0] & 0xF0) == 0x90) && (data[2] > 0)
    }
    var isNoteOff: Bool {
        guard data.count == 3 else { return false }
        return (((data[0] & 0xF0) == 0x90) && (data[2] == 0))
            ||  ((data[0] & 0xF0) == 0x80)
    }
    var isAftertouch: Bool {
        guard data.count == 3 else { return false }
        return ((data[0] & 0xF0) == 0xA0)
    }
    var isControlChange: Bool {
        guard data.count == 3 else { return false }
        return ((data[0] & 0xF0) == 0xB0)
    }
    var isProgramChange: Bool {
        guard data.count == 2 else { return false }
        return ((data[0] & 0xF0) == 0xC0)
    }
    var isChannelPressure: Bool {
        guard data.count == 2 else { return false }
        return ((data[0] & 0xF0) == 0xD0)
    }
    var isPitchBend: Bool {
        guard data.count == 3 else { return false }
        return ((data[0] & 0xF0) == 0xE0)
    }
    /* - - - - - - - - - - - - - - - - - - - - - */
    
    var channel: Int16 {
        get { return self[0] & 0x0F }
        set(newChannel) { self[0] = (self[0] & 0xF0) + (newChannel % 16) }
    }
    var notenum: Int16 {
        get { return self[1] }
        set(newNotenum) { self[1] = newNotenum }
    }
    var velocity: Int16 {
        get { return self[2] }
        set(newVelocity) { self[2] = newVelocity }
    }
    var controller: Int16 {
        get { return self[1] }
        set(newController) { self[1] = newController }
    }
    var value: Int16 { // controlChange, aftertouch
        get { return self[2] }
        set(newValue) { self[2] = newValue }
    }
    var program: Int16 {
        get { return self[1] }
        set(newProgram) { self[1] = newProgram }
    }
    var depth: Int16 { // channelPressure
        get { return self[1] }
        set(newDepth) { self[1] = newDepth }
    }
    var pitchbend: Int16 {
        get { return 128 * self[2] + self[1] }
        set(newPitchbend) {
            self[1] = newPitchbend % 128
            self[2] = newPitchbend / 128
        }
    }
}

func scanMIDIPacketList(_ packetList: UnsafePointer<MIDIPacketList>) -> [RawMIDIMessage] {
    let pkList = packetList.pointee
    var packet: MIDIPacket = pkList.packet
    var midiMessages: [RawMIDIMessage] = []
    for _ in 1...pkList.numPackets {
        let midiBytes = Mirror(reflecting: packet.data).children
        var msgPacket = RawMIDIMessage()
        msgPacket.timeStamp = packet.timeStamp
        var i = packet.length
        for byte in midiBytes {
            msgPacket.data += [Int16(byte.value as! UInt8)]
            i -= 1 ; if (i <= 0) { break }
        }
        midiMessages += [msgPacket]
        packet = MIDIPacketNext(&packet).pointee
    }
    return midiMessages
}

func midiRangeToBipolar(numsteps: UInt8) -> (Double) -> Double {
    return { inval in
        var offset: Double = 0
        var numer:  Double = 0
        if numsteps%2 != 0 {
            // if numsteps is even...
            offset = Double(63.5)
            numer  = Double(numsteps)
        } else {
            // else when numsteps is odd...
            offset = Double(63)
            numer  = Double(numsteps-1)
        }
        let result = (inval - offset) * (numer / 128.0)
        return round(result)
    }
}

public func midiRangeScaled(_ numsteps: UInt8) -> (Double) -> Int16 {
    return { inval in
        let numer  = Double(numsteps)
        let result = inval * (numer / 128.0)
        return Int16(floor(result)) 
    }
}

let asMidiControl: (NSSlider) -> NSSlider = {
    $0.allowsTickMarkValuesOnly = true
    $0.numberOfTickMarks        = 127
    return $0
}

let asVerticalSlider: (NSSlider) -> NSSlider = {
    $0.sliderType = .linear
    $0.isVertical = true
    return $0
}

let asLateralSlider: (NSSlider) -> NSSlider = {
    $0.sliderType = .linear
    $0.isVertical = false
    return $0
}

let asCircularKnob: (NSSlider) -> NSSlider = {
    $0.sliderType = .circular
    return $0
}

let withFrame: (CGFloat, CGFloat, CGFloat, CGFloat) -> (NSSlider) -> NSSlider = { (x,y,w,h) in
    return { slider in
        slider.frame = NSMakeRect(x,y,w,h)
        return slider
    }
}

/* ------------------------------- */

