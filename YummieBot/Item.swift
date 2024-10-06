//
//  Item.swift
//  YummieBot
//
//  Created by Adam Thuvesen on 2024-10-06.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
