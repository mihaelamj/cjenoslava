//import SwiftUI
//import CroatianGroceryCore
//
//public struct ProductListView: View {
//    @StateObject private var viewModel = ProductListViewModel()
//    @State private var searchText = ""
//    @State private var selectedProvider: GroceryProvider?
//    @State private var showingFilters = false
//    
//    public init() {}
//    
//    public var body: some View {
//        NavigationView {
//            VStack {
//                searchAndFilterSection
//                
//                if viewModel.isLoading {
//                    ProgressView("Loading products...")
//                        .frame(maxWidth: .infinity, maxHeight: .infinity)
//                } else if viewModel.filteredProducts.isEmpty {
//                    emptyStateView
//                } else {
//                    productsList
//                }
//            }
//            .navigationTitle("Grocery Prices")
//            .toolbar {
//                ToolbarItem(placement: .navigationBarTrailing) {
//                    Button("Refresh") {
//                        Task {
//                            await viewModel.refreshData()
//                        }
//                    }
//                }
//            }
//            .sheet(isPresented: $showingFilters) {
//                FiltersView(selectedProvider: $selectedProvider) {
//                    viewModel.applyFilters(provider: selectedProvider)
//                }
//            }
//        }
//        .task {
//            await viewModel.loadProducts()
//        }
//        .onChange(of: searchText) { _, newValue in
//            viewModel.searchProducts(query: newValue)
//        }
//    }
//    
//    private var searchAndFilterSection: some View {
//        VStack {
//            HStack {
//                Image(systemName: "magnifyingglass")
//                    .foregroundColor(.secondary)
//                
//                TextField("Search products...", text: $searchText)
//                    .textFieldStyle(RoundedBorderTextFieldStyle())
//                
//                Button(action: { showingFilters = true }) {
//                    Image(systemName: "line.3.horizontal.decrease.circle")
//                        .foregroundColor(.blue)
//                }
//            }
//            .padding(.horizontal)
//            
//            if let provider = selectedProvider {
//                HStack {
//                    Text("Filtered by: \(provider.displayName)")
//                        .font(.caption)
//                        .foregroundColor(.secondary)
//                    
//                    Spacer()
//                    
//                    Button("Clear") {
//                        selectedProvider = nil
//                        viewModel.clearFilters()
//                    }
//                    .font(.caption)
//                }
//                .padding(.horizontal)
//            }
//        }
//    }
//    
//    private var productsList: some View {
//        List(viewModel.filteredProducts) { product in
//            ProductRowView(product: product)
//        }
//    }
//    
//    private var emptyStateView: some View {
//        VStack(spacing: 16) {
//            Image(systemName: "cart.badge.questionmark")
//                .font(.system(size: 48))
//                .foregroundColor(.secondary)
//            
//            Text("No products found")
//                .font(.headline)
//            
//            Text("Try adjusting your search or filters")
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
//        .frame(maxWidth: .infinity, maxHeight: .infinity)
//    }
//}
//
//public struct ProductRowView: View {
//    let product: UnifiedProduct
//    
//    public init(product: UnifiedProduct) {
//        self.product = product
//    }
//    
//    public var body: some View {
//        VStack(alignment: .leading, spacing: 8) {
//            HStack {
//                VStack(alignment: .leading, spacing: 4) {
//                    Text(product.name)
//                        .font(.headline)
//                        .lineLimit(2)
//                    
//                    if let brand = product.brand {
//                        Text(brand)
//                            .font(.subheadline)
//                            .foregroundColor(.secondary)
//                    }
//                    
//                    if let category = product.category {
//                        Text(category)
//                            .font(.caption)
//                            .padding(.horizontal, 8)
//                            .padding(.vertical, 2)
//                            .background(Color.blue.opacity(0.1))
//                            .foregroundColor(.blue)
//                            .clipShape(Capsule())
//                    }
//                }
//                
//                Spacer()
//                
//                VStack(alignment: .trailing, spacing: 4) {
//                    HStack {
//                        if product.isOnSale {
//                            VStack(alignment: .trailing, spacing: 2) {
//                                if let originalPrice = product.originalPrice {
//                                    Text("€\(originalPrice)")
//                                        .font(.caption)
//                                        .strikethrough()
//                                        .foregroundColor(.secondary)
//                                }
//                                Text("€\(product.unitPrice)")
//                                    .font(.headline)
//                                    .foregroundColor(.red)
//                            }
//                        } else {
//                            Text("€\(product.unitPrice)")
//                                .font(.headline)
//                        }
//                    }
//                    
//                    Text("per \(product.unit)")
//                        .font(.caption)
//                        .foregroundColor(.secondary)
//                    
//                    ProviderBadgeView(provider: product.provider)
//                }
//            }
//            
//            if product.isOnSale {
//                HStack {
//                    Image(systemName: "flame.fill")
//                        .foregroundColor(.red)
//                    Text("On Sale")
//                        .font(.caption)
//                        .fontWeight(.medium)
//                        .foregroundColor(.red)
//                    Spacer()
//                }
//            }
//        }
//        .padding(.vertical, 4)
//    }
//}
//
//public struct ProviderBadgeView: View {
//    let provider: GroceryProvider
//    
//    public init(provider: GroceryProvider) {
//        self.provider = provider
//    }
//    
//    public var body: some View {
//        Text(provider.displayName)
//            .font(.caption)
//            .fontWeight(.medium)
//            .padding(.horizontal, 8)
//            .padding(.vertical, 4)
//            .background(providerColor.opacity(0.2))
//            .foregroundColor(providerColor)
//            .clipShape(RoundedRectangle(cornerRadius: 8))
//    }
//    
//    private var providerColor: Color {
//        switch provider {
//        case .plodine: return .green
//        case .tommy: return .blue
//        case .lidl: return .yellow
//        case .spar: return .orange
//        case .studenac: return .red
//        case .dm: return .pink
//        case .eurospin: return .purple
//        case .konzum: return .cyan
//        case .kaufland: return .indigo
//        case .ktc: return .brown
//        }
//    }
//}
//
//public struct FiltersView: View {
//    @Binding var selectedProvider: GroceryProvider?
//    let onApply: () -> Void
//    @Environment(.dismiss) private var dismiss
//    
//    public init(selectedProvider: Binding<GroceryProvider?>, onApply: @escaping () -> Void) {
//        self._selectedProvider = selectedProvider
//        self.onApply = onApply
//    }
//    
//    public var body: some View {
//        NavigationView {
//            Form {
//                Section("Provider") {
//                    Picker("Select Provider", selection: $selectedProvider) {
//                        Text("All Providers").tag(nil as GroceryProvider?)
//                        ForEach(GroceryProvider.allCases, id: \.self) { provider in
//                            Text(provider.displayName).tag(provider as GroceryProvider?)
//                        }
//                    }
//                    .pickerStyle(.wheel)
//                }
//            }
//            .navigationTitle("Filters")
//            .navigationBarTitleDisplayMode(.inline)
//            .toolbar {
//                ToolbarItem(placement: .navigationBarLeading) {
//                    Button("Cancel") {
//                        dismiss()
//                    }
//                }
//                
//                ToolbarItem(placement: .navigationBarTrailing) {
//                    Button("Apply") {
//                        onApply()
//                        dismiss()
//                    }
//                }
//            }
//        }
//    }
//}
//
//@MainActor
//class ProductListViewModel: ObservableObject {
//    @Published var products: [UnifiedProduct] = []
//    @Published var filteredProducts: [UnifiedProduct] = []
//    @Published var isLoading = false
//    @Published var errorMessage: String?
//    
//    private let dataManager: DataManager
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
//    func loadProducts() async {
//        isLoading = true
//        errorMessage = nil
//        
//        do {
//            products = try await dataManager.loadProducts()
//            filteredProducts = products
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
//            filteredProducts = products
//        } catch {
//            errorMessage = error.localizedDescription
//        }
//        
//        isLoading = false
//    }
//    
//    func searchProducts(query: String) {
//        if query.isEmpty {
//            filteredProducts = products
//        } else {
//            let comparisonService = PriceComparisonService()
//            filteredProducts = comparisonService.searchProducts(products, query: query)
//        }
//    }
//    
//    func applyFilters(provider: GroceryProvider?) {
//        if let provider = provider {
//            let comparisonService = PriceComparisonService()
//            filteredProducts = comparisonService.filterByProvider(products, providers: [provider])
//        } else {
//            filteredProducts = products
//        }
//    }
//    
//    func clearFilters() {
//        filteredProducts = products
//    }
//}
//
//#Preview { ProductListView() }
