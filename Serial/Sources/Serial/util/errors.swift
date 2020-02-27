//
//  errors.swift
//  Serial
//
//  Created by Julian Porter on 23/02/2020.
//  Copyright © 2020 JP Embedded Solutions. All rights reserved.
//

import Foundation

extension IOReturn {
    var error : String? {
        guard let cstr = mach_error_string(self) else { return nil }
        return String(cString: cstr)
    }
}
extension timeval {
    static func now() -> timeval {
        var time = timeval()
        gettimeofday(&time, nil)
        return time
    }
}

public class BaseError : Error, CustomStringConvertible  {
    public fileprivate(set) var message : String
    public fileprivate(set) var code : Int32
    public fileprivate(set) var time : timeval
    
    public init(_ message: String, _ code: Int32) {
        self.code=code
        self.message=message
        self.time=timeval.now()
    }
    
    public required init(_ code : Int32) {
        self.code=code
        self.message=code.error ?? ""
        self.time=timeval.now()
    }
    
    @discardableResult public static func wrap(_ code : Int32) throws -> Int32 {
        guard isError(code) else { return code }
        throw self.init(code)
    }
    
    public class func isError(_ code : Int32) -> Bool { return code == -1 }
 
    private var className : String { String(describing: type(of: self)) }
    public var description: String { "\(className) error \(code): \(message)" }
    public var localizedDescription: String { description }
}

public class SerialError : BaseError {
    public class override func isError(_ code : Int32) -> Bool { return code != kIOReturnSuccess }
}

public class POSIXException : BaseError {
    public required init(_ code : Int32) {
        let io : IOReturn = numericCast(code+100000)
        super.init(io.error ?? "", code)
    }
    public static func wrapInt(_ code : Int) throws -> Int {
        try numericCast(wrap(numericCast(code)))
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



