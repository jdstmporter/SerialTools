//
//  parameters.swift
//  Serial
//
//  Created by Julian Porter on 26/02/2020.
//  Copyright © 2020 JP Embedded Solutions. All rights reserved.
//

import Foundation

public protocol BaseParameter : CaseIterable, Hashable {
    var name : String { get }
}

extension BaseParameter {
    public var name : String { "\(self)" }
}

public protocol SimpleSerialParameter : BaseParameter {
    
    static var convert : [Self:UInt32] { get }
    static var MASK : UInt32 { get }
    
    var mask : UInt { get }
    var name : String { get }
    
    
    func apply(_ : UInt) -> UInt
 
}
extension Int32 {
    var u : UInt32 { numericCast(self) }
}

extension SimpleSerialParameter {
    
    public var mask : UInt { numericCast(Self.convert[self] ?? 0) }
    public func apply(_ word : UInt) -> UInt { (word & ~numericCast(Self.MASK)) | self.mask }
    
    
}
    

public protocol SerialParameter : RawRepresentable, SimpleSerialParameter
    where RawValue == Int {
    
    var value : Int { get }
    
    init?(_ : UInt)
    init?(value: Int)
    
}

extension SerialParameter {
    
    public var value : Int { self.rawValue }
    
    public init?(_ m : UInt ) {
        let v = numericCast(m) & Self.MASK
        guard let b = (Self.convert.first { $0.value == v })?.key else { return nil }
        self = b
    }
    public init?(value: Int) {
        guard let v = (Self.allCases.first { $0.rawValue == value }) else { return nil }
        self=v
    }
    
    public static func ==(_ l : Self, _ r : Self) -> Bool { l.value == r.value }
    public static func !=(_ l : Self, _ r : Self) -> Bool { l.value != r.value }
    public var hashValue: Int { self.rawValue }
}
