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

class Delegate : ConnectionDelegate {
    
    func received(_ result: Result<[UInt8], BaseError>) {
        switch result {
        case .success(let bytes):
            let s = String(bytes: bytes, encoding: .ascii) ?? "-"
            print("Got \(s)")
        case .failure(let e):
            print("Error : \(e)")
            SysLog.error(e)
        }
    }
}

// command line parsing


class Scan : Action {
    
    override var command : String { "scan" }
    override var overview : String { "scan for serial ports" }
    
    override func run(_ arguments: Action.Parser.Result) throws {
        let s = try SerialPorts()
        s.enumerated().forEach { kv in
            let port = kv.element
            print("Port \(kv.offset) : \(port)")
            port.forEach { print("    \($0.key) -> \($0.value)") }
        }
    }
}

class Connect : Action {
    
    override var command : String { "connect" }
    override var overview : String { "connect to a port" }
    
    private var port : Positional<String>!
    private var mode : Optional<SerialFlags.Mode>!
    private var rate : Optional<Int>!
    private var raw : Optional<Bool>!
    private var crlf : Optional<Bool>!
    private var blocking : Optional<Bool>!
    private var flow : Optional<Wrapper<FlowControl>>!
    private var timeout : Optional<Double>!
    private var minRead : Optional<Int>!
    
    
    
    
    required init(parser: Parser) {
        super.init(parser: parser)
        port = subparser.add(positional: "port", kind: String.self, optional: false, usage: "Name of the port to connect to")
        mode = subparser.add(option: "--mode", shortName: "-m", kind: SerialFlags.Mode.self, usage: "Standard mode, e.g. 8N1 (default = 8N1)")
        rate = subparser.add(option: "--bauds", shortName: "-b", kind: Int.self, usage: "The baud rate to use (default = 9600)")
        blocking = subparser.add(option: "--block", shortName: "-B", kind: Bool.self, usage: "Make the connection blocking")
        crlf = subparser.add(option: "--crlf", shortName: "-c", kind: Bool.self, usage: "Append CR/LF to all input lines")
       flow = subparser.add(option: "--flow", shortName: "-f", kind: Wrapper<FlowControl>.self, usage: "Flow control (default = None)")
        timeout = subparser.add(option: "--timeout", shortName: "-t", kind: Double.self, usage: "Timeout (default = 0.0)")
        minRead = subparser.add(option: "--minBytes", shortName: "-M", kind: Int.self, usage: "Minimum bytes to read (default = 1)")
    }
    
    override func run(_ arguments: Action.Parser.Result) throws {
        guard let port = arguments.get(self.port) else { return }
        let mode = arguments.get(self.mode) ?? ._8N1
        guard let rate = Bauds(value: arguments.get(self.rate) ?? 9600) else { return }
        let raw = arguments.get(self.raw) ?? false
        //let crlf = arguments.get(self.crlf)
        let flow = arguments.get(self.flow)?.value ?? .None
        let timeout = arguments.get(self.timeout) ?? 0.0
        let minRead = arguments.get(self.minRead) ?? 1
        
        var flags = SerialFlags(rate,raw: raw)
        flags.set(mode: mode)
        flags.set(flowControl: flow)
        flags.set(timeout: timeout, minRead: numericCast(minRead))
        
        let s = try SerialPorts()
        guard let com = s[port] else { throw Errors.noSuchPort }
        let connection = try Connection(port: com, flags: flags)
        connection.delegate=Delegate()
        
        try connection.connect(async: true)
        print("Connected to \(port)")
        
        while true {
            try connection.send("fred")
            _ = readLine()
        }
    }
}



do {
    let actions = ActionSet(commandName: "serialtool", usage: "serial", overview: "Simple serial port utility")
    actions.register(Scan.self)
    try actions.run(args: Array(CommandLine.arguments.dropFirst()))
}

 

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

