//
//  PreferencesWindow.swift
//  LoadIndicator
//
//  Created by Paal Gyula on 2018. 02. 27..
//  Copyright © 2018. Paal Gyula. All rights reserved.
//

import Cocoa
import AppKit

protocol PreferencesWindowDelegate {
    func preferencesDidUpdate()
}

class PreferencesWindow: NSWindowController, NSWindowDelegate {
    
    @IBOutlet weak var widthTextField: NSTextField!
    @IBOutlet weak var showLogoButton: NSButton!
    
    let defaults = UserDefaults.standard
    
    var delegate : PreferencesWindowDelegate?
    
    override func windowDidLoad() {
        super.windowDidLoad()
        IndicatorConfig.loadConfig()
        
        widthTextField.integerValue = IndicatorConfig.graphwidth
        showLogoButton.state = IndicatorConfig.showlogo ? NSButton.StateValue.on : NSButton.StateValue.off
        
        self.window?.center()
        self.window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    override var windowNibName : NSNib.Name? {
        return NSNib.Name(rawValue: "PreferencesWindow")
    }
    
    func windowWillClose(_ notification: Notification) {
        // Saving variables
        IndicatorConfig.graphwidth = widthTextField.integerValue
        IndicatorConfig.showlogo = showLogoButton.state.rawValue > 0 ? true : false
        
        delegate?.preferencesDidUpdate()
    }
    
    @IBAction func closeClicked(_ sender: NSButton) {
        self.close()
    }
}

