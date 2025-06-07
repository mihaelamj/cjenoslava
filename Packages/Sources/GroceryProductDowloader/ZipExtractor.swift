import Foundation
import ZIPFoundation

// Note: This file requires SharedTypes.swift for RawData definition

// MARK: - ZIP Extraction Errors

public enum ZipExtractionError: Error, LocalizedError {
    case extractionFailed
    case invalidZipData
    case fileNotFound
    case permissionDenied
    case unsupportedFormat
    
    public var errorDescription: String? {
        switch self {
        case .extractionFailed:
            return "Failed to extract ZIP archive"
        case .invalidZipData:
            return "Invalid or corrupted ZIP data"
        case .fileNotFound:
            return "ZIP file not found"
        case .permissionDenied:
            return "Permission denied for ZIP extraction"
        case .unsupportedFormat:
            return "Unsupported ZIP format"
        }
    }
}

// MARK: - Extracted File Info

public struct ExtractedFile: Sendable {
    public let name: String
    public let data: Data
    public let originalPath: String
    public let contentType: String
    
    public init(name: String, data: Data, originalPath: String, contentType: String = "application/octet-stream") {
        self.name = name
        self.data = data
        self.originalPath = originalPath
        self.contentType = contentType
    }
    
    public var fileExtension: String {
        return (name as NSString).pathExtension.lowercased()
    }
    
    public var textContent: String? {
        return String(data: data, encoding: .utf8) ?? String(data: data, encoding: .windowsCP1250)
    }
}

// MARK: - ZIP Extractor

public actor ZipExtractor {
    
    private let fileManager: FileManager
    
    public init() {
        self.fileManager = FileManager.default
    }
    
    // MARK: - Main Extraction Methods
    
    /// Extract files from ZIP data with optional file extension filtering
    public func extractFiles(
        from zipData: Data,
        fileExtensions: [String] = [],
        preserveDirectoryStructure: Bool = false
    ) async throws -> [ExtractedFile] {
        
        return try await withCheckedThrowingContinuation { continuation in
            do {
                let archive = try Archive(data: zipData, accessMode: .read)
                var extractedFiles: [ExtractedFile] = []
                
                for entry in archive {
                    // Skip directories
                    guard entry.type == .file else { continue }
                    
                    let fileExtension = (entry.path as NSString).pathExtension.lowercased()
                    
                    // Filter by file extensions if specified
                    if !fileExtensions.isEmpty && !fileExtensions.contains(fileExtension) {
                        continue
                    }
                    
                    // Extract file data
                    var fileData = Data()
                    _ = try archive.extract(entry) { data in
                        fileData.append(data)
                    }
                    
                    // Determine file name and path
                    let fileName = (entry.path as NSString).lastPathComponent
                    let originalPath = preserveDirectoryStructure ? entry.path : fileName
                    
                    // Determine content type
                    let contentType = determineContentType(for: fileName, data: fileData)
                    
                    let extractedFile = ExtractedFile(
                        name: fileName,
                        data: fileData,
                        originalPath: originalPath,
                        contentType: contentType
                    )
                    
                    extractedFiles.append(extractedFile)
                }
                
                continuation.resume(returning: extractedFiles)
                
            } catch {
                continuation.resume(throwing: ZipExtractionError.extractionFailed)
            }
        }
    }
    
    /// Extract specific file types (convenience method)
    public func extractCSVFiles(from zipData: Data) async throws -> [ExtractedFile] {
        return try await extractFiles(from: zipData, fileExtensions: ["csv"])
    }
    
    /// Extract XML files (convenience method)
    public func extractXMLFiles(from zipData: Data) async throws -> [ExtractedFile] {
        return try await extractFiles(from: zipData, fileExtensions: ["xml"])
    }
    
    /// Extract Excel files (convenience method)
    public func extractExcelFiles(from zipData: Data) async throws -> [ExtractedFile] {
        return try await extractFiles(from: zipData, fileExtensions: ["xlsx", "xls"])
    }
    
    /// Extract files and convert to RawData format (for compatibility with existing downloaders)
    public func extractToRawData(
        from zipData: Data,
        sourceURL: URL,
        fileExtensions: [String] = []
    ) async throws -> [RawData] {
        
        let extractedFiles = try await extractFiles(
            from: zipData,
            fileExtensions: fileExtensions
        )
        
        return extractedFiles.map { file in
            // Determine encoding based on content type and Croatian locale
            let encoding: String.Encoding = {
                if file.contentType.contains("csv") || file.contentType.contains("xml") {
                    // Try UTF-8 first, fallback to Windows-1250 for Croatian content
                    return String(data: file.data, encoding: .utf8) != nil ? .utf8 : .windowsCP1250
                }
                return .utf8
            }()
            
            return RawData(
                content: file.data,
                url: sourceURL.appendingPathComponent(file.name),
                contentType: file.contentType,
                encoding: encoding,
                metadata: [
                    "originalPath": file.originalPath,
                    "fileName": file.name,
                    "fileSize": String(file.data.count)
                ]
            )
        }
    }
    
    // MARK: - File Type Detection
    
    private func determineContentType(for fileName: String, data: Data) -> String {
        let fileExtension = (fileName as NSString).pathExtension.lowercased()
        
        switch fileExtension {
        case "csv":
            return "text/csv"
        case "xml":
            return "application/xml"
        case "json":
            return "application/json"
        case "txt":
            return "text/plain"
        case "xlsx", "xls":
            return "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
        case "pdf":
            return "application/pdf"
        case "html", "htm":
            return "text/html"
        default:
            // Try to detect based on content
            if let text = String(data: data.prefix(100), encoding: .utf8) {
                if text.contains("<?xml") {
                    return "application/xml"
                } else if text.contains("\"") && text.contains(",") {
                    return "text/csv"
                } else if text.contains("<html") || text.contains("<!DOCTYPE") {
                    return "text/html"
                }
            }
            return "application/octet-stream"
        }
    } "
