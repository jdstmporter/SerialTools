//
//  atomic.swift
//  SerialPort
//
//  Created by Julian Porter on 28/02/2020.
//  Copyright © 2020 JP Embedded Solutions. All rights reserved.
//

import Foundation

protocol AtomicFlag {
    func set()
    func clear()
    var isSet : Bool { get }
}

public class BooleanFlag : AtomicFlag {
    private static let queueName : String = "__BooleanFlagQueue"
    
    private var value : Bool
    private let queue : DispatchQueue
    
    public init(qos : DispatchQoS = .background) {
        value = false
        queue = DispatchQueue(label: BooleanFlag.queueName, qos: qos)
    }
    
    public func set() { queue.sync { value = true } }
    public func clear() { queue.sync { value = false } }
    public var isSet : Bool { queue.sync { value } }
}



