//
//  MidiSlider.swift
//  MusicalEventsPhrasing
//
//  Created by Thom Jordan on 3/17/19.
//  Copyright © 2019 Thom Jordan. All rights reserved.
//

import Foundation
import Prelude
import AppKit
import ReactiveKit
import Bond

class MidiSlider: NSSlider {
    init(initialValue: Double = 64) {
        super.init(frame: NSZeroRect)
        self.doubleValue = initialValue
        self.minValue = 0
        self.maxValue = 127
        self.allowsTickMarkValuesOnly = true
        self.numberOfTickMarks        = 127
        self.reactive.doubleValue.next(initialValue)
        self.reactive.controlEvent.observeNext { event in
            self.reactive.doubleValue.next(event.doubleValue)
            }.dispose(in: self.reactive.bag)
    }
    required init?(coder: NSCoder) { super.init(coder: coder) }
}

struct SliderCell {
    var cell: Property<Double> = Property(0)
    var valueTransform: (Double) -> Double = { $0 }
    var value: Double {
        get { return cell.value }
        set(newValue) { cell.value = newValue }
    }
    var transformedValue: Double { return valueTransform(value) }
    init(withTransform: @escaping (Double) -> Double = { $0 } ) {
        self.valueTransform = withTransform
    }
}


