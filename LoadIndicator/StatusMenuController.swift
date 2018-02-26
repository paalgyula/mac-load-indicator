//
//  StatusMenuController.swift
//  LoadIndicator
//
//  Created by Paal Gyula on 2018. 02. 26..
//  Copyright © 2018. Paal Gyula. All rights reserved.
//

import Cocoa
import AppKit

class StatusMenuController: NSObject {
    @IBOutlet weak var statusMenu: NSMenu!
    @IBOutlet weak var weatherView: ImageMenuItemView!
    
    var weatherMenuItem: NSMenuItem!
    
    let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    let piIcon = NSImage(named: NSImage.Name("piLogo"))
    
    var timer : Timer?
    var loadPrevious = host_cpu_load_info()
    var loadStack : [Double] = []
    
    deinit {
        self.timer?.invalidate()
    }
    
    override func awakeFromNib() {
        statusItem.title = ""
        statusItem.menu = statusMenu
        
        let icon = NSImage(named: NSImage.Name(rawValue: "piLogo"))
        icon?.isTemplate = false
        
        weatherView.imageView.image = NSImage(named: NSImage.Name("AppIcon"))
        
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
        
        weatherView.cityLabel.stringValue = "Current load: \(usage)"
    }
    
    func createGraphImage() {
        let graphHeight : CGFloat = 22
        let graphWidth : CGFloat = 80
        
        let graph = NSImage(size: NSSize(width: graphWidth, height: graphHeight))
        graph.lockFocus()
        
        piIcon?.draw(in: NSRect(x: 0, y: 3, width: 16, height: 16))
        
        let foregroundColor = NSColor.black
        foregroundColor.setFill()
        
        for i in 0...(80 - 16 - 2) {
            if i > loadStack.count - 1 {
                continue
            }
            
            let height = 22 / 100 * loadStack[i];
            //NSLog("Drawing height: \(height)");
            NSMakeRect(CGFloat(80 - i - 1), 0, CGFloat(1), CGFloat(height)).fill()
        }
        
        NSColor.white.setStroke()
        if ( loadStack.count > 0 ) {
            let percent = NSString(format: "%.0f%%", loadStack[0])
            let textRect = NSRect(x: 18, y: 0, width: CGFloat(80-18), height: 22)
            percent.draw(in: textRect)
        }
        
        // Teszt vonal
        // NSMakeRect(CGFloat(18), 0, CGFloat(1), CGFloat(10)).fill()
        
        graph.unlockFocus()
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
    
    @IBAction func quitClicked(_ sender: NSMenuItem) {
        NSApplication.shared.terminate(self)
    }
    
    @IBAction func updateClicked(_ sender: Any) {
        NSLog("Manual update called")
        update()
    }
}
