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

public protocol BaseError : Error, CustomStringConvertible {
    
    var message : String { get }
    var code : Int32 { get }
    var localizedDescription : String { get }
    var time : timeval { get }
    
    init(_ : Int32)
    
    static var success : Int32 { get }
    static var className : String { get }
    @discardableResult static func wrap(_ : Int32) throws -> Int32
}
extension BaseError {
    
    @discardableResult public static func wrap(_ code : Int32) throws -> Int32 {
        guard code != Self.success else { return code }
        throw Self(code)
    }
    
    public static var className : String { String(describing: Self.self) }
    public var description: String {"\(Self.className) error \(code): \(message)"}
    public var localizedDescription: String { description }
}

public class SerialError : BaseError {
    
    public private(set) var message : String
    public private(set) var code : IOReturn
    public private(set) var time : timeval
    
    public static let success = kIOReturnSuccess
    
    public required init(_ code : IOReturn) {
        self.code=code
        self.message=code.error ?? ""
        self.time=timeval.now()
    }
}

public class POSIXException : BaseError {
    
    public private(set) var message : String
    public private(set) var code : errno_t
    public private(set) var time : timeval
    
    public static let success : errno_t = -1
     
    public required init(_ code : errno_t) {
        let io : IOReturn = numericCast(code+100000)
        self.message=io.error ?? ""
        self.code=code
        self.time=timeval.now()
    }
    public static func wrapInt(_ code : Int) throws -> Int {
        return try numericCast(wrap(numericCast(code)))
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



