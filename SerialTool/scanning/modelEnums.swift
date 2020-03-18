//
//  modelEnums.swift
//  SerialTool
//
//  Created by Julian Porter on 18/03/2020.
//  Copyright © 2020 JP Embedded Solutions. All rights reserved.
//

import Cocoa
import SerialPort

extension String : Nameable {
    public var name : String { self }
}

protocol OrderNameable : CaseIterable, Nameable {
    init?(_ name: String?)
}
extension OrderNameable {
    public init?(_ name: String?) {
        let nl = name?.lowercased() ?? ""
        guard let match = (Self.allCases.first { $0.name.lowercased() == nl }) else { return nil }
        self=match
    }
}

internal enum Columns : OrderNameable {
    case Name
    case Paths
    case ClientType
    case Busy
    
    private static let tableRoot = "SerialScanTable"
    
    public var identifier : NSUserInterfaceItemIdentifier { NSUserInterfaceItemIdentifier("\(Columns.tableRoot):\(self)")
    }
    
    public init?(_ name : String?) {
        let nl = name?.lowercased() ?? ""
        guard let match = (Columns.allCases.first { $0.name.lowercased() == nl }) else { return nil }
        self=match
    }
}

internal enum Tris : Nameable {
    case True
    case False
    case Mixed
    
    private static let values : [Bool:Tris] = [
        true : .True,
        false : .False
    ]
    private static let states : [Tris:NSButton.StateValue] = [
        .True : .on,
        .False : .off,
        .Mixed : .mixed
    ]
    private static let symbols : [Tris:String] = [
        .True : "⬆︎",
        .False : "⬇︎"
    ]
    
    public init(_ v : Bool?) {
        self = ((v==nil) ? nil : Tris.values[v!]) ?? .Mixed
    }
    
    public var state : NSButton.StateValue { Tris.states[self] ?? .mixed }
    public var name : String { Tris.symbols[self] ?? "-" }
    
}
