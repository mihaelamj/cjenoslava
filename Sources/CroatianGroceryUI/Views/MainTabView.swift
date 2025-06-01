import SwiftUI
import CroatianGroceryCore
public struct MainTabView: View {
    
    public init() {}
    
    public var body: some View {
        TabView {
            ProductListView()
                .tabItem {
                    Label("Products", systemImage: "list.bullet")
                }
            
            PriceComparisonView()
                .tabItem {
                    Label("Compare", systemImage: "chart.bar")
                }
            
            AnalyticsView()
                .tabItem {
                    Label("Analytics", systemImage: "chart.pie")
                }
            
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
        }
    }
}

public struct SettingsView: View {
    @StateObject private var viewModel = SettingsViewModel()
    @State private var showingExportSheet = false
    @State private var showingDeleteAlert = false
    
    public init() {}
    
    public var body: some View {
        NavigationView {
            List {
                dataSection
                exportSection
                aboutSection
            }
            .navigationTitle("Settings")
        }
        .sheet(isPresented: $showingExportSheet) {
            ExportSheetView()
        }
        .alert("Delete All Data", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                Task {
                    await viewModel.clearData()
                }
            }
        } message: {
            Text("This will permanently delete all downloaded product data and collection history. This action cannot be undone.")
        }
    }
    
    private var dataSection: some View {
        Section("Data Management") {
            HStack {
                Label("Last Updated", systemImage: "clock")
                Spacer()
                Text(viewModel.lastUpdateText)
                    .foregroundColor(.secondary)
            }
            
            HStack {
                Label("Products", systemImage: "cart")
                Spacer()
                Text("\(viewModel.productCount)")
                    .foregroundColor(.secondary)
            }
            
            Button(action: {
                Task {
                    await viewModel.refreshData()
                }
            }) {
                Label("Refresh Data", systemImage: "arrow.clockwise")
            }
            .disabled(viewModel.isRefreshing)
            
            Button(action: {
                showingDeleteAlert = true
            }) {
                Label("Clear All Data", systemImage: "trash")
                    .foregroundColor(.red)
            }
        }
    }
    
    private var exportSection: some View {
        Section("Export") {
            Button(action: {
                showingExportSheet = true
            }) {
                Label("Export Data", systemImage: "square.and.arrow.up")
            }
        }
    }
    
    private var aboutSection: some View {
        Section("About") {
            HStack {
                Label("Version", systemImage: "info.circle")
                Spacer()
                Text("1.0.0")
                    .foregroundColor(.secondary)
            }
            
            Link(destination: URL(string: "https://github.com/your-repo/croatian-grocery-tracker")!) {
                Label("Source Code", systemImage: "chevron.left.forwardslash.chevron.right")
            }
            
            HStack {
                Label("Data Sources", systemImage: "link")
                Spacer()
                Text("\(GroceryProvider.allCases.count) providers")
                    .foregroundColor(.secondary)
            }
        }
    }
}

public struct ExportSheetView: View {
    @StateObject private var viewModel = ExportViewModel()
    @State private var selectedFormat: ExportFormat = .csv
    @State private var exportType: ExportType = .products
    @Environment(\.dismiss) private var dismiss
    
    public init() {}
    
    public var body: some View {
        NavigationView {
            Form {
                Section("Export Type") {
                    Picker("Type", selection: $exportType) {
                        Text("Products").tag(ExportType.products)
                        Text("Price Comparisons").tag(ExportType.comparisons)
                    }
                    .pickerStyle(.segmented)
                }
                
                Section("Format") {
                    Picker("Format", selection: $selectedFormat) {
                        Text("CSV").tag(ExportFormat.csv)
                        Text("JSON").tag(ExportFormat.json)
                    }
                    .pickerStyle(.segmented)
                }
                
                Section {
                    Button(action: {
                        Task {
                            await viewModel.export(type: exportType, format: selectedFormat)
                        }
                    }) {
                        HStack {
                            if viewModel.isExporting {
                                ProgressView()
                                    .scaleEffect(0.8)
                            }
                            
                            Text(viewModel.isExporting ? "Exporting..." : "Export")
                        }
                    }
                    .disabled(viewModel.isExporting)
                }
            }
            .navigationTitle("Export Data")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                Button("Done") {
                    dismiss()
                }
            }
        }
        .alert("Export Complete", isPresented: $viewModel.showingSuccessAlert) {
            Button("OK") { }
        } message: {
            Text("Data has been exported successfully.")
        }
        .alert("Export Failed", isPresented: $viewModel.showingErrorAlert) {
            Button("OK") { }
        } message: {
            Text(viewModel.errorMessage ?? "An unknown error occurred.")
        }
    }
}

enum ExportFormat {
    case csv, json
}

enum ExportType {
    case products, comparisons
}

@MainActor
class SettingsViewModel: ObservableObject {
    @Published var lastUpdateText = "Never"
    @Published var productCount = 0
    @Published var isRefreshing = false
    @Published var errorMessage: String?
    
