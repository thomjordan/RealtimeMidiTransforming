//
//  ActiveValueQueues.swift
//  RealtimeMidiTransforming
//
//  Created by Thom Jordan on 3/18/19.
//  Copyright © 2019 Thom Jordan. All rights reserved.
//

import Foundation

class ActiveValueQueues {
    var queues: [Int16:[Int16]] = [:]
    subscript(index: Int16) -> Int16? {
        get {
            guard var q = queues[index] else { return nil }
            guard q.count > 0 else { return nil }
            let result = q.removeFirst()
            q.count == 0 ? (queues[index] = nil) : (queues[index] = q)
            return result
        }
        set(newValue) {
            if queues[index] == nil {
                queues[index] = [newValue!]
            } else {
                queues[index] = queues[index]! + [newValue!]
            }
        }
    }
}

