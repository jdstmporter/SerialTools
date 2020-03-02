//
//  logging.swift
//  Serial
//
//  Created by Julian Porter on 26/02/2020.
//  Copyright © 2020 JP Embedded Solutions. All rights reserved.
//

import Foundation
import os.log



public class SysLog {
    private let log : OSLog
    private static let objectFormat : StaticString = "%@"
    private static let exceptionFormat : StaticString = "%{timeval}.*P %@"
    private static let errnoFormat : StaticString = "%{timeval}.*P %{errno}d"
    
    public init(_ name: String,_ category: OSLog.Category) {
        self.log=OSLog(subsystem: name, category: category)
    }
    public init(_ name: String,_ category: String = "IO") {
        self.log=OSLog(subsystem: name, category: category)
    }
    public init() {
        self.log=OSLog.default
    }
    
    public func logCanLog(type: OSLogType) -> Bool {
        return self.log.isEnabled(type: type)
    }
    public var signposted : Bool { log.signpostsEnabled }
    
    private func record(level: OSLogType,_ obj : CustomStringConvertible) {
        os_log(level, log: log, SysLog.objectFormat, obj.description)
    }
    
    private static var the : SysLog = SysLog()
    public static func Initialise(_ name: String) { the=SysLog(name) }
    
    public static func info(_ obj : CustomStringConvertible) { the.record(level: .info, obj) }
    public static func debug(_ obj : CustomStringConvertible) { the.record(level: .debug, obj) }
    public static func error(_ obj : CustomStringConvertible) { the.record(level: .error, obj) }
    public static func fault(_ obj : CustomStringConvertible) { the.record(level: .fault, obj) }
}


