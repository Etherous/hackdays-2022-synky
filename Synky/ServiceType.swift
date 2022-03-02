//
//  ServiceType.swift
//  Synky
//
//  Created by Brandon Lyon on 2/28/22.
//

import Foundation

enum ServiceType : String, CaseIterable, Identifiable {
    var id: Self { self }
    
    case none = "None"
    case webdav = "WebDAV"
    case ftp = "FTP"
    
    static func find(_ value: String) -> ServiceType? {
        for e in Self.allCases {
            if e.rawValue.uppercased() == value.uppercased() {
                return e
            }
        }
        return nil
    }
}
