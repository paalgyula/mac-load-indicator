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

class PreferencesWindow: NSWindowController {

    override func windowDidLoad() {
        super.windowDidLoad()

        self.window?.center()
        self.window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
    }
    
//    override var windowNibName : NSNib.Name? {
//        return NSNib.Name("PreferencesWindow")
//    }
    
}
