//
//  MappingSettings.swift
//  RealtimeMidiTransforming
//
//  Created by Thom Jordan on 3/18/19.
//  Copyright © 2019 Thom Jordan. All rights reserved.
//

import Foundation

public struct RootNote    {
    let value: Int
    public init(_ value: Int) { self.value = value }
}
public struct Tonescales  {
    let value: [[Int]]
    public init(_ value: [[Int]]) { self.value = value }
}
public struct OctaveRange {
    let value: Int
    public init(_ value: Int) { self.value = value }
}

public struct Mapping<Model, Settings> {
    public let model: Model
    public let settings: Settings
    public init(model: Model, settings: Settings) {
        self.model = model
        self.settings = settings
    }
}

public typealias MySettings = (rootNote: RootNote, tonescales: Tonescales, octaveRange: OctaveRange)

public protocol ControlMapping {
    func mapNotenum(_ inputNum: Int16) -> Int16
    func getBPM() -> Double
}

extension Mapping: ControlMapping where Model == ControlsModel, Settings == MySettings {
    var selectedScale: [Int] {
        let rangeSize: Double = 128.0 / Double(settings.tonescales.value.count)
        let index = Int(model.sliderCell2.value / rangeSize)
        return settings.tonescales.value[index]
    }
    public func mapNotenum(_ inputNum: Int16) -> Int16 {
        let tonescale     = selectedScale
        let stepsRange    = UInt8(tonescale.count * settings.octaveRange.value + 1)
        let transformer   = midiRangeScaled(stepsRange)
        let mappedSlider  = transformer(model.sliderCell1.value)
        let stepnum       = inputNum + mappedSlider
        let octavePart    = stepnum / Int16(tonescale.count)
        let scstepPart    = Int(stepnum % Int16(tonescale.count))
        let octaveStart: Int16 = 2
        let result = 12*(octavePart+octaveStart)
                   + Int16(tonescale[scstepPart])
                   + Int16(settings.rootNote.value)
        print("mappedNotenum = \(result)")
        return result
    }
    public func getBPM() -> Double { return model.bpmTempo }
}
