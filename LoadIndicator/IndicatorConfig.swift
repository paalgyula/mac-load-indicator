//
//  IndicatorConfig.swift
//  LoadIndicator
//
//  Created by Paal Gyula on 2018. 03. 15..
//  Copyright © 2018. Paal Gyula. All rights reserved.
//

import Foundation
import AppKit

class IndicatorConfig {
    private static let GRAPH_WIDTH = "graphwidth"
    private static let SHOW_LOGO = "showlogo"
    
    static var isWhite : Bool {
        get {
            return NSAppearance.current.name.rawValue.hasPrefix("NSAppearanceNameVibrantDark")
        }
    }
    
    public static var graphwidth: Int = 40
    public static var showlogo: Bool = true
    
    public static func loadConfig() {
        let defaults = UserDefaults.standard
        
        self.graphwidth = defaults.integer(forKey: GRAPH_WIDTH)
        self.showlogo = defaults.bool(forKey: SHOW_LOGO)
        //self.cpuGraphColor = defaults.
    }
    
    public static func saveConfig() {
        let defaults = UserDefaults.standard
        
        defaults.set(self.graphwidth, forKey: GRAPH_WIDTH)
        defaults.set(self.showlogo, forKey: SHOW_LOGO)
    }
}
