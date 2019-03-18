//
//  RealtimeMidiTransforming.swift
//  MusicalEventsPhrasing
//
//  Created by Thom Jordan on 3/13/19.
//  Copyright © 2019 Thom Jordan. All rights reserved.
//

import Foundation
import Overture
import Prelude
import ReactiveKit
import MidiToolbox
import CoreMIDI

fileprivate extension Int16 { // convenience functions for transforming midi cc values without having to repeatedly cast between types
    static func + (lhs: Int16, rhs: Double) -> Int16 { return Int16(lhs) + Int16(rhs) }
    static func + (lhs: Double, rhs: Int16) -> Int16 { return Int16(lhs) + Int16(rhs) }
}

public class RealtimeMidiTransformer {
    let mapping: ControlMapping
    var activeNoteMaps = ActiveValueQueues()
    var virtualLiveMidiClient = MIDIClientRef()
    var virtualSourceEndpoint = MIDIEndpointRef()
    var virtualTargetEndpoint = MIDIEndpointRef()
    public var input: MIDIEndpointRef { return virtualTargetEndpoint }
    
    // should accept inputControls model + mapping-schema (using Witnesses?)
    public init(mapping: ControlMapping) {
        self.mapping = mapping
        DispatchQueue.global(qos: .userInteractive).async { [weak self] in
            guard let self = self else { return }
            MIDIClientCreateWithBlock("net.thomjordan.VirtualMidiClient" as CFString, &self.virtualLiveMidiClient, nil) |> confirm
            //        MIDIClientCreate("net.thomjordan.VirtualMidiClient" as CFString, nil, nil, &virtualLiveMidiClient) |> confirm
            MIDISourceCreate(self.virtualLiveMidiClient, "MusicA.VirtualSource" as CFString, &self.virtualSourceEndpoint) |> confirm
            MIDIDestinationCreateWithBlock(self.virtualLiveMidiClient, "MusicA.VirtualDest" as CFString, &self.virtualTargetEndpoint, self.readBlock) |> confirm
            //var outProps: Unmanaged<CFPropertyList>?  // gets name and uniqueID
            //MIDIObjectGetProperties(virtualTargetEndpoint, &outProps, true) |> confirm
            //print(outProps)
        }
    }
    
    func receiveMIDI(_ src: MIDIEndpointRef, _ pkt: MIDIPacket) -> OSStatus {
        var packetList = MIDIPacketList(numPackets: 1, packet: pkt)
        return MIDIReceived(src, &packetList)
    }
    
    func latencyToAdd() -> UInt64 { // removes jitter
        let durationOf16thNoteInMS = ((1000/4) * 60 / mapping.getBPM()) / 2.0
        let durationInNanoseconds  = durationOf16thNoteInMS * 1000000
        return durationInNanoseconds |> round |> UInt64.init
    }
    
    func readBlock(packetList: UnsafePointer<MIDIPacketList>, srcConnRefCon: UnsafeMutableRawPointer?) {
        let midiMessages = scanMIDIPacketList(packetList)
        for var msg in midiMessages {
            if msg.isNoteOn {
                let inputNotenum = msg.notenum
                let mappedNoteOn = msg |> (prop(\.notenum))   { nn in self.mapping.mapNotenum(nn)}
                                       |> (prop(\.timeStamp)) { $0 + self.latencyToAdd() }
                self.activeNoteMaps[inputNotenum] = mappedNoteOn.notenum
                guard let newNoteOn = mappedNoteOn.asRawMIDIPacket else { return }
                self.receiveMIDI(self.virtualSourceEndpoint, newNoteOn) |> confirm
            } else if msg.isNoteOff {
                guard let mappedNNValue = self.activeNoteMaps[msg.notenum] else { return }
                // self.activeNoteMaps[msg.notenum] = nil
                let mappedNoteOff = msg |> (prop(\.notenum))   { _ in mappedNNValue  }
                                        |> (prop(\.timeStamp)) { $0 + self.latencyToAdd() }
                guard let newNoteOff = mappedNoteOff.asRawMIDIPacket else { return }
                self.receiveMIDI(self.virtualSourceEndpoint, newNoteOff) |> confirm
            }
            // var dumpStr = ""
            // for byte in msg.data { dumpStr += String(format:"$%02X ", byte) }
            // print("OUT: MIDIPacket: \(dumpStr) withTimestamp: \(msg.timeStamp)")
        }
    }
    
}