    private let dataManager: DataManager
    
    init() {
        do {
            let storage = try FileStorage()
            self.dataManager = DataManager(storage: storage)
            Task {
                await loadInfo()
            }
        } catch {
            fatalError("Failed to initialize storage: \(error)")
        }
    }
    
    func loadInfo() async {
        let manager = dataManager
        let result = await Task {
            do {
                let products = try await manager.loadProducts()
                let sessions = try await manager.getSessions()
                return (products.count, sessions.last, nil as Error?)
            } catch {
                return (0, nil as DataCollectionSession?, error)
            }
        }.value
        
        if let error = result.2 {
            errorMessage = error.localizedDescription
        } else {
            productCount = result.0
            
            if let lastSession = result.1 {
                let formatter = DateFormatter()
                formatter.dateStyle = .medium
                formatter.timeStyle = .short
                lastUpdateText = formatter.string(from: lastSession.startTime)
            }
        }
    }
    
    func refreshData() async {
        isRefreshing = true
        errorMessage = nil

        let manager = dataManager
        let error = await Task {
            do {
                _ = try await manager.refreshData()
                return nil as Error?
            } catch {
                return error
            }
        }.value

        if let error = error {
            errorMessage = error.localizedDescription
        } else {
            await loadInfo()  // Safely call loadInfo
        }

        isRefreshing = false
    }
    
    func clearData() async {
        do {
            let storage = try FileStorage()
            try await storage.clear()
            await loadInfo()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

@MainActor
class ExportViewModel: ObservableObject {
    @Published var isExporting = false
    @Published var showingSuccessAlert = false
    @Published var showingErrorAlert = false
    @Published var errorMessage: String?
    
    private let dataManager: DataManager
    private let exportService = ExportService()
    
    init() {
        do {
            let storage = try FileStorage()
            self.dataManager = DataManager(storage: storage)
        } catch {
            fatalError("Failed to initialize storage: \(error)")
        }
    }
    
//    func export(type: ExportType, format: ExportFormat) async {
//        isExporting = true
//        do {
//            let data: Data
//            let fileName: String
//            
//            switch type {
//            case .products:
//                let products = try await dataManager.loadProducts()
//                
//                switch format {
//                case .csv:
//                    data = try exportService.exportToCSV(products: products)
//                    fileName = "grocery_products.csv"
//                case .json:
//                    data = try exportService.exportToJSON(products: products)
//                    fileName = "grocery_products.json"
//                }
//                
//            case .comparisons:
//                let comparisons = try await dataManager.getComparisons()
//                data = try exportService.exportComparisonsToCSV(comparisons: comparisons)
//                fileName = "price_comparisons.csv"
//            }
//#if os(iOS)
//            shareData(data, fileName: fileName)
//#else
//            // On macOS, save to Downloads folder
//            try await saveToDownloads(data, fileName: fileName)
//#endif
//            
//            showingSuccessAlert = true
//        } catch {
//            errorMessage = error.localizedDescription
//            showingErrorAlert = true
//        }
//        
//        isExporting = false
//    }
//
    
    func export(type: ExportType, format: ExportFormat) async {
        isExporting = true

        let manager = dataManager  // capture outside any background task
        let exportService = self.exportService  // if needed

        do {
            let (data, fileName): (Data, String) = try await Task {
                do {
                    switch type {
                    case .products:
                        let products = try await manager.loadProducts()
                        switch format {
                        case .csv:
                            let data = try exportService.exportToCSV(products: products)
                            return (data, "grocery_products.csv")
                        case .json:
                            let data = try exportService.exportToJSON(products: products)
                            return (data, "grocery_products.json")
                        }
                    case .comparisons:
                        let comparisons = try await manager.getComparisons()
                        let data = try exportService.exportComparisonsToCSV(comparisons: comparisons)
                        return (data, "price_comparisons.csv")
                    }
                } catch {
                    throw error
                }
            }.value

    #if os(iOS)
            shareData(data, fileName: fileName)
    #else
            try await saveToDownloads(data, fileName: fileName)
    #endif

            showingSuccessAlert = true
        } catch {
            errorMessage = error.localizedDescription
            showingErrorAlert = true
        }

        isExporting = false
    }
    
#if os(iOS)
    private func shareData(_ data: Data, fileName: String) {
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        
        do {
            try data.write(to: tempURL)
            
            let activityViewController = UIActivityViewController(
                activityItems: [tempURL],
                applicationActivities: nil
            )
            
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first {
                window.rootViewController?.present(activityViewController, animated: true)
            }
        } catch {
            errorMessage = error.localizedDescription
            showingErrorAlert = true
        }
    }
#endif
    
#if os(macOS)
    private func saveToDownloads(_ data: Data, fileName: String) async throws {
        let downloadsURL = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first!
        let fileURL = downloadsURL.appendingPathComponent(fileName)
        
        try data.write(to: fileURL)
    }
#endif
}

#Preview { MainTabView() }
