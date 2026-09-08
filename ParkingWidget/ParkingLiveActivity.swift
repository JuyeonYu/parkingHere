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
    static let photoURL = URL(string: "parkinghere://photo")!
}

struct ParkingLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: ParkingActivityAttributes.self) { context in
            LockScreenView(attributes: context.attributes, state: context.state)
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
                        Subtitle(attributes: context.attributes, state: context.state)
                            .font(.system(.subheadline, design: .rounded))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                        Spacer(minLength: 0)
                        if context.attributes.hasLocation {
                            ActionLink(kind: .findCar, compact: true)
                        } else if !context.state.hasPhoto {
                            ActionLink(kind: .addPhoto, compact: true)
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
    let state: ParkingActivityAttributes.ContentState

    var body: some View {
        VStack(spacing: 14) {
            HStack(spacing: 12) {
                CarBadge(size: 44, iconSize: 20)
                VStack(alignment: .leading, spacing: 2) {
                    Text("activity.title")
                        .font(.system(.headline, design: .rounded).weight(.semibold))
                    Subtitle(attributes: attributes, state: state)
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
            if attributes.hasLocation || !state.hasPhoto {
                HStack(spacing: 10) {
                    if attributes.hasLocation {
                        ActionLink(kind: .findCar, compact: false)
                    }
                    if !state.hasPhoto {
                        ActionLink(kind: .addPhoto, compact: false, secondary: attributes.hasLocation)
                    }
                }
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
    let state: ParkingActivityAttributes.ContentState

    var body: some View {
        if let memo = state.memo {
            Text(memo)
        } else {
            Text("activity.startedAt \(Text(attributes.startedAt, style: .time))")
        }
    }
}

private struct ActionLink: View {
    enum Kind {
        case findCar, addPhoto

        var url: URL { self == .findCar ? Brand.mapURL : Brand.photoURL }
        var titleKey: LocalizedStringKey { self == .findCar ? "activity.findCar" : "activity.addPhoto" }
        var symbol: String { self == .findCar ? "location.fill" : "camera.fill" }
    }

    let kind: Kind
    let compact: Bool
    /// 주 버튼 옆에 놓일 때는 채우지 않은 스타일로 보여준다.
    var secondary: Bool = false

    var body: some View {
        Link(destination: kind.url) {
            Label(kind.titleKey, systemImage: kind.symbol)
                .font(.system(compact ? .subheadline : .headline, design: .rounded).weight(.semibold))
                .foregroundStyle(secondary ? .primary : Brand.onYellow)
                .padding(.vertical, compact ? 8 : 12)
                .padding(.horizontal, compact ? 14 : 16)
                .frame(maxWidth: compact ? nil : .infinity)
                .background(secondary ? AnyShapeStyle(.quaternary) : AnyShapeStyle(Brand.yellow), in: Capsule())
        }
    }
}
