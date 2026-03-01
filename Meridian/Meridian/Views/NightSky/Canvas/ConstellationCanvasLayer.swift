//
//  ConstellationCanvasLayer.swift
//  Meridian
//
//  Canvas layer for rendering constellation lines connecting same-week stars.
//

import SwiftUI

/// Canvas layer that renders dashed constellation lines between same-week stars
struct ConstellationCanvasLayer: View {
    let lines: [ConstellationLine]
    let stars: [RenderableStar]
    let parallaxOffset: CGSize
    let scale: CGFloat

    /// Constellation layer parallax multiplier (between background stars and journal stars)
    private let constellationParallax: CGFloat = 0.7

    init(lines: [ConstellationLine], stars: [RenderableStar], parallaxOffset: CGSize, scale: CGFloat = 1.0) {
        self.lines = lines
        self.stars = stars
        self.parallaxOffset = parallaxOffset
        self.scale = scale
    }

    var body: some View {
        Canvas { context, size in
            for line in lines {
                drawConstellationLine(line, in: context, size: size)
            }
        }
    }

    private func drawConstellationLine(_ line: ConstellationLine, in context: GraphicsContext, size: CGSize) {
        // Find the start and end stars
        guard let startStar = stars.first(where: { $0.id == line.startStarID }),
              let endStar = stars.first(where: { $0.id == line.endStarID }) else {
            return
        }

        // Calculate positions with constellation-layer parallax
        let constellationOffset = CGSize(
            width: parallaxOffset.width * constellationParallax,
            height: parallaxOffset.height * constellationParallax
        )

        // Constellation scale is between nebula and foreground
        let constellationScale = 1.0 + (scale - 1.0) * 0.7

        // Calculate center of view for scaling around center
        let centerX = size.width / 2
        let centerY = size.height / 2

        // Calculate scaled positions
        let startBaseX = startStar.normalizedPosition.x * size.width
        let startBaseY = startStar.normalizedPosition.y * size.height
        let startPos = CGPoint(
            x: centerX + (startBaseX - centerX) * constellationScale + constellationOffset.width,
            y: centerY + (startBaseY - centerY) * constellationScale + constellationOffset.height
        )

        let endBaseX = endStar.normalizedPosition.x * size.width
        let endBaseY = endStar.normalizedPosition.y * size.height
        let endPos = CGPoint(
            x: centerX + (endBaseX - centerX) * constellationScale + constellationOffset.width,
            y: centerY + (endBaseY - centerY) * constellationScale + constellationOffset.height
        )

        // Create path
        var path = Path()
        path.move(to: startPos)
        path.addLine(to: endPos)

        // Draw with dashed stroke (scale line width slightly with zoom)
        let scaledLineWidth = Theme.Constellation.lineWidth * min(constellationScale, 1.5)
        let style = StrokeStyle(
            lineWidth: scaledLineWidth,
            lineCap: .round,
            dash: Theme.Constellation.lineDashPattern.map { $0 * constellationScale }
        )

        context.stroke(
            path,
            with: .color(Color.white.opacity(line.opacity)),
            style: style
        )
    }
}

#Preview {
    ZStack {
        Color.nightSkyGradient
            .ignoresSafeArea()

        ConstellationCanvasLayer(
            lines: [],
            stars: [],
            parallaxOffset: .zero,
            scale: 1.0
        )
    }
}
