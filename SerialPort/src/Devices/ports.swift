//
//  ports.swift
//  Serial
//
//  Created by Julian Porter on 21/02/2020.
//  Copyright © 2020 JP Embedded Solutions. All rights reserved.
//

import Foundation
import IOKit
import IOKit.serial

public typealias IOObject = io_object_t

public class SerialPorts : Sequence {
    public typealias Port = mach_port_t
    public typealias Iterator = Array<SerialPort>.Iterator
    
    private let master : Port = kIOMasterPortDefault
    private let matcher : [String : String] = [
        kIOProviderClassKey : kIOSerialBSDServiceValue
    ]
    private var ports : [SerialPort] = []
    
    public init() throws {
        try self.reload()
    }
    
    public var count : Int { ports.count }
    public func makeIterator() -> Iterator { ports.makeIterator() }
    public subscript(_ n : Int) -> SerialPort { ports[n] }
    public subscript(_ name : String) -> SerialPort? { ports.first { $0.name == name } }
    
    public func reload() throws {
        var ports : [SerialPort] = []
        var iter : io_iterator_t = 0
        let m = matcher as CFDictionary
        try SerialError.wrap(IOServiceGetMatchingServices(master, m, &iter))
        var out = IOIteratorNext(iter)
        while out != 0 {
            ports.append(try SerialPort(out))
            out = IOIteratorNext(iter)
        }
        self.ports=ports
    }
    
    public static func scan() throws -> SerialPorts { try SerialPorts() }
}
