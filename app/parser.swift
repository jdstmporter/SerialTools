//
//  parser.swift
//  SerialPort
//
//  Created by Julian Porter on 01/03/2020.
//  Copyright © 2020 JP Embedded Solutions. All rights reserved.
//

import Foundation
import SerialPort
import ArgumentParserKit



class Action {
    public typealias Parser = ArgumentParser
    public typealias Positional = PositionalArgument
    public typealias Optional = OptionArgument
    
    var command : String { "" }
    var overview : String { "" }
    
    internal private(set) var subparser : Parser!
    
    required init(parser: Parser) {
        self.subparser = parser.add(subparser: self.command, overview: self.overview)
    }
    
    func run(_ : Parser.Result) throws {}
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

