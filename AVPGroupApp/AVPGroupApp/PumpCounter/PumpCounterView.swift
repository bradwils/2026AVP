//
//  PumpCounterView.swift
//  AVPGroupApp
//
//  Created by brad wils on 23/6/26.
//

import SwiftUI

struct PumpCounterView: View {
    @Environment(PumpCounterModel.self) private var model
    @Environment(\.openImmersiveSpace) private var openImmersiveSpace
    @Environment(\.dismissImmersiveSpace) private var dismissImmersiveSpace

    @State private var isTransitioning = false

    var body: some View {
        HStack(spacing: 8) {
            VStack(spacing: 16) {
                Text("\(model.pumpCount)")
                    .font(.system(size: 64, weight: .bold, design: .rounded))
                    .monospacedDigit()
                
                Text(model.isHandTracked ? "Hand tracked" : "No hand visible")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                HStack(spacing: 12) {
                    Button(model.isMonitoring ? "Stop" : "Start") {
                        isTransitioning = true
                        if model.isMonitoring {
                            model.stop()
                            Task {
                                // Dismiss immersive space first, then clear transitioning state
                                await dismissImmersiveSpace()
                                isTransitioning = false
                            }
                        } else {
                            Task {
                                // Only start monitoring after immersive space opens
                                let result = await openImmersiveSpace(id: "pumpCounterImmersiveSpace")
                                if result == .opened {
                                    model.start()
                                }
                                isTransitioning = false
                            }
                        }
                    }
                    .disabled(isTransitioning)
                }
            }
            .padding(20)
            .glassBackgroundEffect()
            
            VStack{
                Text("Pumping Sensitivity")
                Button("Sesnsitive") {
                    model.changePumpSensitivity("sensitive")
                }
                
                Button("Normal") {
                    model.changePumpSensitivity("normal")
                }
                
                Button("Weak") {
                    model.changePumpSensitivity("weak")
                }
            }
        }
    }
}

#Preview {
    PumpCounterView()
        .environment(PumpCounterModel())
}
