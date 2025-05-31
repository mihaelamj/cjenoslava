//import SwiftUI
//import CroatianGroceryCore
//import Charts
//
//public struct AnalyticsView: View {
//    @StateObject private var viewModel = AnalyticsViewModel()
//    
//    public init() {}
//    
//    public var body: some View {
//        NavigationView {
//            ScrollView {
//                LazyVStack(spacing: 20) {
//                    if viewModel.isLoading {
//                        ProgressView("Loading analytics...")
//                            .frame(maxWidth: .infinity, minHeight: 200)
//                    } else if viewModel.products.isEmpty {
//                        emptyStateView
//                    } else {
//                        analyticsContent
//                    }
//                }
//                .padding()
//            }
//            .navigationTitle("Analytics")
//            .toolbar {
//                ToolbarItem(placement: .navigationBarTrailing) {
//                    Button("Refresh") {
//                        Task {
//                            await viewModel.refreshData()
//                        }
//                    }
//                }
//            }
//        }
//        .task {
//            await viewModel.loadData()
//        }
//    }
//    
//    private var analyticsContent: some View {
//        VStack(spacing: 20) {
//            overallStatsSection
//            providerAnalyticsSection
//            categoryAnalyticsSection
//            bestDealsSection
//        }
//    }
//    
//    private var overallStatsSection: some View {
//        VStack(alignment: .leading, spacing: 16) {
//            Text("Overall Statistics")
//                .font(.title2)
//                .fontWeight(.bold)
//            
//            LazyVGrid(columns: [
//                GridItem(.flexible()),
//                GridItem(.flexible())
//            ], spacing: 16) {
//                StatCardView(
//                    title: "Total Products",
//                    value: "\(viewModel.products.count)",
//                    icon: "cart.fill",
//                    color: .blue
//                )
//                
//                StatCardView(
//                    title: "Providers",
//                    value: "\(viewModel.providerCount)",
//                    icon: "building.2.fill",
//                    color: .green
//                )
//                
//                StatCardView(
//                    title: "Categories",
//                    value: "\(viewModel.categoryCount)",
//                    icon: "tag.fill",
//                    color: .orange
//                )
//                
//                StatCardView(
//                    title: "On Sale",
//                    value: "\(viewModel.onSaleCount)",
//                    icon: "flame.fill",
//                    color: .red
//                )
//            }
//        }
//    }
//    
//    private var providerAnalyticsSection: some View {
//        VStack(alignment: .leading, spacing: 16) {
//            Text("Provider Analytics")
//                .font(.title2)
//                .fontWeight(.bold)
//            
//            if #available(iOS 16.0, macOS 13.0, *) {
//                Chart(viewModel.providerAnalytics, id: \.provider) { analytics in
//                    BarMark(
//                        x: .value("Provider", analytics.provider.displayName),
//                        y: .value("Average Price", Double(truncating: analytics.averagePrice as NSNumber))
//                    )
//                    .foregroundStyle(.blue)
//                }
//                .frame(height: 200)
//            }
//            
//            ForEach(viewModel.providerAnalytics, id: \.provider) { analytics in
//                ProviderAnalyticsRowView(analytics: analytics)
//            }
//        }
//    }
//    
//    private var categoryAnalyticsSection: some View {
//        VStack(alignment: .leading, spacing: 16) {
//            Text("Top Categories")
//                .font(.title2)
//                .fontWeight(.bold)
//            
//            ForEach(Array(viewModel.categoryAnalytics.prefix(5)), id: \.category) { analytics in
//                CategoryAnalyticsRowView(analytics: analytics)
//            }
//        }
//    }
//    
//    private var bestDealsSection: some View {
//        VStack(alignment: .leading, spacing: 16) {
//            Text("Best Deals")
//                .font(.title2)
//                .fontWeight(.bold)
//            
//            ForEach(viewModel.bestDeals) { deal in
//                BestDealRowView(product: deal)
//            }
//        }
//    }
//    
//    private var emptyStateView: some View {
//        VStack(spacing: 16) {
//            Image(systemName: "chart.bar.doc.horizontal")
//                .font(.system(size: 48))
//                .foregroundColor(.secondary)
//            
//            Text("No analytics available")
//                .font(.headline)
//            
//            Text("Load some product data first")
//                .font(.subheadline)
//                .foregroundColor(.secondary)
//            
//            Button("Refresh Data") {
//                Task {
//                    await viewModel.refreshData()
//                }
//            }
//            .buttonStyle(.borderedProminent)
//        }
//        .frame(maxWidth: .infinity, minHeight: 200)
//    }
//}
//
//public struct StatCardView: View {
//    let title: String
//    let value: String
//    let icon: String
//    let color: Color
//    
//    public init(title: String, value: String, icon: String, color: Color) {
//        self.title = title
//        self.value = value
//        self.icon = icon
//        self.color = color
//    }
//    
//    public var body: some View {
//        VStack(spacing: 8) {
//            HStack {
//                Image(systemName: icon)
//                    .foregroundColor(color)
//                    .font(.title2)
//                
//                Spacer()
//            }
//            
//            VStack(alignment: .leading, spacing: 4) {
//                HStack {
//                    Text(value)
//                        .font(.title)
//                        .fontWeight(.bold)
//                    Spacer()
//                }
//                
//                HStack {
//                    Text(title)
//                        .font(.caption)
//                        .foregroundColor(.secondary)
//                    Spacer()
//                }
//            }
//        }
//        .padding()
//        .background(Color(.systemGray6))
//        .clipShape(RoundedRectangle(cornerRadius: 12))
//    }
//}
//
//public struct ProviderAnalyticsRowView: View {
//    let analytics: ProviderAnalytics
//    
//    public init(analytics: ProviderAnalytics) {
//        self.analytics = analytics
//    }
//    
//    public var body: some View {
//        VStack(alignment: .leading, spacing: 8) {
//            HStack {
//                ProviderBadgeView(provider: analytics.provider)
//                Spacer()
//                Text("\(analytics.totalProducts) products")
//                    .font(.caption)
//                    .foregroundColor(.secondary)
//            }
//            
//            HStack {
//                VStack(alignment: .leading, spacing: 4) {
//                    Text("Avg Price")
//                        .font(.caption)
//                        .foregroundColor(.secondary)
//                    Text("€\(analytics.averagePrice)")
//                        .font(.subheadline)
//                        .fontWeight(.medium)
//                }
//                
//                Spacer()
//                
//                VStack(alignment: .center, spacing: 4) {
//                    Text("Price Range")
//                        .font(.caption)
//                        .foregroundColor(.secondary)
//                    Text("€\(analytics.minPrice) - €\(analytics.maxPrice)")
//                        .font(.caption)
//                        .fontWeight(.medium)
//                }
//                
//                Spacer()
//                
//                VStack(alignment: .trailing, spacing: 4) {
//                    Text("Sale Rate")
//                        .font(.caption)
//                        .foregroundColor(.secondary)
//                    Text("\(String(format: "%.1f", analytics.salePercentage))%")
//                        .font(.subheadline)
//                        .fontWeight(.medium)
//                        .foregroundColor(analytics.salePercentage > 10 ? .green : .primary)
//                }
//            }
//        }
//        .padding()
//        .background(Color(.systemGray6))
//        .clipShape(RoundedRectangle(cornerRadius: 8))
//    }
//}
//
//public struct CategoryAnalyticsRowView: View {
//    let analytics: CategoryAnalytics
//    
//    public init(analytics: CategoryAnalytics) {
//        self.analytics = analytics
//    }
//    
//    public var body: some View {
//        HStack {
//            VStack(alignment: .leading, spacing: 4) {
//                Text(analytics.category)
//                    .font(.headline)
//                
//                Text("\(analytics.totalProducts) products")
//                    .font(.caption)
//                    .foregroundColor(.secondary)
//            }
//            
//            Spacer()
//            
//            VStack(alignment: .trailing, spacing: 4) {
//                Text("€\(analytics.averagePrice)")
//                    .font(.headline)
//                    .foregroundColor(.blue)
//                
//                Text("avg price")
//                    .font(.caption)
//                    .foregroundColor(.secondary)
//            }
//        }
//        .padding()
//        .background(Color(.systemGray6))
//        .clipShape(RoundedRectangle(cornerRadius: 8))
//    }
//}
//
//public struct BestDealRowView: View {
//    let product: UnifiedProduct
//    
//    public init(product: UnifiedProduct) {
//        self.product = product
//    }
//    
//    public var body: some View {
//        HStack {
//            VStack(alignment: .leading, spacing: 4) {
//                Text(product.name)
//                    .font(.headline)
//                    .lineLimit(2)
//                
//                if let brand = product.brand {
//                    Text(brand)
//                        .font(.caption)
//                        .foregroundColor(.secondary)
//                }
//            }
//            
//            Spacer()
//            
//            VStack(alignment: .trailing, spacing: 4) {
//                Text("€\(product.unitPrice)")
//                    .font(.headline)
//                    .foregroundColor(.green)
//                
//                ProviderBadgeView(provider: product.provider)
//            }
//        }
//        .padding()
//        .background(
//            RoundedRectangle(cornerRadius: 8)
//                .fill(.green.opacity(0.1))
//                .overlay(
//                    RoundedRectangle(cornerRadius: 8)
//                        .stroke(.green.opacity(0.3), lineWidth: 1)
//                )
//        )
//    }
//}
//
//@MainActor
//class AnalyticsViewModel: ObservableObject {
//    @Published var products: [UnifiedProduct] = []
//    @Published var providerAnalytics: [ProviderAnalytics] = []
//    @Published var categoryAnalytics: [CategoryAnalytics] = []
//    @Published var bestDeals: [UnifiedProduct] = []
//    @Published var isLoading = false
//    @Published var errorMessage: String?
//    
//    private let dataManager: DataManager
//    private let analyticsService = PriceAnalyticsService()
//    
//    var providerCount: Int {
//        Set(products.map { $0.provider }).count
//    }
//    
//    var categoryCount: Int {
//        Set(products.compactMap { $0.category }).count
//    }
//    
//    var onSaleCount: Int {
//        products.filter { $0.isOnSale }.count
//    }
//    
//    init() {
//        do {
//            let storage = try FileStorage()
//            self.dataManager = DataManager(storage: storage)
//        } catch {
//            fatalError("Failed to initialize storage: \(error)")
//        }
//    }
//    
//    func loadData() async {
//        isLoading = true
//        errorMessage = nil
//        
//        do {
//            products = try await dataManager.loadProducts()
//            generateAnalytics()
//            bestDeals = try await dataManager.getBestDeals(limit: 5)
//        } catch {
//            errorMessage = error.localizedDescription
//        }
//        
//        isLoading = false
//    }
//    
//    func refreshData() async {
//        isLoading = true
//        errorMessage = nil
//        
//        do {
//            _ = try await dataManager.refreshData()
//            products = try await dataManager.loadProducts()
//            generateAnalytics()
//            bestDeals = try await dataManager.getBestDeals(limit: 5)
//        } catch {
//            errorMessage = error.localizedDescription
//        }
//        
//        isLoading = false
//    }
//    
//    private func generateAnalytics() {
//        providerAnalytics = analyticsService.generateProviderAnalytics(products)
//        categoryAnalytics = analyticsService.generateCategoryAnalytics(products)
//    }
//}
//
//#Preview { AnalyticsView() }
