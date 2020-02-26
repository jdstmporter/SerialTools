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





public class Connection {
    
    private let port : SerialPort
    private let path : String
    private var fd : Int32 = -1
    private var listening : Bool = false
    
    public init(_ port : SerialPort) throws  {
        self.port=port
        guard let path = port.outbound else {
            throw SerialError(kIOReturnNoDevice)
        }
        self.path=path
    }
    
    
    
    public func connect(flags : SerialFlags,blocking: Bool = false) throws {
        if try port.isBusy() { throw SerialError(kIOReturnBusy) }
        self.fd = try path.withCString { try wopen($0, O_RDWR | O_NOCTTY | O_NDELAY) }
        if self.fd<0 { throw SerialError(kIOReturnNotOpen) }
         
        // apply serial flags
        
        flags.apply(port: self.fd)
        
        // set blocking mode
        
        let flag = blocking ? 0 : FNDELAY
        try wfcntl(fd, F_SETFL, flag);
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
            var data = Array<UInt8>(repeating: 0, count: 20)
            let n : Int = data.withUnsafeMutableBytes { ptr in
                if let raw = ptr.baseAddress {
                    return read(fd, raw, 1)
                }
                else { return 0 }
            }
            guard n>=0 else { return [] }
            return Array(data.prefix(n))
        }
        set {
            newValue.withUnsafeBytes { ptr in
                guard let raw = ptr.baseAddress else { return }
                _ = write(fd, raw, newValue.count)
            }
        }
    }
    
    public func incoming(minimum: Int = 1, maximum : Int = 256) throws -> [UInt8] {
        var data = Array<UInt8>(repeating: 0, count: maximum)
        let n : Int = try data.withUnsafeMutableBytes { ptr in
            if let raw = ptr.baseAddress {
                return try wread(fd, raw, minimum)
            }
            else { return 0 }
        }
        return Array(data.prefix(n))
    }
    
    public func out(_ s : String) throws {
        var t = s
        try t.withUTF8 { ptr in
            guard let p = ptr.baseAddress else { return }
            let raw = UnsafeRawPointer(p)
            try wwrite(fd, raw, ptr.count)
        }
    }
    
    public func listen(_  cb : @escaping ([UInt8]) -> ()) {
        listening=true
        DispatchQueue.init(label: "serial").async {
            while true {
                if !self.listening { return }
                let b=self.bytes
                if b.count>0 { cb(b) }
            }
        }
    }
    
    
    
}
