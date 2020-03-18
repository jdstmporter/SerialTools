//
//  terminalViewController.swift
//  SerialTool
//
//  Created by Julian Porter on 18/03/2020.
//  Copyright © 2020 JP Embedded Solutions. All rights reserved.
//

import Cocoa
import SerialPort

class TerminalViewController : NSViewController {
    
    @IBOutlet var fromDevice: NSTextView!
    @IBOutlet var toDevice: NSTextView!
    
    @IBOutlet weak var connectButton: NSButton!
    
    private var port : SerialPort!
    
    private func clear(_ view : NSTextView?) {
        guard let view = view, let txt = view.textStorage else { return }
        txt.deleteCharacters(in: NSRange(location: 0, length: txt.length))
    }
    
    @IBAction func clearFromDevice(_ sender: Any) { clear(fromDevice) }
    @IBAction func clearToDevice(_ sender: Any) { clear(toDevice) }
    
    
    @IBAction func connectAction(_ sender: NSButton) {
    }
    
    @IBAction func baudsAction(_ sender: NSComboBox) {
    }
    @IBAction func wordAction(_ sender: NSComboBox) {
    }
    @IBAction func rawAction(_ sender: NSButton) {
    }
    @IBAction func flowControlAction(_ sender: NSButton) {
    }
}
