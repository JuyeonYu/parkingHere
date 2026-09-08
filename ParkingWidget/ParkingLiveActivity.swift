//
//  ParkingLiveActivity.swift
//  ParkingWidget
//
//  주차 중 잠금 화면 배너와 다이내믹 아일랜드.
//

import ActivityKit
import WidgetKit
import SwiftUI

private enum Brand {
    static let yellow = Color("BrandYellow")
    static let onYellow = Color("OnBrand")
    static let parkingURL = URL(string: "parkinghere://parking")!
    static let mapURL = URL(string: "parkinghere://map")!
}

struct ParkingLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: ParkingActivityAttributes.self) { context in
            LockScreenView(attributes: context.attributes)
                .widgetURL(Brand.parkingURL)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    HStack(spacing: 8) {
                        CarBadge(size: 32, iconSize: 14)
                        Text("activity.title")
                            .font(.system(.headline, design: .rounded).weight(.semibold))
                    }
                    .padding(.leading, 4)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    ElapsedTimer(startedAt: context.attributes.startedAt, font: .title2)
                        .padding(.trailing, 4)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    HStack(spacing: 12) {
                        Subtitle(attributes: context.attributes)
                            .font(.system(.subheadline, design: .rounded))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                        Spacer(minLength: 0)
                        if context.attributes.hasLocation {
                            FindCarLink(compact: true)
                        }
                    }
                    .padding(.horizontal, 4)
                    .padding(.top, 4)
                }
            } compactLeading: {
                Image(systemName: "car.fill")
                    .foregroundStyle(Brand.yellow)
                    .padding(.leading, 2)
            } compactTrailing: {
                Text(context.attributes.startedAt, style: .timer)
                    .font(.system(.caption, design: .rounded).weight(.semibold))
                    .monospacedDigit()
                    .multilineTextAlignment(.trailing)
                    .frame(maxWidth: 72, alignment: .trailing)
            } minimal: {
                Image(systemName: "car.fill")
                    .foregroundStyle(Brand.yellow)
            }
            .widgetURL(Brand.parkingURL)
            .keylineTint(Brand.yellow)
        }
    }
}

// MARK: - Lock screen

private struct LockScreenView: View {
    let attributes: ParkingActivityAttributes

    var body: some View {
        VStack(spacing: 14) {
            HStack(spacing: 12) {
                CarBadge(size: 44, iconSize: 20)
                VStack(alignment: .leading, spacing: 2) {
                    Text("activity.title")
                        .font(.system(.headline, design: .rounded).weight(.semibold))
                    Subtitle(attributes: attributes)
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                Spacer(minLength: 8)
                VStack(alignment: .trailing, spacing: 0) {
                    ElapsedTimer(startedAt: attributes.startedAt, font: .title2)
                    Text("activity.elapsed")
                        .font(.system(.caption2, design: .rounded))
                        .foregroundStyle(.secondary)
                }
            }
            if attributes.hasLocation {
                FindCarLink(compact: false)
            }
        }
        .padding(16)
        // 배경은 시스템 기본 재질을 그대로 써서 잠금 화면 글자색과 어긋나지 않게 한다.
    }
}

// MARK: - Pieces

private struct CarBadge: View {
    let size: CGFloat
    let iconSize: CGFloat

    var body: some View {
        ZStack {
            Circle().fill(Brand.yellow)
            Image(systemName: "car.fill")
                .font(.system(size: iconSize, weight: .semibold))
                .foregroundStyle(Brand.onYellow)
        }
        .frame(width: size, height: size)
    }
}

private struct ElapsedTimer: View {
    let startedAt: Date
    let font: Font.TextStyle

    var body: some View {
        Text(startedAt, style: .timer)
            .font(.system(font, design: .rounded).weight(.bold))
            .monospacedDigit()
            .multilineTextAlignment(.trailing)
            .frame(maxWidth: 96, alignment: .trailing)
    }
}

private struct Subtitle: View {
    let attributes: ParkingActivityAttributes

    var body: some View {
        if let memo = attributes.memo {
            Text(memo)
        } else {
            Text("activity.startedAt \(Text(attributes.startedAt, style: .time))")
        }
    }
}

private struct FindCarLink: View {
    let compact: Bool

    var body: some View {
        Link(destination: Brand.mapURL) {
            Label("activity.findCar", systemImage: "location.fill")
                .font(.system(compact ? .subheadline : .headline, design: .rounded).weight(.semibold))
                .foregroundStyle(Brand.onYellow)
                .padding(.vertical, compact ? 8 : 12)
                .padding(.horizontal, compact ? 14 : 16)
                .frame(maxWidth: compact ? nil : .infinity)
                .background(Brand.yellow, in: Capsule())
        }
    }
}
