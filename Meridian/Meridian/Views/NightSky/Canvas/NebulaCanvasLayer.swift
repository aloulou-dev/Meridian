//
//  NebulaCanvasLayer.swift
//  Meridian
//
//  Canvas layer for rendering blurred nebula ellipses in the background.
//

import SwiftUI

/// Canvas layer that renders nebula clouds in the background
struct NebulaCanvasLayer: View {
    let clouds: [NebulaCloud]
    let parallaxOffset: CGSize
    let scale: CGFloat
    let parallaxMultiplier: CGFloat
    let useVirtualCanvas: Bool
    let screenSize: CGSize

    init(
        clouds: [NebulaCloud],
        parallaxOffset: CGSize,
        scale: CGFloat = 1.0,
        parallaxMultiplier: CGFloat = Theme.Nebula.parallaxMultiplier,
        useVirtualCanvas: Bool = false,
        screenSize: CGSize = .zero
    ) {
        self.clouds = clouds
        self.parallaxOffset = parallaxOffset
        self.scale = scale
        self.parallaxMultiplier = parallaxMultiplier
        self.useVirtualCanvas = useVirtualCanvas
        self.screenSize = screenSize
    }

    var body: some View {
        Canvas { context, size in
            for cloud in clouds {
                drawNebulaCloud(cloud, in: context, size: size)
            }
        }
    }

    private func drawNebulaCloud(_ cloud: NebulaCloud, in context: GraphicsContext, size: CGSize) {
        // Apply parallax (nebula moves very slowly)
        let parallaxedOffset = CGSize(
            width: parallaxOffset.width * parallaxMultiplier,
            height: parallaxOffset.height * parallaxMultiplier
        )

        // Nebula scales slower than foreground for depth effect
        let nebulaScale = 1.0 + (scale - 1.0) * 0.3

        let centerX: CGFloat
        let centerY: CGFloat
        let radiusX: CGFloat
        let radiusY: CGFloat

        if useVirtualCanvas {
            // Virtual canvas mode: clouds use normalized coordinates relative to virtual canvas
            let virtualWidth = screenSize.width * Theme.VirtualCanvas.widthMultiplier
            let virtualHeight = screenSize.height * Theme.VirtualCanvas.heightMultiplier

            // Calculate offset to center virtual canvas on screen
            let virtualCenterOffsetX = (virtualWidth - screenSize.width) / 2
            let virtualCenterOffsetY = (virtualHeight - screenSize.height) / 2

            // Convert virtual canvas position to screen position
            let baseX = cloud.center.x * virtualWidth - virtualCenterOffsetX
            let baseY = cloud.center.y * virtualHeight - virtualCenterOffsetY

            // Apply scale from center of view
            let viewCenterX = size.width / 2
            let viewCenterY = size.height / 2
            centerX = viewCenterX + (baseX - viewCenterX) * nebulaScale + parallaxedOffset.width
            centerY = viewCenterY + (baseY - viewCenterY) * nebulaScale + parallaxedOffset.height

            // Radii are relative to virtual canvas dimensions
            radiusX = cloud.radiusX * virtualWidth * nebulaScale
            radiusY = cloud.radiusY * virtualHeight * nebulaScale
        } else {
            // Legacy mode: clouds use normalized coordinates relative to screen
            centerX = cloud.center.x * size.width * nebulaScale + parallaxedOffset.width
            centerY = cloud.center.y * size.height * nebulaScale + parallaxedOffset.height
            radiusX = cloud.radiusX * size.width * nebulaScale
            radiusY = cloud.radiusY * size.height * nebulaScale
        }

        // Create ellipse path
        var path = Path()
        let rect = CGRect(
            x: centerX - radiusX,
            y: centerY - radiusY,
            width: radiusX * 2,
            height: radiusY * 2
        )
        path.addEllipse(in: rect)

        // Apply rotation, blur, and draw
        var rotatedContext = context
        rotatedContext.translateBy(x: centerX, y: centerY)
        rotatedContext.rotate(by: cloud.rotation)
        rotatedContext.translateBy(x: -centerX, y: -centerY)
        rotatedContext.addFilter(.blur(radius: cloud.blurRadius * nebulaScale))

        rotatedContext.fill(
            path,
            with: .color(cloud.color.opacity(cloud.opacity))
        )
    }
}

#Preview {
    ZStack {
        Color.nightSkyGradient
            .ignoresSafeArea()

        NebulaCanvasLayer(
            clouds: NebulaCloud.generateDefaults(),
            parallaxOffset: .zero,
            scale: 1.0
        )
    }
}
