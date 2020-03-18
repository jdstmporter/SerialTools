//
//  port.swift
//  Serial
//
//  Created by Julian Porter on 23/02/2020.
//  Copyright © 2020 JP Embedded Solutions. All rights reserved.
//

import Foundation
import IOKit
import IOKit.serial

public protocol Nameable {
    var name : String { get }
}
extension Nameable {
    public var name : String { "\(self)" }
    
    
}

public class SerialPort : CustomStringConvertible, CustomDebugStringConvertible, Sequence {
    
    public enum BSDType : Nameable {
        case RS232
        case Serial
        case Modem
        
        private static let map : [String:BSDType] = [
            kIOSerialBSDAllTypes : .Serial,
            kIOSerialBSDModemType : .Modem,
            kIOSerialBSDRS232Type : .RS232
        ]
        public init?(_ s : String?) {
            guard let s = s, let v = Self.map[s] else { return nil }
            self = v
        }
    }
    
    public typealias Iterator = Dictionary<String,Any>.Iterator
    private let object : IOObject
    public private(set) var id : UInt64
    public private(set) var className : String
    public private(set) var path : String
    private var attributes : [String:Any]
    
    
    public init(_ object : IOObject) throws {
        self.object = object
        
        var id : UInt64 = 0
        try SerialError.wrap(IORegistryEntryGetRegistryEntryID(object, &id))
        self.id = id
        
        self.path = try String { IORegistryEntryGetPath(object, kIOServicePlane, $0) }  ?? "-"
        self.className = try String { IORegistryEntryGetNameInPlane(object, kIOServicePlane, $0) }  ?? "-"
        
        var dict : Unmanaged<CFMutableDictionary>? = nil
        try SerialError.wrap(IORegistryEntryCreateCFProperties(object, &dict, kCFAllocatorDefault, 0))
        self.attributes = (dict?.takeRetainedValue() as? [String:Any]) ?? [:]
    }
    
    
    public var name : String? { self[kIOTTYDeviceKey] }
    public var inbound : String? { self[kIODialinDeviceKey] }
    public var outbound : String? { self[kIOCalloutDeviceKey] }
    public var clientType : BSDType? { BSDType(self[kIOSerialBSDTypeKey]) }
    
    public func isBusy() throws -> Bool {
        var state : UInt32 = 0
        try SerialError.wrap(IOServiceGetBusyState(self.object, &state))
        return state>0
    }
    public func waitUntilNotBusy(timeout: TimeInterval) throws -> Bool {
        var t = mach_timespec(timeout)
        let out = IOServiceWaitQuiet(self.object, &t)
        switch out {
        case kIOReturnSuccess:
            return true
        case kIOReturnTimeout:
            return false
        default:
            throw SerialError(out)
        }
    }
    
    
    // Sequence methods
    
    public subscript<T>(_ key : String) -> T? { attributes[key] as? T }
    public var count : Int { attributes.count }
    public __consuming func makeIterator() -> Dictionary<String, Any>.Iterator { attributes.makeIterator() }
    
    // Custom string convertible methods
    
    public var description: String { name ?? "" }
    public var debugDescription: String { "Port \(name ?? "-") with device file \(outbound ?? "")" }
    
    
}

