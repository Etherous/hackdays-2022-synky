//
//  util.swift
//  Synky
//
//  Created by Brandon Lyon on 2/28/22.
//

import SwiftUI

func ??<T>(lhs: Binding<Optional<T>>, rhs: T) -> Binding<T> {
    Binding(
        get: { lhs.wrappedValue ?? rhs },
        set: { lhs.wrappedValue = $0 }
    )
}

let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .medium
    return formatter
}()

func accountDisplayName(_ account: AccountModel) -> String {
    return account.name ?? account.username ?? "(Untitled)"
}

func serviceDisplayName(_ service: ServiceModel) -> String {
    return service.name ?? service.host ?? "(Untitled)"
}

func scheduleDisplayName(_ schedule: ScheduleModel) -> String {
    return schedule.name ?? "(Untitled)"
}
