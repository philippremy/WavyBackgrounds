//
//  MTLSpacesView.swift
//  WavyBackgrounds
//
//  Created by Philipp Remy on 13.11.24.
//

import SwiftUI

struct EnumeratedForEach<ItemType, ContentView: View>: View {
    let data: [ItemType]
    let content: (Int, ItemType) -> ContentView

    init(_ data: [ItemType], @ViewBuilder content: @escaping (Int, ItemType) -> ContentView) {
        self.data = data
        self.content = content
    }

    var body: some View {
        ForEach(Array(zip(data.indices, data)), id: \.0) { idx, item in
            content(idx, item)
        }
    }
}

struct MTLSpacesView: View {
    
    @EnvironmentObject private var globalState: GlobalViewState
    @State private var calculatedSize: CGFloat?
    @State private var columns: [GridItem] = []
    
    var body: some View {
        
        VStack(alignment: .center) {
            GeometryReader { geometry in
                VStack {
                    let renderer = MTLSpacesRenderer(globalState: self.globalState)
                    HStack {
                        Spacer()
                        SpacesViewRepresentable(renderer: renderer)
                            .aspectRatio(getAspectRatioDecimalForCurrentSpaceCount(spaceCount: self.globalState.spaceIDs.count), contentMode: .fit)
                            .environment(self.globalState)
                            .background(
                                GeometryReader { geometry2 in
                                    VStack {}
                                        .onAppear {
                                            self.calculatedSize = calculateSpacing(geometry: geometry2)
                                        }
                                        .onChange(of: geometry2.size, {
                                            self.calculatedSize = calculateSpacing(geometry: geometry2)
                                        })
                                }
                            )
                        Spacer()
                    }
                    LazyVGrid(columns: columns) {
                        EnumeratedForEach(self.globalState.spaceIDs, content: { index, _ in
                            Text("Desktop \(index+1)")
                        })
                    }
                    .frame(width: self.calculatedSize, height: 15)
                }
            }
        }
        .padding(.vertical, 20)
        .onAppear() {
            self.columns = Array(repeating: GridItem(.flexible()), count: self.globalState.spaceIDs.count)
        }
        .onChange(of: self.globalState.spaceIDs, {
            self.columns = Array(repeating: GridItem(.flexible()), count: self.globalState.spaceIDs.count)
        })
        
    }
    
    func calculateSpacing(geometry: GeometryProxy) -> CGFloat {
        
        // Calculate possible height
        let width = geometry.size.width
        let widthMinusPadding = width - (CGFloat(self.globalState.spacesViewPadding) * 2)
        return widthMinusPadding < 0 ? 0 : widthMinusPadding
    }
    
}

#Preview {
    MTLSpacesView()
}
