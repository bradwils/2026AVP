//
//  AVPGroupAppApp.swift
//  AVPGroupApp
//
//  Created by brad wils on 23/6/26.
//

import SwiftUI

@main
struct AVPGroupAppApp: App {

    @State private var appModel = AppModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appModel)
        }
        .defaultSize(width: 600, height: 600)

        WindowGroup(id: "stopwatch") {
            MinuteTimerView()
        }
        .defaultSize(width: 300, height: 250)
        .windowResizability(.contentSize)

        // CPR video window (landscape)
        WindowGroup(id: "cpr-video") {
            CPRVideoView()
        }
        .defaultSize(width: 680, height: 460)

        // CPR steps/script window (portrait)
        WindowGroup(id: "cpr-steps") {
            CPRStepsView()
        }
        .defaultSize(width: 420, height: 640)

        ImmersiveSpace(id: appModel.immersiveSpaceID) {
            ImmersiveView()
                .environment(appModel)
                .onAppear { appModel.immersiveSpaceState = .open }
                .onDisappear { appModel.immersiveSpaceState = .closed }
        }
        .immersionStyle(selection: .constant(.full), in: .full)
    }
}
