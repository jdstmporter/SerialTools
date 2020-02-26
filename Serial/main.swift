//
//  main.swift
//  Serial
//
//  Created by Julian Porter on 21/02/2020.
//  Copyright © 2020 JP Embedded Solutions. All rights reserved.
//

import Foundation

enum Errors : Error {
    case noSuchPort
}

do {
    let s = try IOSystem()
    s.enumerated().forEach { kv in
        let port = kv.element
        print("Port \(kv.offset) : \(port)")
        port.forEach { print("    \($0.key) -> \($0.value)") }
    }
    guard let port = s["usbserial-1310"] else { throw Errors.noSuchPort }
    print("")
    print("The port is \(port)")
    
    let connection = try Connection(port)
    let flags = SerialFlags()
    try connection.connect(flags: flags,blocking: true)
    print("Connected")
    connection.listen { bytes in
        let s = String(bytes: bytes, encoding: .ascii) ?? "-"
        print("Got \(s)")
    }
    
    while true {
        try connection.out("fred")
        _ = readLine()
    }
    
}
    
catch let e { print(e) }

