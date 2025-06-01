import SwiftUI
import CroatianGroceryCore

public struct PriceComparisonView: View {
    @StateObject private var viewModel = PriceComparisonViewModel()
    @State private var showingSignificantOnly = false
    
    public init() {}
    
    public var body: some View {
        NavigationView {
            VStack {
                if #available(iOS 17.0, *) {
                    if viewModel.isLoading {
                        ProgressView("Loading comparisons...")
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if viewModel.filteredComparisons.isEmpty {
                        emptyStateView
                    } else {
                        comparisonsList
                    }
                } else {
                    // Fallback on earlier versions
                }
            }
            .navigationTitle("Price Comparisons")
            .toolbar {
                Button("Refresh") {
                    Task {
                        await viewModel.refreshData()
                    }
                }
            }
        }
        .task {
            await viewModel.loadComparisons()
        }
    }
    
    @available(iOS 17.0, *)
    private var comparisonsList: some View {
        VStack {
            // Filter toggle
            HStack {
                Toggle("Show significant differences only (>10%)", isOn: $showingSignificantOnly)
                    .onChange(of: showingSignificantOnly) { _, newValue in
                        viewModel.filterSignificant(newValue)
                    }
                Spacer()
            }
            .padding(.horizontal)
            
            // Savings summary
            if let report = viewModel.savingsReport {
                savingsSummaryView(report: report)
            }
            
            // Comparisons list
            List(viewModel.filteredComparisons) { comparison in
                PriceComparisonRowView(comparison: comparison)
            }
        }
    }
    
    private func savingsSummaryView(report: PriceSavingsReport) -> some View {
        Section("Savings Summary") {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Total Comparisons")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(report.totalComparisons)")
                            .font(.headline)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Avg Savings")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("€\(String(format: "%.2f", report.averageSavings))")
                            .font(.headline)
                            .foregroundColor(.green)
                    }
                }
                
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Total Savings")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("€\(String(format: "%.2f", report.totalSavings))")
                            .font(.headline)
                            .foregroundColor(.green)
                    }
                    
                    Spacer()
                    
                    if let biggestSaving = report.biggestSaving {
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("Biggest Saving")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("€\(String(format: "%.2f", biggestSaving.priceDifference))")
                                .font(.headline)
                                .foregroundColor(.green)
                        }
                    }
                }
            }
            .padding(.vertical, 8)
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            Text("No comparisons available")
                .font(.headline)
            
            Text("Load some product data first")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Button("Refresh Data") {
                Task {
                    await viewModel.refreshData()
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

public struct PriceComparisonRowView: View {
    let comparison: PriceComparison
    
    public init(comparison: PriceComparison) {
        self.comparison = comparison
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(comparison.productName)
                .font(.headline)
                .lineLimit(2)
            
            HStack(spacing: 16) {
                // Cheapest option
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Image(systemName: "crown.fill")
                            .foregroundColor(.yellow)
                            .font(.caption)
                        Text("Best Price")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    
                    ProviderBadgeView(provider: comparison.cheapestProvider)
                    
                    Text("€\(String(format: "%.2f", comparison.cheapestPrice))")
                        .font(.headline)
                        .foregroundColor(.green)
                }
                
                Spacer()
                
                // Most expensive option
                VStack(alignment: .trailing, spacing: 4) {
                    HStack {
                        Text("Most Expensive")
                            .font(.caption)
                            .fontWeight(.medium)
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                    
                    ProviderBadgeView(provider: comparison.expensiveProvider)
                    
                    Text("€\(String(format: "%.2f", comparison.expensivePrice))")
                        .font(.headline)
                        .foregroundColor(.red)
                }
            }
            
            // Savings information
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("You Save")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("€\(String(format: "%.2f", comparison.priceDifference))")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.green)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Savings")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    let percentage = (comparison.priceDifference / comparison.expensivePrice * 100).rounded()
                    Text("\(String(format: "%.0f", percentage))%")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.green)
                }
            }
        }
        .padding(.vertical, 8)
    }
}

@MainActor
class PriceComparisonViewModel: ObservableObject {
    @Published var comparisons: [PriceComparison] = []
    @Published var filteredComparisons: [PriceComparison] = []
    @Published var savingsReport: PriceSavingsReport?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let dataManager: DataManager
    private let comparisonService = PriceComparisonService()
    
    init() {
        do {
            let storage = try FileStorage()
            self.dataManager = DataManager(storage: storage)
        } catch {
            fatalError("Failed to initialize storage: \(error)")
        }
    }
    
    func loadComparisons() async {
        isLoading = true
        errorMessage = nil

        let manager = dataManager
        let result = await Task {
            do {
                let comparisons = try await manager.getComparisons()
                return (comparisons, nil as Error?)
            } catch {
                return ([] as [PriceComparison], error)
            }
        }.value

        if let error = result.1 {
            errorMessage = error.localizedDescription
        } else {
            comparisons = result.0
            filteredComparisons = comparisons
            updateSavingsReport()
        }

        isLoading = false
    }
    
    func refreshData() async {
        isLoading = true
        errorMessage = nil

        let manager = dataManager
        let result = await Task {
            do {
                _ = try await manager.refreshData()
                let comparisons = try await manager.getComparisons()
                return (comparisons, nil as Error?)
            } catch {
                return ([] as [PriceComparison], error)
            }
        }.value

        if let error = result.1 {
            errorMessage = error.localizedDescription
        } else {
            comparisons = result.0
            filteredComparisons = comparisons
            updateSavingsReport()
        }

        isLoading = false
    }
    
    func filterSignificant(_ significantOnly: Bool) {
        if significantOnly {
            filteredComparisons = comparisons.filter { comparison in
                let percentage = comparison.priceDifference / comparison.expensivePrice * 100
                return percentage >= 10
            }
        } else {
            filteredComparisons = comparisons
        }
        updateSavingsReport()
    }
    
    private func updateSavingsReport() {
        savingsReport = comparisonService.calculateSavings(from: filteredComparisons)
    }
}

#Preview {
    PriceComparisonView()
}
