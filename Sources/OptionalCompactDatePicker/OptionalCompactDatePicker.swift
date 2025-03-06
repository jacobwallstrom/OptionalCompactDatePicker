import SwiftUI
import Combine
import UIKit

public struct OptionalCompactDatePicker: View {
    @Environment(\.font) private var font
    @Binding private var selection: Date?
    private let label: LocalizedStringKey
    private let buttonText: LocalizedStringKey
    private let defaultDate: Date?
    private let selectionColor: Color?
    private let pickerColor: Color?
    private let backgroundColor: Color?

    public init(
        _ label: LocalizedStringKey,
        buttonText: LocalizedStringKey,
        selection: Binding<Date?>,
        defaultDate: Date? = Date(),
        selectionColor: Color? = nil,
        pickerColor: Color? = nil,
        backgroundColor: Color? = nil
    ) {
        self._selection = selection
        self.label = label
        self.defaultDate = defaultDate
        self.selectionColor = selectionColor
        self.pickerColor = pickerColor
        self.backgroundColor = backgroundColor
        self.buttonText = buttonText
    }

    private var card: some View {
        Rectangle()
            .foregroundStyle(pickerColor ?? Color(UIColor.secondarySystemBackground))
            .cornerRadius(8)
    }

    public var body: some View {
        HStack(spacing: 6) {
            Text(label)
                .font(font)
                .padding(.vertical, 9)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.clear)

            HStack {
                OptionalUIDatePickerView(
                    date: $selection
                )
                .opacity(selection == nil ? 0 : 1)
                .overlay(alignment: .trailing) {
                    if let selection {
                        Text(dateFormatter.string(from: selection))
                            .padding(.vertical, 7)
                            .padding(.horizontal, 12)
                            .background { card }
                            .allowsHitTesting(false)
                            .foregroundColor(selectionColor ?? .primary)
                            .lineLimit(1)
                            .fixedSize(horizontal: true, vertical: false)
                    }
                }
                if selection != nil {
                    Button {
                        selection = nil
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                            .font(.subheadline)
                            .padding(-1)
                    }
                } else {
                    Button(buttonText) {
                        selection = defaultDate
                    }
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false)
                    .padding(.vertical, 7)
                    .padding(.horizontal, 12)
                    .background { card }
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .foregroundColor(selectionColor ?? .primary)
                }
            }
        }
        .font(.body)
        .frame(alignment: .leading)
    }

    let dateFormatter: DateFormatter = {
        let result = DateFormatter()
        result.dateStyle = .short
        result.timeStyle = .none
        return result
    }()

    private struct OptionalUIDatePickerView: UIViewRepresentable {
        @Binding var boundDate: Date?
        @State var internalDate: Date
        let defaultDate: Date = Date()

        init(date: Binding<Date?>) {
            self._boundDate = date
            self.internalDate = date.wrappedValue ?? defaultDate
        }

        @MainActor
        class Coordinator: NSObject {
            let datePicker = UIDatePicker()
            var parent: OptionalUIDatePickerView
            let button: UIButton?
            var willExpandOnUpdate: Bool

            init(parent: OptionalUIDatePickerView, willExpandOnUpdate: Bool) {
                self.parent = parent
                self.willExpandOnUpdate = willExpandOnUpdate

                datePicker.preferredDatePickerStyle = .compact
                datePicker.datePickerMode = .date
                button = datePicker.findView(type: UIButton.self)
                super.init()
                datePicker.addTarget(self, action: #selector(Coordinator.pickerDateChanged(_:)), for: .valueChanged)
            }

            func updateCoordinator(boundDate: Date?) {
                switch (willExpandOnUpdate, boundDate) {
                case (true, .some):
                    Task { @MainActor in
                        button?.sendActions(for: .touchUpInside)
                        willExpandOnUpdate = false
                    }
                case (false, .none):
                    parent.internalDate = parent.defaultDate
                    willExpandOnUpdate = true
                case (false, .some), (true, .none):
                    break
                }
                if let boundDate {
                    datePicker.setDate(boundDate, animated: true)
                } else {
                    datePicker.setDate(parent.defaultDate, animated: true)
                }
            }

            @objc func pickerDateChanged(_ sender: UIDatePicker) {
                parent.internalDate = sender.date
                parent.boundDate = sender.date
            }
        }

        func makeCoordinator() -> Coordinator {
            Coordinator(parent: self, willExpandOnUpdate: boundDate == nil)
        }

        func makeUIView(context: Context) -> UIDatePicker {
            context.coordinator.datePicker
        }

        func updateUIView(_ datePicker: UIDatePicker, context: Context) {
            context.coordinator.updateCoordinator(boundDate: boundDate)
        }
    }
}

private extension UIView {
    func findView<T: UIView>(type: T.Type) -> T? {
        if let button = self as? T {
            return button
        }
        for subview in subviews {
            if let foundButton = subview.findView(type: type) {
                return foundButton
            }
        }
        return nil
    }
}

struct OptionalCompactDatePicker_Previews: PreviewProvider {
    static var previews: some View {
        PreviewWrapper()
    }

    struct PreviewWrapper: View {
        @State private var date1: Date? = Date()
        @State private var date2: Date? = nil

        var body: some View {
            let height = 34.0
            VStack(alignment: .leading, spacing: 10) {
                OptionalCompactDatePicker("Picker label", buttonText: "Select", selection: $date1)
                    .frame(height: height)
                    .tint(.black)
                Text("Result: \(date1?.formatted(date: .long, time: .omitted) ?? "nil")")
                    .font(.caption)

                OptionalCompactDatePicker(
                    "Picker label",
                    buttonText: "Välj",
                    selection: $date2,
                    selectionColor: .red,
                    pickerColor: .yellow
                )
                .font(.headline)
                .frame(height: height)
                .tint(.green)
                Text("Result: \(date2?.formatted(date: .long, time: .omitted) ?? "nil")")
                    .font(.caption)
            }
            .font(.body)
            .padding(32)
        }
    }
}
