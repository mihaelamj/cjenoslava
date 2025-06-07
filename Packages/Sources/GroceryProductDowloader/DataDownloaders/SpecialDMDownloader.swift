import Foundation

/// Special downloader for DM (Excel files from JSON index)
public actor SpecialDMDownloader: SpecialFormatDownloader {
    private let httpDownloader: HTTPDataDownloader
    
    public init() {
        self.httpDownloader = HTTPDataDownloader()
    }
    
    public func downloadSpecialFormat(for request: StoreDataRequest) async throws -> [RawData] {
        let indexURL = URL(string: "https://content.services.dmtech.com/rootpage-dm-shop-hr-hr/novo/promocije/nove-oznake-cijena-i-vazeci-cjenik-u-dm-u-2906632?mrclx=false")!
        
        let jsonContent = try await httpDownloader.downloadText(from: indexURL)
        let excelURL = try findExcelURL(from: jsonContent, date: request.date)
        let excelData = try await httpDownloader.download(from: excelURL)
        
        return [excelData]
    }
    
    private func findExcelURL(from jsonContent: String, date: Date) throws -> URL {
        guard let json = try JSONSerialization.jsonObject(with: jsonContent.data(using: .utf8)!) as? [String: Any],
              let mainData = json["mainData"] as? [[String: Any]] else {
            throw DownloadError.invalidJSON
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "d.M.yyyy"
        let targetDateString = dateFormatter.string(from: date)
        
        for item in mainData {
            if item["type"] as? String == "CMDownload",
               let data = item["data"] as? [String: Any],
               let headline = data["headline"] as? String,
               headline.contains(targetDateString),
               let linkTarget = data["linkTarget"] as? String {
                
                let fullURL = "https://content.services.dmtech.com/rootpage-dm-shop-hr-hr" + linkTarget
                return URL(string: fullURL)!
            }
        }
        
        throw DownloadError.dataNotFound
    }
}
