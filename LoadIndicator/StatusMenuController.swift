//
//  StatusMenuController.swift
//  LoadIndicator
//
//  Created by Paal Gyula on 2018. 02. 26..
//  Copyright © 2018. Paal Gyula. All rights reserved.
//

import Cocoa
import AppKit

class StatusMenuController: NSObject, PreferencesWindowDelegate {
    @IBOutlet weak var statusMenu: NSMenu!
    @IBOutlet weak var weatherView: ImageMenuItemView!
    
    var preferencesWindow: PreferencesWindow!
    var weatherMenuItem: NSMenuItem!
    
    let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    let piIcon = NSImage(named: NSImage.Name("piLogo"))
    
    var timer : Timer?
    var loadPrevious = host_cpu_load_info()
    var loadStack : [Double] = []
    
    // Variables for graph
    var graphwidth : Int = 80
    var showlogo : Bool = true
    
    deinit {
        self.timer?.invalidate()
    }
    
    override func awakeFromNib() {
        self.loadConfig()
        
        let icon = NSImage(named: NSImage.Name(rawValue: "piLogo"))
        icon?.isTemplate = true
        
        weatherView.imageView.image = NSImage(named: NSImage.Name("AppIcon"))
        
        statusItem.title = ""
        statusItem.menu = statusMenu
        
        weatherMenuItem = statusMenu.item(withTitle: "CPU")
        if weatherMenuItem != nil {
            weatherMenuItem.view = weatherView
        }
        
        loadPrevious = hostCPULoadInfo()
        timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.update), userInfo: nil, repeats: true)
    }
    
    @objc func update() {
        let stats = cpuUsage()
        let usage = 100 - stats.idle
        
        self.loadStack.insert(usage, at: 0)
        if self.loadStack.count > 100 {
            self.loadStack.remove(at: 100)
        }
        createGraphImage()
        
        weatherView.cityLabel.stringValue = NSString(format: "Current CPU load: %.2f%%", usage) as String
    }
    
    func createGraphImage() {
        let graphHeight : CGFloat = 22
        let graphWidth : CGFloat = CGFloat(graphwidth)
        
        let font = NSFont(name: "Menlo", size: 10.0)
        let baselineAdjust = 1.0
        let attrsDictionary =  [
            NSAttributedStringKey.font:font,
            NSAttributedStringKey.baselineOffset:baselineAdjust] as [NSAttributedStringKey : AnyObject]

        
        let graph = NSImage(size: NSSize(width: graphWidth, height: graphHeight))
        graph.lockFocus()
        
        if (self.showlogo) {
            piIcon?.draw(in: NSRect(x: 0, y: 3, width: 16, height: 16))
        }
        
        let foregroundColor = NSColor.black
        foregroundColor.setFill()
        
        for i in 0...(self.showlogo ? (self.graphwidth - 16 - 2) : self.graphwidth ) {
            if i > loadStack.count - 1 {
                continue
            }
            
            let height = 22 / 100 * loadStack[i];
            //NSLog("Drawing height: \(height)");
            NSMakeRect(
                CGFloat(self.graphwidth - i - 1),
                0,
                CGFloat(1),
                CGFloat(height)
            ).fill()
        }
        
        NSColor.white.setStroke()
        if ( loadStack.count > 0 ) {
            let percent = NSString(format: "%.0f%%", loadStack[0])
            
            let textRect = NSRect(
                x: showlogo ? 18 : 0,
                y: 0,
                width: CGFloat(self.showlogo ? self.graphwidth-18 : self.graphwidth),
                height: 22)
            
            percent.draw(in: textRect, withAttributes: attrsDictionary)
        }
        
        // Teszt vonal
        // NSMakeRect(CGFloat(18), 0, CGFloat(1), CGFloat(10)).fill()
        
        graph.unlockFocus()
        graph.isTemplate = true
        self.statusItem.image = graph
    }
    
    func hostCPULoadInfo() -> host_cpu_load_info {
        let  HOST_CPU_LOAD_INFO_COUNT = MemoryLayout<host_cpu_load_info>.stride / MemoryLayout<integer_t>.stride
        
        var size = mach_msg_type_number_t(HOST_CPU_LOAD_INFO_COUNT)
        let hostInfo = host_cpu_load_info_t.allocate(capacity: 1)
        
        let result = hostInfo.withMemoryRebound(to: integer_t.self, capacity: HOST_CPU_LOAD_INFO_COUNT) {
            host_statistics(mach_host_self(), HOST_CPU_LOAD_INFO, $0, &size)
        }
        
        if result != KERN_SUCCESS{
            print("Error  - \(#file): \(#function) - kern_result_t = \(result)")
            return host_cpu_load_info()
        }
        let data = hostInfo.move()
        hostInfo.deallocate(capacity: 1)
        return data
    }
    
    public func cpuUsage() -> (system: Double, user: Double, idle : Double, nice: Double){
        let load = hostCPULoadInfo()
        
        let usrDiff = Double(load.cpu_ticks.0 - loadPrevious.cpu_ticks.0)
        let systDiff = Double(load.cpu_ticks.1 - loadPrevious.cpu_ticks.1)
        let idleDiff = Double(load.cpu_ticks.2 - loadPrevious.cpu_ticks.2)
        let niceDiff = Double(load.cpu_ticks.3 - loadPrevious.cpu_ticks.3)
        
        let totalTicks = usrDiff + systDiff + idleDiff + niceDiff
        //NSLog("Total ticks is \(totalTicks)")
        let sys = systDiff / totalTicks * 100.0
        let usr = usrDiff / totalTicks * 100.0
        let idle = idleDiff / totalTicks * 100.0
        let nice = niceDiff / totalTicks * 100.0
        
        //NSLog("CPU Load: \(usr)+\(sys)+\(idle)")
        loadPrevious = load
        return (sys, usr, idle, nice)
    }
    
    func preferencesDidUpdate() {
        //updateWeather()
        self.loadConfig()
    }
    
    private func loadConfig() {
        let defaults = UserDefaults.standard
        self.graphwidth = defaults.integer(forKey: "graphwidth") ?? 80
        self.showlogo = defaults.bool(forKey: "showlogo") ?? true;
    }
    
    @IBAction func quitClicked(_ sender: NSMenuItem) {
        NSApplication.shared.terminate(self)
    }
    
    @IBAction func updateClicked(_ sender: NSMenuItem) {
        NSLog("Manual update called")
        update()
    }
    
    @IBAction func preferencesClicked(_ sender: Any) {
        NSLog("Preferences called, showing...")
        
        if (preferencesWindow == nil) {
            preferencesWindow = PreferencesWindow(windowNibName: NSNib.Name(rawValue: "PreferencesWindow"))
        }
        
        preferencesWindow.delegate = self
        preferencesWindow.showWindow(nil)
    }
}
