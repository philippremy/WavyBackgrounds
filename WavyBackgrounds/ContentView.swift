//
//  ContentView.swift
//  WavyBackgrounds
//
//  Created by Philipp Remy on 13.11.24.
//

import SwiftUI

import WavyBackgroundsKit

struct ContentView: View {
    
    @Environment(\.colorScheme) var colorScheme
    @State private var globalState: GlobalViewState = GlobalViewState.sharedInstance
    
    var body: some View {
        ZStack {
            GeometryReader { geometry in
                VStack {
                    SpacesView()
                        .environment(self.globalState)
                        .frame(width: geometry.size.width, height: geometry.size.height * 0.25)
                        .background(Color(nsColor: self.globalState.currentBackgroundColor))
                        .compositingGroup()
                        .shadow(radius: 5)
                    HStack {
                        
                    }
                    .frame(width: geometry.size.width, height: geometry.size.height * 0.75)
                }
            }
            .toolbar(content: {
                ToolbarItem(id: "titleItem", placement: .navigation, content: {
                    VStack(alignment: .leading) {
                        Text("STUB TITLE").fontWeight(.bold)
                        Text("STUB FOOTLINE").fontWeight(.light).font(.caption)
                    }
                })
                ToolbarItem(placement: .automatic, content: {
                    Button(action: {
                        showSettingsWindow()
                    }, label: {
                        Label(title: {
                            Text("Settings")
                        }, icon: {
                            Image(systemName: "gearshape")
                        })
                    })
                })
            })
            .navigationTitle("")
        }
        .frame(minWidth: 1000, minHeight: 700)
        .onAppear() {
            
            // Update FPS and IncludeOtherWindowsInService
            let _ = try! self.globalState.spaceCaptureServiceConnection.sendSync(message: prepareSpaceIOSurfaceCaptureServiceRequest(requestType: .UpdateRefreshFPS, fps: self.globalState.fps))
            let _ = try! self.globalState.spaceCaptureServiceConnection.sendSync(message: prepareSpaceIOSurfaceCaptureServiceRequest(requestType: .ToggleShouldIncludeOtherWindows, shouldIncludeOtherWindows: self.globalState.shouldIncludeForeignWindows))
            
            
        }
        
        // React to changes of Color Scheme
        .onChange(of: self.colorScheme, {
            let windowColor = NSColor.windowBackgroundColor.usingColorSpace(.deviceRGB)!
            self.globalState.currentBackgroundColor = NSColor(red: windowColor.redComponent, green: windowColor.greenComponent, blue: windowColor.blueComponent, alpha: windowColor.alphaComponent)
        })
    }
}

#Preview {
    ContentView()
}
