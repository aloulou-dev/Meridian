//
//  View+Extensions.swift
//  Meridian
//
//  View extensions and modifiers for the Meridian design system.
//

import SwiftUI

// MARK: - View Extensions

extension View {
    /// Apply the primary button style
    func primaryButtonStyle(isEnabled: Bool = true) -> some View {
        self
            .font(Theme.Typography.button)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: Theme.Size.buttonHeight)
            .background(isEnabled ? Color.primaryButton : Color.disabledButton)
            .cornerRadius(Theme.CornerRadius.large)
    }

    /// Apply glassmorphism effect
    func glassmorphism(
        cornerRadius: CGFloat = Theme.CornerRadius.large,
        opacity: Double = 0.1
    ) -> some View {
        self
            .background(.ultraThinMaterial.opacity(opacity))
            .background(Color.cardBackground.opacity(0.5))
            .cornerRadius(cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
    }

    /// Apply card style with dark background
    func cardStyle(cornerRadius: CGFloat = Theme.CornerRadius.large) -> some View {
        self
            .background(Color.cardBackground)
            .cornerRadius(cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(Color.white.opacity(0.05), lineWidth: 1)
            )
    }

    /// Add glow effect
    func glow(color: Color, radius: CGFloat = Theme.Size.glowRadius) -> some View {
        self
            .shadow(color: color, radius: radius, x: 0, y: 0)
    }

    /// Conditional modifier
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }

    /// Hide keyboard
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

// MARK: - Custom View Modifiers

/// Shimmer animation effect for loading states or highlights
struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geometry in
                    LinearGradient(
                        colors: [
                            .clear,
                            .white.opacity(0.3),
                            .clear
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: geometry.size.width * 2)
                    .offset(x: -geometry.size.width + (geometry.size.width * 2 * phase))
                }
            )
            .mask(content)
            .onAppear {
                withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    phase = 1
                }
            }
    }
}

extension View {
    func shimmer() -> some View {
        modifier(ShimmerModifier())
    }
}

/// Twinkle animation for stars
struct TwinkleModifier: ViewModifier {
    let minOpacity: Double
    let maxOpacity: Double
    let duration: Double

    @State private var opacity: Double

    init(minOpacity: Double = 0.6, maxOpacity: Double = 1.0, duration: Double = 2.0) {
        self.minOpacity = minOpacity
        self.maxOpacity = maxOpacity
        self.duration = duration
        self._opacity = State(initialValue: maxOpacity)
    }

    func body(content: Content) -> some View {
        content
            .opacity(opacity)
            .onAppear {
                withAnimation(
                    .easeInOut(duration: duration)
                    .repeatForever(autoreverses: true)
                    .delay(Double.random(in: 0...duration))
                ) {
                    opacity = minOpacity
                }
            }
    }
}

extension View {
    func twinkle(
        minOpacity: Double = 0.6,
        maxOpacity: Double = 1.0,
        duration: Double = 2.0
    ) -> some View {
        modifier(TwinkleModifier(minOpacity: minOpacity, maxOpacity: maxOpacity, duration: duration))
    }
}

/// Float animation for subtle movement
struct FloatModifier: ViewModifier {
    let amplitude: CGFloat
    let duration: Double

    @State private var offset: CGFloat = 0

    init(amplitude: CGFloat = 3, duration: Double = 3.0) {
        self.amplitude = amplitude
        self.duration = duration
    }

    func body(content: Content) -> some View {
        content
            .offset(y: offset)
            .onAppear {
                withAnimation(
                    .easeInOut(duration: duration)
                    .repeatForever(autoreverses: true)
                    .delay(Double.random(in: 0...duration))
                ) {
                    offset = amplitude
                }
            }
    }
}

extension View {
    func float(amplitude: CGFloat = 3, duration: Double = 3.0) -> some View {
        modifier(FloatModifier(amplitude: amplitude, duration: duration))
    }
}
