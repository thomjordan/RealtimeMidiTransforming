//
//  ControlsViewController.swift
//  MusicalEventsPhrasing
//
//  Created by Thom Jordan on 3/17/19.
//  Copyright © 2019 Thom Jordan. All rights reserved.
//

import Foundation
import Prelude
import ReactiveKit

public class ControlsViewController: NSViewController { }

public extension ControlsViewController {
    public static func makeViewController(_ model: ControlsModel) -> ControlsViewController {
        let vc = ControlsViewController(nibName: nil, bundle: nil)
        let slider1 = MidiSlider() |> asVerticalSlider |> withFrame( 90, 0, 100, 260)
        let slider2 = MidiSlider() |> asVerticalSlider |> withFrame(120, 0, 100, 260)
        let slider3 = MidiSlider() |> asVerticalSlider |> withFrame(150, 0, 100, 260)
        let slider4 = MidiSlider() |> asVerticalSlider |> withFrame(180, 0, 100, 260)
        slider1.reactive.doubleValue.bidirectionalBind(to: model.sliderCell1.cell).dispose(in: vc.bag)
        slider2.reactive.doubleValue.bidirectionalBind(to: model.sliderCell2.cell).dispose(in: vc.bag)
        slider3.reactive.doubleValue.bidirectionalBind(to: model.sliderCell3.cell).dispose(in: vc.bag)
        slider4.reactive.doubleValue.bidirectionalBind(to: model.sliderCell4.cell).dispose(in: vc.bag)
        vc.view = NSView(frame: NSMakeRect(0,0,300,300))
        vc.view.addSubview(slider1)
        vc.view.addSubview(slider2)
        vc.view.addSubview(slider3)
        vc.view.addSubview(slider4)
        return vc
    }
}

