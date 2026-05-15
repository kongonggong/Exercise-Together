// =====================================================
// DesignSystem.swift
// สีสัน, Typography และ Component พื้นฐานของแอป
// =====================================================

import SwiftUI

// MARK: - Color Palette

extension Color {
    // Backgrounds
    static let surface          = Color(hex: "#131315")
    static let surfaceDim       = Color(hex: "#131315")
    static let surfaceBright    = Color(hex: "#39393B")

    // Surface Containers (ใช้สร้าง depth แทน border)
    static let containerLowest  = Color(hex: "#0E0E10")
    static let containerLow     = Color(hex: "#1B1B1D")
    static let container        = Color(hex: "#1F1F21")
    static let containerHigh    = Color(hex: "#2A2A2C")
    static let containerHighest = Color(hex: "#353437")

    // Brand Colors
    static let primary          = Color(hex: "#AAC7FF") // Electric Blue
    static let primaryContainer = Color(hex: "#3E90FF")
    static let tertiary         = Color(hex: "#FFB868") // Soft Orange
    static let tertiaryContainer = Color(hex: "#CE7F00")

    // Text Colors
    static let onSurface        = Color(hex: "#E4E2E4")
    static let onSurfaceVariant = Color(hex: "#C1C6D7")
    static let outline          = Color(hex: "#8B90A0")
    static let outlineVariant   = Color(hex: "#414755")
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >> 8) & 0xFF) / 255
        let b = Double(int & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}

// MARK: - Typography Styles

struct PerformanceTextStyle {
    // Display: ตัวเลขขนาดใหญ่ เช่น HR, Score
    static let displayLarge = Font.system(size: 56, weight: .black, design: .default)
    static let displayMedium = Font.system(size: 45, weight: .black, design: .default)
    static let displaySmall = Font.system(size: 36, weight: .black, design: .default)

    // Headline: หัวข้อ Section
    static let headlineLarge = Font.system(size: 32, weight: .bold, design: .default)
    static let headlineMedium = Font.system(size: 28, weight: .bold, design: .default)
    static let headlineSmall = Font.system(size: 24, weight: .bold, design: .default)

    // Body: เนื้อหาทั่วไป
    static let bodyLarge = Font.system(size: 16, weight: .regular)
    static let bodyMedium = Font.system(size: 14, weight: .regular)

    // Label: Metadata แบบ ALL CAPS
    static let labelSmall = Font.system(size: 11, weight: .bold, design: .default)
}

// MARK: - Gradient

extension LinearGradient {
    // Gradient หลักของปุ่ม CTA (ไล่จาก Electric Blue → Primary Container)
    static let primaryGradient = LinearGradient(
        colors: [.primary, .primaryContainer],
        startPoint: UnitPoint(x: 0.15, y: 0),
        endPoint: UnitPoint(x: 0.85, y: 1)
    )
}

// MARK: - Reusable Components

/// Label แบบ ALL CAPS สไตล์ Pro Instrument
struct MetadataLabel: View {
    let text: String
    var color: Color = .outline

    var body: some View {
        Text(text.uppercased())
            .font(PerformanceTextStyle.labelSmall)
            .tracking(1.2)
            .foregroundColor(color)
            .lineLimit(2)
            .minimumScaleFactor(0.75)
            .allowsTightening(true)
    }
}

/// Progress Bar แบบ Borderless
struct ProgressBlade: View {
    let value: Double // 0.0 – 1.0
    var color: Color = .primary

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.containerHighest)
                    .frame(height: 6)
                Capsule()
                    .fill(color)
                    .frame(width: geo.size.width * value, height: 6)
            }
        }
        .frame(height: 6)
    }
}

/// Circular Progress Ring
struct ProgressRing: View {
    let progress: Double // 0.0 – 1.0
    let size: CGFloat
    var ringColor: Color = .tertiary
    var lineWidth: CGFloat = 8

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.containerHighest, lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(ringColor, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
        }
        .frame(width: size, height: size)
    }
}

/// ปุ่ม Primary แบบ Gradient Glassmorphic
struct PrimaryButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title.uppercased())
                .font(PerformanceTextStyle.labelSmall)
                .tracking(1.5)
                .foregroundColor(Color(hex: "#002957"))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(LinearGradient.primaryGradient)
                .clipShape(Capsule())
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

/// Button style ที่มี scale down เมื่อกด (สัมผัส "Pro" feel)
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

/// Glass Card สำหรับ floating elements
struct GlassCard<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        content
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.containerLow.opacity(0.7))
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.08), lineWidth: 1)
                    )
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

/// Top App Bar แบบ Glassmorphic ใช้ร่วมกันทุกหน้า
struct TopAppBar: View {
    var trailingIcon: String = "gearshape"
    var trailingAction: (() -> Void)? = nil

    var body: some View {
        HStack {
            // Logo + App Name
            HStack(spacing: 10) {
                Circle()
                    .fill(Color.containerHighest)
                    .frame(width: 32, height: 32)
                    .overlay(
                        Image(systemName: "figure.strengthtraining.traditional")
                            .font(.system(size: 14, weight: .light))
                            .foregroundColor(.primary)
                    )

                Text("PERFORMANCE LAB")
                    .font(.system(size: 15, weight: .black))
                    .tracking(1)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }

            Spacer()

            // Trailing Action
            Button {
                trailingAction?()
            } label: {
                Image(systemName: trailingIcon)
                    .font(.system(size: 18, weight: .light))
                    .foregroundColor(.outline)
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 48)
        .frame(height: 104, alignment: .top)
        .background(
            Color.surface.opacity(0.8)
                .background(.ultraThinMaterial)
                .ignoresSafeArea()
        )
    }
}
