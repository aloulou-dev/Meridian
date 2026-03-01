//
//  NebulaCloud.swift
//  Meridian
//
//  Configuration for a nebula cloud ellipse in the background.
//

import SwiftUI

/// Represents a nebula cloud ellipse in the background
struct NebulaCloud: Identifiable {
    let id: UUID
    let center: CGPoint      // Normalized 0-1
    let radiusX: CGFloat     // 0.15-0.4 of screen width
    let radiusY: CGFloat     // 0.15-0.4 of screen height
    let color: Color
    let blurRadius: CGFloat
    let opacity: Double
    let rotation: Angle

    init(
        center: CGPoint,
        radiusX: CGFloat,
        radiusY: CGFloat,
        color: Color,
        blurRadius: CGFloat = 60,
        opacity: Double = 0.08,
        rotation: Angle = .zero
    ) {
        self.id = UUID()
        self.center = center
        self.radiusX = radiusX
        self.radiusY = radiusY
        self.color = color
        self.blurRadius = blurRadius
        self.opacity = opacity
        self.rotation = rotation
    }

    /// Generate default nebula clouds for the background (normalized coordinates)
    static func generateDefaults() -> [NebulaCloud] {
        [
            NebulaCloud(
                center: CGPoint(x: 0.25, y: 0.3),
                radiusX: 0.35,
                radiusY: 0.25,
                color: .nebulaBlue,
                blurRadius: 80,
                opacity: 0.06,
                rotation: .degrees(-15)
            ),
            NebulaCloud(
                center: CGPoint(x: 0.75, y: 0.6),
                radiusX: 0.3,
                radiusY: 0.35,
                color: .nebulaPurple,
                blurRadius: 70,
                opacity: 0.05,
                rotation: .degrees(20)
            ),
            NebulaCloud(
                center: CGPoint(x: 0.5, y: 0.85),
                radiusX: 0.4,
                radiusY: 0.2,
                color: .nebulaRose,
                blurRadius: 60,
                opacity: 0.04,
                rotation: .degrees(5)
            )
        ]
    }

    /// Generate nebula clouds scattered across the virtual canvas
    /// Uses normalized coordinates (0-1) relative to virtual canvas size
    static func generateForVirtualCanvas() -> [NebulaCloud] {
        [
            NebulaCloud(
                center: CGPoint(x: 0.2, y: 0.15),
                radiusX: 0.25,
                radiusY: 0.08,
                color: .nebulaBlue,
                blurRadius: 80,
                opacity: 0.06,
                rotation: .degrees(-15)
            ),
            NebulaCloud(
                center: CGPoint(x: 0.75, y: 0.35),
                radiusX: 0.3,
                radiusY: 0.1,
                color: .nebulaPurple,
                blurRadius: 70,
                opacity: 0.05,
                rotation: .degrees(20)
            ),
            NebulaCloud(
                center: CGPoint(x: 0.4, y: 0.55),
                radiusX: 0.35,
                radiusY: 0.09,
                color: .nebulaTeal,
                blurRadius: 90,
                opacity: 0.04,
                rotation: .degrees(-10)
            ),
            NebulaCloud(
                center: CGPoint(x: 0.6, y: 0.8),
                radiusX: 0.28,
                radiusY: 0.11,
                color: .nebulaIndigo,
                blurRadius: 60,
                opacity: 0.07,
                rotation: .degrees(15)
            )
        ]
    }
}
