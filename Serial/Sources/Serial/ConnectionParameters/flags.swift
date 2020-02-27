//
//  flags.swift
//  Serial
//
//  Created by Julian Porter on 26/02/2020.
//  Copyright © 2020 JP Embedded Solutions. All rights reserved.
//

import Foundation


public enum Bauds : Int, SerialParameter {
    case b9600 = 9600
    case b19200 = 19200
    case b38400 = 38400
    case b57600 = 57600
    case b76800 = 76800
    case b115200 = 115200
    
    public static let MASK : UInt32 = 0xffffffff
    public static let convert : [Bauds:UInt32] = [
        .b9600 : B9600.u,
        .b19200 : B19200.u,
        .b38400 : B38400.u,
        .b57600 : B57600.u,
        .b76800 : B76800.u,
        .b115200 : B115200.u
    ]
}

public enum Bits : Int, SerialParameter {
    case b5 = 5
    case b6 = 6
    case b7 = 7
    case b8 = 8
    
    public static let MASK : UInt32 = CSIZE.u
    public static let convert : [Bits:UInt32] = [
        .b5 : CS5.u,
        .b6 : CS6.u,
        .b7 : CS7.u,
        .b8 : CS8.u
    ]
    
}

public enum Parity : SimpleSerialParameter {
    
    case None
    case Odd
    case Even
    
    public static var MASK : UInt32 = ~(PARENB | CSTOPB | CSIZE).u
    public static let convert : [Parity:UInt32] = [
        .None : 0,
        .Odd : (PARENB | PARODD).u,
        .Even : PARENB.u
    ]
}



public enum InputMode : SimpleSerialParameter {

    case Canonical
    case Raw
    
    static var MASK: UInt32 = ~(ICANON | ECHO | ECHOE).u
    public static var convert: [InputMode : UInt32] = [
        .Canonical : (ICANON | ECHO | ECHOE).u,
        .Raw : 0
    ]
}

public enum FlowControl {

    case XON
    case RTSCTS
    case None
}

public enum HardwareFlowControl : SimpleSerialParameter {

    case RTSCTS
    case None
    
    static var MASK: UInt32 = ~CRTSCTS.u
    public static var convert: [HardwareFlowControl : UInt32] = [
        .RTSCTS : CRTSCTS.u,
        .None : 0
    ]
}



public struct SerialFlags {
    public enum Mode {
        case _8N1
        case _7E1
        case _7O1
        case _7S1
    }
    var rate : Bauds = .b9600
    var flowControl : FlowControl = .None
    var rawInput : Bool = true
    var crlfOutput : Bool = false
    var size : Bits = .b8
    var parity : Parity = .None
    var blocking : Bool = false
    var timeout : Int8 = 0
    var minRead : Int8 = 0
    
    public init(_ rate : Bauds = .b9600, raw : Bool = true, blocking: Bool = false) {
        self.rate = rate
        self.rawInput = raw
        self.crlfOutput = !raw
        self.blocking = blocking
    }
    
    @discardableResult public mutating func set(rate : Bauds) -> SerialFlags {
        self.rate = rate
        return self
    }
    @discardableResult public mutating func set(flowControl : FlowControl) -> SerialFlags {
        self.flowControl = flowControl
        return self
    }
    @discardableResult public mutating func set(raw : Bool,crlf : Bool = false) -> SerialFlags {
        self.rawInput=raw
        self.crlfOutput=crlf
        return self
    }
    @discardableResult public mutating func set(mode : Mode) -> SerialFlags {
        switch mode {
        case ._8N1, ._7S1:
            size = .b8
            parity = .None
        case ._7E1:
            size = .b7
            parity = .Even
        case ._7O1:
            size = .b7
            parity = .Odd
        }
        return self
    }
    @discardableResult public mutating func set(blocking : Bool) -> SerialFlags {
        self.blocking=blocking
        return self
    }
    @discardableResult public mutating func set(timeout: Double = 0,minRead : UInt = 0) -> SerialFlags {
        self.timeout = Int8(min(max(timeout,0), 10)*10)
        self.minRead = numericCast(minRead)
        return self
    }
    
    public var minimumRead : Int {
        return blocking ? numericCast(minRead) : 0
    }
    
    
    public func apply(_ term : inout termios) {
        cfsetspeed(&term, rate.mask)
        
        switch flowControl {
        case .None:
            term.c_cflag &= ~numericCast(CRTSCTS)
            term.c_iflag &= ~numericCast(IXON | IXOFF | IXANY)
        case .RTSCTS:
            term.c_cflag |=  numericCast(CRTSCTS)
            term.c_iflag &= ~numericCast(IXON | IXOFF | IXANY)
        case .XON:
            term.c_cflag &= ~numericCast(CRTSCTS)
            term.c_iflag |=  numericCast(IXON | IXOFF | IXANY)
            term.set_cc(VSTART, 17)
            term.set_cc(VSTOP, 19)
        }
        
        if rawInput {
            cfmakeraw(&term)
            if blocking {
                term.set_cc(VMIN, self.timeout)
                term.set_cc(VTIME, self.minRead)
            }
        }
        else {
            term.c_lflag |= numericCast(ICANON | ECHO | ECHOE | ISIG)
            term.c_oflag |= numericCast(OPOST)
            if crlfOutput {
                term.c_oflag |= numericCast(ONLCR)
            }
        }
        
        term.c_cflag = size.apply(term.c_cflag)
        term.c_cflag = parity.apply(term.c_cflag)
        
        if parity != .None {
            term.c_iflag |= numericCast(INPCK | ISTRIP)
        }
    }
    
    public func apply(port fd : Int32) throws {
        var term = termios()
        tcgetattr(fd, &term)
        
        self.apply(&term)
        
        term.c_cflag |= numericCast(CLOCAL | CREAD)
        tcsetattr(fd, TCSANOW, &term)
        
        let flag = blocking ? 0 : FNDELAY
        try wfcntl(fd, F_SETFL, flag)
    }
}


