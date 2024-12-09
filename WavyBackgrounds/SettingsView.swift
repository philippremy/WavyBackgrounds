//
//  SettingsView.swift
//  WavyBackgrounds
//
//  Created by Philipp Remy on 20.10.24.
//

import CoreGraphics
import SwiftUI

import WavyBackgroundsKit

struct SettingsView: View {
    
    @EnvironmentObject var viewModel: GlobalViewState;
    @State private var screenRecordingAlert: Bool = false
    
    var body: some View {
        ZStack {
            GeometryReader { geometry in
                switch self.viewModel.selectedSettingsView {
                case "General":
                    VStack(alignment: .center, spacing: 25) {
                        VStack(alignment: .leading) {
                            Toggle("Capture foreign windows in Space view", isOn: self.$viewModel.shouldIncludeForeignWindows)
                            Text("Activating this option will capture foreign windows in the Space view. This requires user approval (you will be prompted if it is not granted yet) and an app restart.")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                                .monospaced()
                        }
                        .frame(width: geometry.size.width*0.5)
                        VStack(alignment: .leading) {
                            Slider(value: self.$viewModel.sliderValue, in: 0...Float(self.viewModel.sliderValues.count-1),
                                   step: 1, label: {
                                Label("Refresh Rate", image: "")
                                    .labelStyle(.titleOnly)
                            }, minimumValueLabel: {
                                Text("1 fps")
                            }, maximumValueLabel: {
                                Text("60 fps")
                            })
                            .labelsHidden()
                            Text("\(self.viewModel.sliderValues[Int(self.viewModel.sliderValue)]) fps")
                                .frame(width: geometry.size.width*0.5)
                                .font(.footnote)
                                .multilineTextAlignment(.center)
                                .foregroundStyle({
                                    switch self.viewModel.sliderValues[Int(self.viewModel.sliderValue)] {
                                    case let x where x <= 10:
                                        return Color.green;
                                    case let x where x <= 30:
                                        return Color.yellow;
                                    case let x where x <= 60:
                                        return Color.red;
                                    default:
                                        return Color.primary;
                                    }
                                }())
                            Text("Warning:\n")
                                .font(.footnote)
                                .foregroundStyle(.yellow)
                                .monospaced() +
                            Text("Using this option with high framerates (> 10 fps) may cause the WindowServer to lag and can cause the overall system experience to deterioate. Use at your own risk!")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                                .monospaced()
                        }
                        .frame(width: geometry.size.width*0.5)
                    }
                    .frame(width: geometry.size.width, height: geometry.size.height)
                case "Licenses":
                    Text("Licenses TODO.")

                default:
                    Text("Please choose one option.")
                }
            }
        }
        .frame(width: 800, height: 400)
        .toolbar(id: "settingsToolbar") {
            ToolbarItem(id: "gearItem", placement: .principal, content: {
                HStack(alignment: .center) {
                    Button {
                        self.viewModel.selectedSettingsView = "General"
                    } label: {
                        VStack(spacing: 0) {
                            Image(systemName: "gearshape")
                                .imageScale(.large)
                            Text("General")
                                .textScale(.secondary)
                        }
                    }
                    .buttonStyle(.borderless)
                    .padding(.all, 5)
                    .onHover(perform: { hover in
                        if hover {
                            self.viewModel.hoveredSettingsView = "General"
                        } else {
                            self.viewModel.hoveredSettingsView = ""
                        }
                    })
                    .foregroundStyle(self.viewModel.selectedSettingsView == "General" ? Color(.controlAccentColor) : .primary)
                    .background(self.viewModel.hoveredSettingsView == "General" || self.viewModel.selectedSettingsView == "General" ? Material.thick.opacity(1) : Material.regular.opacity(0))
                    .cornerRadius(5)
                }
            })
            ToolbarItem(id: "licensesItem", placement: .principal, content: {
                HStack(alignment: .center) {
                    Button {
                        self.viewModel.selectedSettingsView = "Licenses"
                    } label: {
                        VStack(spacing: 0) {
                            Image(systemName: "note.text")
                                .imageScale(.large)
                            Text("Licenses")
                                .textScale(.secondary)
                        }
                    }
                    .buttonStyle(.borderless)
                    .padding(.all, 5)
                    .onHover(perform: { hover in
                        if hover {
                            self.viewModel.hoveredSettingsView = "Licenses"
                        } else {
                            self.viewModel.hoveredSettingsView = ""
                        }
                    })
                    .foregroundStyle(self.viewModel.selectedSettingsView == "Licenses" ? Color(.controlAccentColor) : .primary)
                    .background(self.viewModel.hoveredSettingsView == "Licenses" || self.viewModel.selectedSettingsView == "Licenses" ? Material.thick.opacity(1) : Material.regular.opacity(0))
                    .cornerRadius(5)
                }
            })
        }
        
        // MARK: Apply the onChange methods
        // Change if other Windows should be included
        .onChange(of: self.viewModel.shouldIncludeForeignWindows, {
            
            if CGPreflightScreenCaptureAccess() {
                let _ = try! self.viewModel.spaceCaptureServiceConnection.sendSync(message: prepareSpaceIOSurfaceCaptureServiceRequest(requestType: .ToggleShouldIncludeOtherWindows, shouldIncludeOtherWindows: self.viewModel.shouldIncludeForeignWindows))
                return
            }
            
            if CGRequestScreenCaptureAccess() {
                let _ = try! self.viewModel.spaceCaptureServiceConnection.sendSync(message: prepareSpaceIOSurfaceCaptureServiceRequest(requestType: .ToggleShouldIncludeOtherWindows, shouldIncludeOtherWindows: self.viewModel.shouldIncludeForeignWindows))
                return
            }
            
            self.viewModel.shouldIncludeForeignWindows = false
            self.screenRecordingAlert = true
            
        })
        
        // Change of the FPS Slider, needs to be converted
        .onChange(of: self.viewModel.sliderValue, {
            self.viewModel.fps = self.viewModel.sliderValues[Int(self.viewModel.sliderValue)]
            let _ = try! self.viewModel.spaceCaptureServiceConnection.sendSync(message: prepareSpaceIOSurfaceCaptureServiceRequest(requestType: .UpdateRefreshFPS, fps: self.viewModel.fps))
        })
        
        // MARK: Alerts
        .alert("Screen Recording Permission not granted", isPresented: self.$screenRecordingAlert, actions: {
            Button("Close", role: .cancel) {
                self.screenRecordingAlert = false
            }
            Button("Open System Settings") {
                if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenRecording") {
                    NSWorkspace.shared.open(url)
                }
                self.screenRecordingAlert = false
            }
        }, message: {
            Text("Can't enable capturing other (process-foreign) windows. Please head to System Preferences -> 'Security & Privacy -> Screen Recording' and enable Screen Recording permissions for WavyBackgrounds.")
        })
        
    }
}

#Preview {
    SettingsView()
}
