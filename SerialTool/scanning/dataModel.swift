//
//  dataModel.swift
//  SerialTool
//
//  Created by Julian Porter on 18/03/2020.
//  Copyright © 2020 JP Embedded Solutions. All rights reserved.
//

import SerialPort

internal struct PortPaths : Nameable {
    let inbound  : String?
    let outbound : String?
    
    var name: String { "\(inbound ?? "-")\n\(outbound ?? "-")" }
}

internal struct PortItem {
    
    private var dict : [Columns:Nameable] = [:]
    
    init() {}
    
    init(_ port : SerialPort) {
        self.dict[.Name] = port.name ?? "-"
        self.dict[.ClientType] = port.clientType ?? .Serial
        self.dict[.Paths] = PortPaths(inbound: port.inbound, outbound: port.outbound)
        self.dict[.Busy] = Tris(try? port.isBusy())
        //print(port.name ?? "-" )
        //port.forEach { print("\($0.key) -> \($0.value) ") }
        
    }
   
    
    subscript(_ key : Columns) -> Nameable? {
        return self.dict[key] 
    }
    
    
}

internal struct RootItem {
    let name = "Serial Ports"
    var children : [PortItem]
    
    init() {
        self.children=[]
    }
    
    init(_ ports : SerialPorts) {
        self.children = ports.map { PortItem($0) }
    }
    
    var count : Int { return children.count }
    subscript(_ idx : Int) -> PortItem? {
        guard idx>=0 && idx<count else { return nil }
        return children[idx]
    }
}
