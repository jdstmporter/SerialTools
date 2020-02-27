//
//  main.swift
//  Serial
//
//  Created by Julian Porter on 21/02/2020.
//  Copyright © 2020 JP Embedded Solutions. All rights reserved.
//

import Foundation
import Serial



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
/*
protocol Action {
    var command : String { get }
    var overview : String { get }
    
    init(parser: ArgumentParser)
    func run(_ : ArgumentParser.Result) throws
}

class ActionSet {
    private let parser : ArgumentParser
    private var actions : [Action]
    
    public init(usage: String, overview : String) {
        self.parser = ArgumentParser(usage: usage, overview: overview)
        self.actions = []
    }
    
    public func run() throws {
        let args = Array(CommandLine.arguments.dropFirst())
        let parsed = try parser.parse(args)
        if let subparser = parsed.subparser(parser),
            let action = (actions.first { $0.command == subparser }) {
            try action.run(parsed)
        }
        else {
            print("GOK")
        }
    }
    
    public func register(_ action: Action.Type) {
        actions.append(action.init(parser: parser))
    }
    
    public func usage() {
        parser.printUsage(on: stdoutStream)
    }
}

struct Scan : Action {
    
    let command = "scan"
    let overview = "scan for serial ports"
    
    init(parser: ArgumentParser) {
        parser.add(subparser: command, overview: overview)
    }
    
    func run(_ arguments: ArgumentParser.Result) throws {
        // nothing
    }
    
}

do {
    let actions = ActionSet(usage: "serial", overview: "Simple serial port utility")
    actions.register(Scan.self)
    try actions.run()
    
    
}
catch ArgumentParserError.expectedValue(let value) {
    print("Missing value for argument \(value).")
} catch ArgumentParserError.expectedArguments(let parser, let stringArray) {
    print("Parser: \(parser) Missing arguments: \(stringArray.joined()).")
} catch {
    print(error.localizedDescription)
}
 */

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
    
    let connection = try Connection(port)
    connection.delegate=Delegate()
    let flags = SerialFlags(blocking: true)
    try connection.connect(flags: flags)
    print("Connected")
    connection.listen()
    
    while true {
        try connection.send("fred")
        _ = readLine()
    }
    
}
    
catch let e { print(e) }

