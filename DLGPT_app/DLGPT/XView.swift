import SwiftUI

struct XView: View {
    private enum Field: Hashable {
        case maxItems
        case timeWindowHours
    }
    @State private var isLoading = false
    @State private var summary: XSummary?
    @State private var fetchCount = 0
    @State private var lastFetchStartedAt: Date? = nil
    @State private var currentError: XError? = nil
    @State private var selectedMaxItems = 100
    @State private var selectedTimeWindowHours: Int? = nil
    @FocusState private var focusedField: Field?
    
    private let service = XService()
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("X")
                    .font(.largeTitle)
                
                Text("This screen will fetch your X feed, send it to your backend, and show the returned summary.")
                    .foregroundStyle(.secondary)

                VStack(alignment: .leading, spacing: 16) {
                    Text("Request Settings")
                        .font(.headline)

                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Max Items")
                            Spacer()
                            TextField("100", text: maxItemsText)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 80)
                                .multilineTextAlignment(.trailing)
                                .keyboardType(.numberPad)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                                .focused($focusedField, equals: .maxItems)
                        }

                        Slider(value: maxItemsSliderValue, in: 1...100, step: 1)

                        Text("Current value: \(selectedMaxItems)")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Toggle("Use Time Window", isOn: useTimeWindowBinding)

                        if selectedTimeWindowHours != nil {
                            HStack {
                                Text("Time Window (hours)")
                                Spacer()
                                TextField("24", text: timeWindowText)
                                    .textFieldStyle(.roundedBorder)
                                    .frame(width: 80)
                                    .multilineTextAlignment(.trailing)
                                    .keyboardType(.numberPad)
                                    .textInputAutocapitalization(.never)
                                    .autocorrectionDisabled()
                                    .focused($focusedField, equals: .timeWindowHours)
                            }

                            Slider(value: timeWindowSliderValue, in: 1...168, step: 1)

                            Text("Current value: \(selectedTimeWindowHours ?? 0) hours")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        } else {
                            Text("No time window limit")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    Text("Fetch attempts this session: \(fetchCount)")
                        .font(.subheadline)
                    
                    if let lastFetchStartedAt {
                        Text("Last fetch started at: \(lastFetchStartedAt.formatted(date: .omitted, time: .shortened))")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("Last fetch started at: Not yet fetched")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Button {
                    Task {
                        await fetchSummary()
                    }
                } label: {
                    HStack {
                        if isLoading {
                            ProgressView()
                        }
                        Text(isLoading ? "Fetching..." : "Fetch X Summary")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(isLoading)
                
                if let currentError {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Error")
                            .font(.headline)
                        
                        Text(errorMessage(for: currentError))
                            .font(.subheadline)
                        
                        if isRetryable(currentError) {
                            Text("You can try again.")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                
                if let summary {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Pipeline")
                            .font(.headline)

                        Text("Raw items: \(summary.totalRawItems)")
                        Text("Cleaned items: \(summary.totalCleanedItems)")
                        Text("Excluded replies: \(summary.excludedReplyCount)")
                        Text("Excluded ads: \(summary.excludedAdCount)")
                        Text("Excluded other: \(summary.excludedOtherCount)")
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                    VStack(alignment: .leading, spacing: 16) {
                        Text("Headline")
                            .font(.headline)
                        
                        Text(summary.headline)
                        
                        Text("Recency")
                            .font(.headline)
                        
                        Text("Generated at: \(summary.generatedAt)")
                        Text("Feed window start: \(summary.feedWindowStart)")
                        Text("Feed window end: \(summary.feedWindowEnd)")
                        
                        if let weightedMeanTime = summary.weightedMeanTime {
                            Text("Weighted mean time: \(weightedMeanTime)")
                        }
                        
                        Text("Total analysed items: \(summary.totalAnalysedItems)")

                        Text("Themes")
                            .font(.headline)
                        
                        ForEach(summary.themes, id: \.name) { theme in
                            Text("• \(theme.name): \(theme.count) items, \(theme.percentage, specifier: "%.1f")%")
                        }
                        
                        Text("Notable Items")
                            .font(.headline)
                        
                        ForEach(summary.notableItems, id: \.id) { item in
                            VStack(alignment: .leading, spacing: 6) {
                                Text("@\(item.authorHandle)")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                
                                Text(item.text)
                                
                                Text("Reason: \(item.reason)")
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                } else {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Summary")
                            .font(.headline)
                        
                        if fetchCount == 0 {
                            Text("No summary yet.")
                        } else {
                            Text("No summary available yet for the latest fetch.")
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            .frame(maxWidth: .infinity, alignment: .topLeading)
            .padding()
        }
        .navigationTitle("X")
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    focusedField = nil
                }
            }
        }
    }
    
    private func fetchSummary() async {
        fetchCount += 1
        lastFetchStartedAt = Date()
        currentError = nil
        isLoading = true
        
        do {
            summary = try await service.fetchSummary(
                maxItems: selectedMaxItems,
                timeWindowHours: selectedTimeWindowHours
            )
            currentError = nil
        } catch {
            summary = nil
            
            if let xError = error as? XError {
                currentError = xError
            } else {
                currentError = .unknown(
                    message: "Something went wrong while fetching the summary.",
                    retryable: true,
                    requestId: nil
                )
            }
        }
        
        isLoading = false
    }
    
    private func errorMessage(for error: XError) -> String {
        switch error {
        case .invalidUserId(let message, _, _),
                .invalidMaxItems(let message, _, _),
                .unsupportedSummaryType(let message, _, _),
                .invalidTimeWindowHours(let message, _, _),
                .xFetchFailed(let message, _, _),
                .noAnalysableContent(let message, _, _),
                .openAIFailed(let message, _, _),
                .timeout(let message, _, _),
                .internalError(let message, _, _),
                .badBackendResponse(let message, _, _),
                .unknown(let message, _, _):
            return message
        case .networkFailure:
            return "Network connection failed."
        case .decodingFailure:
            return "The app could not read the backend response."
        }
    }
    
    private func isRetryable(_ error: XError) -> Bool {
        switch error {
        case .invalidUserId(_, let retryable, _),
                .invalidMaxItems(_, let retryable, _),
                .unsupportedSummaryType(_, let retryable, _),
                .invalidTimeWindowHours(_, let retryable, _),
                .xFetchFailed(_, let retryable, _),
                .noAnalysableContent(_, let retryable, _),
                .openAIFailed(_, let retryable, _),
                .timeout(_, let retryable, _),
                .internalError(_, let retryable, _),
                .badBackendResponse(_, let retryable, _),
                .unknown(_, let retryable, _):
            return retryable
        case .networkFailure:
            return true
        case .decodingFailure:
            return false
        }
    }

    private var maxItemsSliderValue: Binding<Double> {
        Binding(
            get: { Double(selectedMaxItems) },
            set: { selectedMaxItems = Int($0) }
        )
    }

    private var maxItemsText: Binding<String> {
        Binding(
            get: { String(selectedMaxItems) },
            set: { newValue in
                let digitsOnly = newValue.filter(\.isNumber)

                if let value = Int(digitsOnly) {
                    selectedMaxItems = min(max(value, 1), 100)
                } else if digitsOnly.isEmpty {
                    selectedMaxItems = 1
                }
            }
        )
    }

    private var useTimeWindowBinding: Binding<Bool> {
        Binding(
            get: { selectedTimeWindowHours != nil },
            set: { isOn in
                if isOn {
                    selectedTimeWindowHours = selectedTimeWindowHours ?? 24
                } else {
                    selectedTimeWindowHours = nil
                }
            }
        )
    }

    private var timeWindowSliderValue: Binding<Double> {
        Binding(
            get: { Double(selectedTimeWindowHours ?? 24) },
            set: { selectedTimeWindowHours = Int($0) }
        )
    }

    private var timeWindowText: Binding<String> {
        Binding(
            get: { String(selectedTimeWindowHours ?? 24) },
            set: { newValue in
                let digitsOnly = newValue.filter(\.isNumber)

                if let value = Int(digitsOnly) {
                    selectedTimeWindowHours = min(max(value, 1), 168)
                } else if digitsOnly.isEmpty {
                    selectedTimeWindowHours = 1
                }
            }
        )
    }
}

#Preview {
    XView()
}
