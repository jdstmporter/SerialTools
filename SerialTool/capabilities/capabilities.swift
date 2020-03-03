//
//  capabilities.swift
//  serialtool
//
//  Created by Julian Porter on 02/03/2020.
//  Copyright © 2020 JP Embedded Solutions. All rights reserved.
//

import Foundation
import SerialPort

enum Errors : Error { case noSuchPort }

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
    
    override var command : String { "connect" }
    override var overview : String { "Simple bi-directional communications to a port (ASCII only)" }
    
    private var port : Positional<String>!
    private var mode : Optional<SerialFlags.Mode>!
    private var rate : Optional<Bauds>!
    private var raw : Optional<Bool>!
    private var flow : Optional<FlowControl>!
    private var timeout : Optional<Double>!
    private var minRead : Optional<UInt>!
    
    
    required init(parser: Parser) {
        super.init(parser: parser)
        port = subparser.add(positional: "port", kind: String.self, optional: false, usage: "Name of the port to connect to")
        mode = subparser.add(option: "--mode", shortName: "-m", kind: SerialFlags.Mode.self, usage: "Standard mode, e.g. 8N1 (default = 8N1)")
        rate = subparser.add(option: "--bauds", shortName: "-b", kind: Bauds.self, usage: "The baud rate to use (default = 9600)")
        flow = subparser.add(option: "--flow", shortName: "-f", kind: FlowControl.self, usage: "Flow control (default = None)")
        timeout = subparser.add(option: "--timeout", shortName: "-t", kind: Double.self, usage: "Timeout (default = 0.0)")
        minRead = subparser.add(option: "--minBytes", shortName: "-M", kind: UInt.self, usage: "Minimum bytes to read (default = 1)")
    }
    
    override func run(_ arguments: Action.Parser.Result) throws {
        guard let port = arguments.get(self.port) else { return }
        let mode = arguments.get(self.mode) ?? ._8N1
        let rate = arguments.get(self.rate) ?? .b9600
        let raw = arguments.get(self.raw) ?? false
        let flow = arguments.get(self.flow) ?? .None
        let timeout = arguments.get(self.timeout) ?? 0.0
        let minRead = arguments.get(self.minRead) ?? 1
        
        var flags = SerialFlags(rate,raw: raw)
        flags.set(mode: mode)
        flags.set(flowControl: flow)
        flags.set(timeout: timeout, minRead: minRead)
        
        let s = try SerialPorts()
        guard let com = s[port] else { throw Errors.noSuchPort }
        let connection = try Connection(port: com, flags: flags)
        connection.delegate=Delegate()
        
        try connection.connect(async: true)
        print("Connected to \(port)")
        
        do {
            while true {
                try connection.send("fred")
                _ = readLine()
            }
        }
        catch let e {
            try? connection.disconnect()
            throw e
        }
    }
}

