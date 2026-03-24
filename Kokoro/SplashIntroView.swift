import SwiftUI

struct SplashIntroView: View {
    let onFinished: () -> Void

    @State private var animateBackground = false
    @State private var revealLogo = false
    @State private var breatheLogo = false
    @State private var fadeOut = false

    var body: some View {
        ZStack {
            backgroundGradient

            // Organic soft blobs to create emotional, premium motion.
            Group {
                AnimatedBlob(
                    colors: [
                        Color(red: 0.87, green: 0.27, blue: 0.90).opacity(0.58),
                        Color.purple.opacity(0.45)
                    ],
                    size: 320,
                    startOffset: CGSize(width: -150, height: -230),
                    endOffset: CGSize(width: -90, height: -160),
                    animate: animateBackground
                )

                AnimatedBlob(
                    colors: [
                        Color(red: 0.35, green: 0.57, blue: 0.98).opacity(0.56),
                        Color.white.opacity(0.30)
                    ],
                    size: 360,
                    startOffset: CGSize(width: 170, height: 210),
                    endOffset: CGSize(width: 110, height: 150),
                    animate: animateBackground
                )

                AnimatedBlob(
                    colors: [
                        Color.purple.opacity(0.40),
                        Color(red: 0.87, green: 0.27, blue: 0.90).opacity(0.34)
                    ],
                    size: 260,
                    startOffset: CGSize(width: 170, height: -180),
                    endOffset: CGSize(width: 115, height: -120),
                    animate: animateBackground
                )
            }
            .blendMode(.plusLighter)

            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color.white.opacity(0.42),
                                    Color(red: 0.87, green: 0.27, blue: 0.90).opacity(0.12),
                                    .clear
                                ],
                                center: .center,
                                startRadius: 6,
                                endRadius: 130
                            )
                        )
                        .frame(width: 210, height: 210)
                        .blur(radius: 14)
                        .opacity(revealLogo ? 1 : 0)

                    Image("ApapachoLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 300, height: 300)
                        .shadow(color: .white.opacity(0.55), radius: 14, x: 0, y: 4)
                        .shadow(color: Color(red: 0.87, green: 0.27, blue: 0.90).opacity(0.35), radius: 24, x: 0, y: 6)
                }

            }
            .opacity(revealLogo ? 1 : 0)
            .scaleEffect(revealLogo ? (breatheLogo ? 1.035 : 1.0) : 0.88)
            .offset(y: revealLogo ? (breatheLogo ? -3 : 0) : 18)
        }
        .ignoresSafeArea()
        .opacity(fadeOut ? 0 : 1)
        .task {
            startAnimations()
        }
    }

    private var backgroundGradient: some View {
        LinearGradient(
            colors: [
                Color.black.opacity(0.80),
                Color(red: 0.11, green: 0.08, blue: 0.22),
                Color(red: 0.22, green: 0.12, blue: 0.31),
                Color(red: 0.35, green: 0.57, blue: 0.98).opacity(0.40)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    @MainActor
    private func startAnimations() {
        withAnimation(.easeInOut(duration: 1.2)) {
            revealLogo = true
        }

        withAnimation(.easeInOut(duration: 7.0).repeatForever(autoreverses: true)) {
            animateBackground = true
        }

        withAnimation(.easeInOut(duration: 2.1).repeatForever(autoreverses: true).delay(0.25)) {
            breatheLogo = true
        }

        Task {
            try? await Task.sleep(for: .milliseconds(2700))

            await MainActor.run {
                withAnimation(.easeInOut(duration: 0.55)) {
                    fadeOut = true
                }
            }

            try? await Task.sleep(for: .milliseconds(460))

            await MainActor.run {
                onFinished()
            }
        }
    }
}

private struct AnimatedBlob: View {
    let colors: [Color]
    let size: CGFloat
    let startOffset: CGSize
    let endOffset: CGSize
    let animate: Bool

    var body: some View {
        Circle()
            .fill(
                LinearGradient(
                    colors: colors,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: size, height: size)
            .blur(radius: 58)
            .offset(animate ? endOffset : startOffset)
            .scaleEffect(animate ? 1.10 : 0.96)
            .animation(.easeInOut(duration: 7.0).repeatForever(autoreverses: true), value: animate)
    }
}

#Preview {
    SplashIntroView(onFinished: {})
}
