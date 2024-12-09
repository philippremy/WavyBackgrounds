//
//  AspectRatioHelper.swift
//  WavyBackgrounds
//
//  Created by Philipp Remy on 13.11.24.
//

import Foundation
import AppKit

func getAspectRatioDecimal() -> CGFloat {
    let screen = NSScreen.main!
    let rect = screen.frame
    let height = rect.size.height
    let width = rect.size.width
    return width / height;
}

func getAspectRatioDecimalForCurrentSpaceCount(spaceCount: Int) -> CGFloat {
    let screen = NSScreen.main!
    let rect = screen.frame
    let height = rect.size.height
    let width = rect.size.width
    let width_combined = CGFloat(spaceCount) * width;
    return width_combined / height;
}
