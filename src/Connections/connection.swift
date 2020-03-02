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

public protocol ConnectionDelegate {
    func received(_ result : Result<[UInt8],BaseError>)
}


public class Connection {
    
    private let port : SerialPort
    private let flags : SerialFlags
    private let path : String
    private var fd : Int32 = -1
    private var listening : BooleanFlag
    private var waitForBytes : Int
    private var bufferSize : Int
    public var delegate : ConnectionDelegate?
    
    public init(port : SerialPort, flags : SerialFlags, waitForBytes : Int = 1, bufferSize : Int = 256) throws  {
        self.listening = BooleanFlag()
        self.waitForBytes = waitForBytes
        self.bufferSize = bufferSize
        self.flags = flags
        self.port=port
        guard let path = port.outbound else { throw SerialError(kIOReturnNoDevice) }
        self.path=path
    }
    public var name : String? { port.name }
    private var queueName : String { "__Serial_Port_\(name ?? "port")_Queue" }
    
    internal func listen() {
        guard let delegate = self.delegate else { return }
        listening.set()
        DispatchQueue.init(label: "serial\(port.name ?? "COM")", qos: .userInteractive).async {
            while self.listening.isSet {
                do {
                    let b=try self.receive()
                    if b.count>0 { delegate.received(.success(b)) }
                }
                catch let e as BaseError { delegate.received(.failure(e)) }
                catch let e { SysLog.error("\(e)") }
            }
        }
    }
    
    public func connect(async : Bool) throws {
        if try port.isBusy() { throw SerialError(kIOReturnBusy) }
        self.fd = try path.withCString { try wopen($0, O_RDWR | O_NOCTTY | O_NDELAY) }
        if self.fd<0 { throw SerialError(kIOReturnNotOpen) }
         
        // apply serial flags
        try flags.apply(port: self.fd)
        if async { self.listen() }
    }
    
    public func disconnect() throws {
        listening.clear()
        try wclose(self.fd)
    }
    
    public func flush() throws {
        try wioctl(fd, numericCast(TCOFLUSH))
    }
    
    public var bytes : [UInt8] {
        get {
            do { return try receive() }
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
    
    public func receive() throws -> [UInt8] {
        var data = Array<UInt8>(repeating: 0, count: bufferSize)
        let n : Int = try data.withUnsafeMutableBytes { ptr in
            if let raw = ptr.baseAddress {
                return try wread(fd, raw, waitForBytes)
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
    
    
}

