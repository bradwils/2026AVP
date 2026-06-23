//
//  ImmersiveView.swift
//  AVPGroupApp
//
//  Created by brad wils on 23/6/26.
//

import SwiftUI
import RealityKit
import RealityKitContent

struct ImmersiveView: View {

    var body: some View {
        RealityView { content in
            // Add the initial RealityKit content
            if let immersiveContentEntity = try? await Entity(named: "Immersive", in: realityKitContentBundle) {
                content.add(immersiveContentEntity)
                
                playAllAnimations(on: immersiveContentEntity)

                // Put skybox here.  See example in World project available at
                // https://developer.apple.com/
            }
        }
    }
}

func playAllAnimations(on entity: Entity) {
    // Play animations on this entity if it has any
    if !entity.availableAnimations.isEmpty {
        entity.playAnimation(
            entity.availableAnimations[0].repeat(duration: .infinity),
            transitionDuration: 0.0,
            startsPaused: false
        )
    }
    
    // Recursively play animations on all children
    for child in entity.children {
        playAllAnimations(on: child)
    }
}

#Preview(immersionStyle: .full) {
    ImmersiveView()
        .environment(AppModel())
}
