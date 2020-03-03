//
//  main.swift
//  Serial
//
//  Created by Julian Porter on 21/02/2020.
//  Copyright © 2020 JP Embedded Solutions. All rights reserved.
//

import Foundation
import SerialPort



enum Errors : Error {
    case noSuchPort
}



// command line parsing





do {
    let actions = ActionSet(commandName: "serialtool", usage: "serial", overview: "Simple serial port utility")
    actions.register(Scan.self)
    actions.register(Connect.self)
    try actions.run(args: Array(CommandLine.arguments.dropFirst()))
}

 
/*
do {
    let s = try SerialPorts()
    s.enumerated().forEach { kv in
        let port = kv.element
        print("Port \(kv.offset) : \(port)")
        port.forEach { print("    \($0.key) -> \($0.value)") }
    }
    guard let port = s["usbserial-1310"] else { throw Errors.noSuchPort }
    print("")
    print("The port is \(port)")
    
    let flags = SerialFlags(blocking: true)
    let connection = try Connection(port: port, flags: flags)
    connection.delegate=Delegate()
    
    try connection.connect(async: true)
    print("Connected")
    
    while true {
        try connection.send("fred")
        _ = readLine()
    }
    
}
    
catch let e { print(e) }
*/
