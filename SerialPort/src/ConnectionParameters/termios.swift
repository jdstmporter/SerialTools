//
//  termios.swift
//  Serial
//
//  Created by Julian Porter on 26/02/2020.
//  Copyright © 2020 JP Embedded Solutions. All rights reserved.
//

import Foundation

extension tcflag_t {
    mutating func set(_ v : UInt32) {
        self |= numericCast(v)
    }
    mutating func clear(_ v : UInt32) {
        self &= ~numericCast(v)
    }
}



extension termios {
    
    static let NCC : Int = numericCast(NCCS)
    
    mutating func set_cc(_ offset : Int, _ value : Int8) {
        let p = UnsafeMutableRawPointer(&(self.c_cc))
        let b = UnsafeMutableRawBufferPointer(start: p, count: termios.NCC)
        let a = b.bindMemory(to: Int8.self)
        a[offset]=value
    }
    mutating func set_cc(_ offset : Int32, _ value : Int8) {
        set_cc(Int(offset),value)
    }
    
    
}




