//
//  SpacesView.swift
//  WavyBackgrounds
//
//  Created by Philipp Remy on 13.11.24.
//

import SwiftUI

struct SpacesView: View {
    
    @EnvironmentObject private var globalState: GlobalViewState
    
    var body: some View {
        ZStack {
            MTLSpacesView()
                .environment(self.globalState)
        }
    }
}

#Preview {
    SpacesView()
}
