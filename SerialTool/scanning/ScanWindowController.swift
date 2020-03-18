//
//  ScanWindowController.swift
//  SerialTool
//
//  Created by Julian Porter on 17/03/2020.
//  Copyright © 2020 JP Embedded Solutions. All rights reserved.
//

import Cocoa
import SerialPort




public class ScanViewController : NSViewController, NSTableViewDelegate, NSTableViewDataSource {
    
    @IBOutlet weak var table: NSTableView!
    private var ports : SerialPorts!
    private var root : RootItem = RootItem()
    
    private func initialiseSerialSubsystem() -> Bool {
        if ports==nil {
            do {
                try ports=SerialPorts()
            }
            catch let e {
                print("Cannot launch serial subsystem: \(e)")
                return false
            }
        }
        return true
    }
    
    @IBAction func doRescan(_ sender: Any!) {
        guard initialiseSerialSubsystem() else { return }
        do {
            try ports.reload()
            root=RootItem(ports)
            DispatchQueue.main.async { self.table.reloadData() }
        }
        catch let e { print("\(e)") }
        
    }
    
    public override func viewDidAppear() {
        super.viewDidAppear()
        self.doRescan(nil)
    }
    
    // events
    
    @IBAction func singleClick(_ sender: Any) {
    }
    
    
    // data source delegate actions
    
    public func numberOfRows(in tableView: NSTableView) -> Int {
        root.count
        
    }
    
    public func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        return 40
    }
    
    
    
    
    public func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard let column = Columns(tableColumn?.title), let item = root[row] else { return nil }
        guard let value = item[column]?.name else { return nil }
        let ident = column.identifier
        let view = (tableView.makeView(withIdentifier: ident, owner: self) as? NSTextField) ?? NSTextField(labelWithString: "")
        
        view.stringValue=value
        view.identifier=ident
        return view
    }
    
    
}
