//
//  errors.swift
//  Serial
//
//  Created by Julian Porter on 23/02/2020.
//  Copyright © 2020 JP Embedded Solutions. All rights reserved.
//

import Foundation

public class SerialError : Error {
    
    public private(set) var message : String
    public private(set) var code : IOReturn
    
    public init(_ code : IOReturn) {
        self.code=code
        if let cstr = mach_error_string(code) {
            self.message = String(cString: cstr)
        }
        else { self.message = "-" }
    }
    
    static func wrap(_ code : IOReturn) throws {
        guard code != kIOReturnSuccess else { return }
        throw SerialError(code)
    }
}

public class POSIXError : Error {
    
    public private(set) var message : String
    public private(set) var code : POSIXError
     
    public init(_ code : errno_t) {
        self.code=POSIXError(code)
        self.message=self.code.message
    }
     
    @discardableResult static func wrap(_ code : Int32) throws -> Int32 {
        guard code == -1 else { return code }
        throw POSIXError(errno)
     }
    @discardableResult static func wrap(_ code : Int) throws -> Int {
       guard code == -1 else { return code }
       throw POSIXError(errno)
    }
}




public typealias IOGetter = (UnsafeMutablePointer<Int8>?) -> IOReturn

extension String {
    init?(_ io : IOGetter) throws {
        var dt = Data(repeating: 0, count: 500)
        try dt.withUnsafeMutableBytes { ptr in
            let raw = ptr.baseAddress
            let b = raw?.bindMemory(to: Int8.self, capacity: 500)
            try SerialError.wrap(io(b))
        }
        guard let s = String(data: dt, encoding: .utf8) else { return nil }
        self = s
    }
        
}

extension mach_timespec {
    init(_ i : TimeInterval) {
        let secs = UInt32(i)
        let nanos = clock_res_t(i*1.0e9)
        self.init(tv_sec: secs, tv_nsec: nanos)
    }
}



