//
//  SyncDirection.swift
//  Synky
//
//  Created by Brandon Lyon on 3/1/22.
//

enum SyncDirection : String, CaseIterable, Identifiable  {
    var id: Self { self }
    
    case up = "UP"
    case down = "DOWN"
    case bi = "BI"
    
    static func find(_ value: String) -> SyncDirection? {
        for e in Self.allCases {
            if e.rawValue.uppercased() == value.uppercased() {
                return e
            }
        }
        return nil
    }
    
    var description : String {
        switch(self) {
        case .up:
            return "To Remote"
        case .down:
            return "From Remote"
        case .bi:
            return "Bi-Directional"
        }
    }
}
