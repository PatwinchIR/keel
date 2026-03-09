import SwiftUI

struct TimeRangePicker: View {
    @Binding var selection: TimeRange

    var body: some View {
        HStack(spacing: 0) {
            ForEach(TimeRange.allCases) { range in
                Button {
                    withAnimation(K.Animation.fast) {
                        selection = range
                    }
                } label: {
                    Text(range.rawValue)
                        .font(.system(size: 13, weight: selection == range ? .bold : .medium))
                        .foregroundStyle(
                            selection == range ? K.Colors.accent : K.Colors.tertiary
                        )
                        .padding(.horizontal, K.Spacing.sm)
                        .padding(.vertical, K.Spacing.xs)
                        .background(
                            selection == range
                                ? K.Colors.accent.opacity(0.12)
                                : Color.clear
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
            }
        }
    }
}
