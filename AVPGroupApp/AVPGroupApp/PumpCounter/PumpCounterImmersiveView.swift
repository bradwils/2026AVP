//
//  PumpCounterImmersiveView.swift
//  AVPGroupApp
//
//  Created by brad wils on 23/6/26.
//

import RealityKit
import SwiftUI

struct PumpCounterImmersiveView: View {
    @Environment(PumpCounterModel.self) private var model

    var body: some View {
        RealityView { _ in }
            // Start ARKit session when immersive space appears
            .task { await model.startSession() }
            // Clean up session when immersive space closes
            .onDisappear { model.stopSession() }
    }
}
