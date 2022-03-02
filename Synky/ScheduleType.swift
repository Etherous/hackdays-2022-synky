//
//  ScheduleType.swift
//  Synky
//
//  Created by Brandon Lyon on 2/28/22.
//

import Foundation

enum ScheduleType : String, CaseIterable, Identifiable {
    var id: Self { self }
    
    case off = "Off"
    case hourly = "Hourly"
    
    static func find(_ value: String) -> ScheduleType? {
        for e in Self.allCases {
            if e.rawValue.uppercased() == value.uppercased() {
                return e
            }
        }
        return nil
    }
}
