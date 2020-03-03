//
//  arguments.swift
//  serialtool
//
//  Created by Julian Porter on 02/03/2020.
//  Copyright © 2020 JP Embedded Solutions. All rights reserved.
//

import Foundation
import SerialPort
import ArgumentParserKit

extension UInt : ArgumentKind {
    public init(argument: String) throws {
        guard let i = UInt(argument) else { throw ArgumentConversionError.unknown(value: argument) }
        self=i
    }
    public static var completion: ShellCompletion = .none
    
}

extension UInt8 : ArgumentKind {
    public init(argument: String) throws {
        guard let i = UInt8(argument, radix: 16) else { throw ArgumentConversionError.unknown(value: argument) }
        self=i
    }
    public static var completion: ShellCompletion = .none
    
}

extension Double : ArgumentKind {
    public init(argument: String) throws {
        guard let d = Double(argument) else { throw ArgumentConversionError.unknown(value: argument) }
        self=d
    }
    public static var completion: ShellCompletion = .none
}



class Wrapper<W> : ArgumentKind where W : BaseParameter {
    public private(set) var value : W
    required init(argument: String) throws {
        guard let v = (W.allCases.first { $0.name == argument }) else { throw ArgumentConversionError.unknown(value: argument) }
        value = v
    }
    public static var completion: ShellCompletion { return .none }
    
    
}

extension SerialFlags.Mode : ArgumentKind {
    public init(argument: String) throws {
        guard let v = SerialFlags.Mode(rawValue : argument) else { throw ArgumentConversionError.unknown(value: argument) }
        self = v
    }
    public static var completion: ShellCompletion { return .none }
}

extension Bauds : ArgumentKind {
    public init(argument: String) throws {
        let i = try Int(argument: argument)
        guard let b = Bauds(value: i) else { throw ArgumentConversionError.unknown(value: argument) }
        self = b
    }
    public static var completion: ShellCompletion { return .none }
}

extension FlowControl : ArgumentKind {
    public init(argument: String) throws {
        guard let f = (FlowControl.allCases.first { $0.name == argument }) else { throw ArgumentConversionError.unknown(value: argument) }
        self = f
    }
    public static var completion: ShellCompletion { return .none }
}


