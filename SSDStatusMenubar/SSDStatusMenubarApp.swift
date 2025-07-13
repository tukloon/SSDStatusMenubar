//
//  SSDStatusMenubarApp.swift
//  SSDStatusMenubar
//
//  Created by tukloon on 2025/07/12.
//

import SwiftUI

@main
struct SSDStatusMenubarApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // WindowGroupを削除し、空のSceneを返す
        Settings { }
    }
}
