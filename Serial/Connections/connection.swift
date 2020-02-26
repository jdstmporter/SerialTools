//
//  connection.swift
//  Serial
//
//  Created by Julian Porter on 23/02/2020.
//  Copyright © 2020 JP Embedded Solutions. All rights reserved.
//

import Foundation
import IOKit
import IOKit.serial



public typealias SerialFlag = (c:UInt, i:UInt, o:UInt)


public protocol ConnectionDelegate {
    
    func receivedBytes(_ : [UInt8])
    func receivedError(_ : BaseError)
    
}


public class Connection {
    
    private let port : SerialPort
    private let path : String
    private var fd : Int32 = -1
    private var listening : Bool = false
    private var minimum : Int = 0
    public var delegate : ConnectionDelegate?
    
    public init(_ port : SerialPort) throws  {
        self.port=port
        guard let path = port.outbound else {
            throw SerialError(kIOReturnNoDevice)
        }
        self.path=path
    }
    
    
    
    public func connect(flags : SerialFlags) throws {
        if try port.isBusy() { throw SerialError(kIOReturnBusy) }
        self.fd = try path.withCString { try wopen($0, O_RDWR | O_NOCTTY | O_NDELAY) }
        if self.fd<0 { throw SerialError(kIOReturnNotOpen) }
         
        // apply serial flags
        
        try flags.apply(port: self.fd)
        //self.minimum = flags.minimumRead
    }
    
    public func disconnect() throws {
        listening=false
        try wclose(self.fd)
    }
    
    public func flush() throws {
        try wioctl(fd, numericCast(TCOFLUSH))
    }
    
    public var bytes : [UInt8] {
        get {
            do { return try receive(minimum: 1) }
            catch let e {
                SysLog.error("\(e)")
                return []
            }
        }
        set {
            do { try send(newValue) }
            catch let e { SysLog.error("\(e)") }
        }
    }
    
    public func receive(minimum: Int = 1, maximum : Int = 256) throws -> [UInt8] {
        var data = Array<UInt8>(repeating: 0, count: maximum)
        let n : Int = try data.withUnsafeMutableBytes { ptr in
            if let raw = ptr.baseAddress {
                return try wread(fd, raw, minimum)
            }
            else { return 0 }
        }
        return Array(data.prefix(n))
    }
    
    @discardableResult public func send(_ b : [UInt8]) throws -> Int {
        return try b.withUnsafeBytes { ptr in
            guard let raw = ptr.baseAddress else { throw SerialError(kIOReturnNoSpace) }
            return write(fd, raw, b.count)
        }
    }
    
    @discardableResult public func send(_ s : String) throws -> Int {
        var t = s
        return try t.withUTF8 { ptr in
            guard let p = ptr.baseAddress else { throw SerialError(kIOReturnNoSpace) }
            let raw = UnsafeRawPointer(p)
            return try wwrite(fd, raw, ptr.count)
        }
    }
    
    public func listen(minimum: Int = 1, maximum : Int = 256) {
        guard let delegate = self.delegate else { return }
        listening=true
        DispatchQueue.init(label: "serial\(port.name ?? "COM")", qos: .userInteractive).async {
            while true {
                if !self.listening { return }
                do {
                    let b=try self.receive(minimum: minimum, maximum: maximum)
                    if b.count>0 { delegate.receivedBytes(b) }
                }
                catch let e as BaseError { delegate.receivedError(e) }
                catch let e { SysLog.error("\(e)") }
            }
        }
    }
}
