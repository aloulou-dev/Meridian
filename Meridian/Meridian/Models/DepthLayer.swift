//
//  DepthLayer.swift
//  Meridian
//
//  Depth layer for parallax effect in night sky visualization.
//

import SwiftUI

/// Depth layer for parallax scrolling effect
enum DepthLayer: CaseIterable {
    case background  // Furthest away, moves slowest
    case midground   // Middle depth
    case foreground  // Closest, moves fastest

    /// Parallax multiplier - how much this layer moves relative to input
    var parallaxMultiplier: CGFloat {
        switch self {
        case .background: return 0.3
        case .midground: return 0.6
        case .foreground: return 1.0
        }
    }

    /// Size multiplier - further stars appear smaller
    var sizeMultiplier: CGFloat {
        switch self {
        case .background: return 0.6
        case .midground: return 0.8
        case .foreground: return 1.0
        }
    }

    /// Opacity multiplier - further stars appear dimmer
    var opacityMultiplier: Double {
        switch self {
        case .background: return 0.6
        case .midground: return 0.8
        case .foreground: return 1.0
        }
    }
}
