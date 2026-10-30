//
//  EverfitTestApp.swift
//  EverfitTest
//
//  Created by DatLeAnh on 10/29/26.
//

import SwiftUI

@main
struct EverfitTestApp: App {
    private let container = AppContainer()

    var body: some Scene {
        WindowGroup {
            CalendarView(viewModel: container.makeCalendarViewModel())
        }
    }
}
