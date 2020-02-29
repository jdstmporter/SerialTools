//
//  main.swift
//  Serial
//
//  Created by Julian Porter on 21/02/2020.
//  Copyright © 2020 JP Embedded Solutions. All rights reserved.
//

import Foundation
import SerialPort
import ArgumentParserKit


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

class Action {
    var command : String { "" }
    var overview : String { "" }
    
    required init(parser: ArgumentParser) {
        parser.add(subparser: self.command, overview: self.overview)
    }
    
    func run(_ : ArgumentParser.Result) throws {}
}



class ActionSet {
    private typealias E = ArgumentParserError
    private let parser : ArgumentParser
    private var actions : [String:Action]
    
    public init(commandName: String,usage: String, overview : String) {
        self.parser = ArgumentParser(commandName: commandName, usage: usage, overview: overview)
        self.actions = [:]
    }
    
    private subscript(_ command : String) -> Action? {
        get { actions[command] }
        set {
            if let action = newValue { actions[command] = action }
            else { actions.removeValue(forKey: command) }
        }
    }
    private func command(for parsed: ArgumentParser.Result) -> String? {
        parsed.subparser(parser)
    }
    private func action(for parsed: ArgumentParser.Result) -> Action? {
        guard let command = self.command(for: parsed) else { return nil }
        return self[command]
    }
    
    public func run(args : [String]) throws {
        do {
            let parsed = try parser.parse(args)
            guard let action = self.action(for: parsed) else { throw E.unknownOption(args.first ?? "") }
            try action.run(parsed)
        }
        catch let error as E { print(error.description) }
    }
    
    public func register(_ action: Action.Type) {
        let a=action.init(parser: parser)
        self[a.command]=a
    }
    
    public func usage() {
        
        
    }
}

class Scan : Action {
    
    override var command : String { "scan" }
    override var overview : String { "scan for serial ports" }
    
    override func run(_ arguments: ArgumentParser.Result) throws {
        let s = try SerialPorts()
        s.enumerated().forEach { kv in
            let port = kv.element
            print("Port \(kv.offset) : \(port)")
            port.forEach { print("    \($0.key) -> \($0.value)") }
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

