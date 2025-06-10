import Foundation
import GroceryProduct

/**
 Artikl;Pdv %;Naziv grupe artikla;Barcode;Naziv artikla / usluge; Mpc
 605646;25; alkoholna pica ;9,0288E+12;Heineken 0,33l;1,39
 605692;25; alkoholna pica ;3,8501E+12;KarLovacko pivo 0,5L;1,29
 7825;25; alkoholna pica; 3,85989+12;5 Element Lela 0,50L;1,29
 3995;25; alkoholna pica; 3,85989+12;5. ELEMENT ABA 0,50L
 ;1,29
 605266;25; alkoholna pica: 5,90054+12; EDELMEISTER IPA LIMENKA 0,5L;1,19
 605267;25; alkoholna pica: 5,90054+12; EDELMEISTER PIVO 8,8% ALC. LIMENKA 0,5L;1,39
 606475;25; alkoholna pica
 ;3,83006+12;DANA KOKTEL BLUE LAGOON 4.5% 0.33L LIM; 0,99
 607984;25; alkoholna pica ;7,2383+11; IPA Lagunitas 0.355L;1,59
 608485;25; alkoholna pica ;9,0288+12; PIVO DESPERADOS 0,33L BOCA; 1,19
 605895;25; alkoholna pica
 ; 5,90054+12; Edelmeister pilsener pivo Limenka 0,5;0,99
 607655;25; alkoholna pica; 75001629; SOL NRB 0,331;1,09
 611894;25; alkoholna pica ;4,00829+12; Krombacher pils Limenka 0,5 24/1;1,19
 607866;25; alkoholna pica; 3,85989+12;5. ELEMENT - ABA 0,5 LIM (24/1): 1,29
 */

public protocol DataDownloader: Sendable {
    func download(from url: URL) async throws -> RawData
    func downloadText(from url: URL, encoding: String.Encoding) async throws -> String
    func downloadBinary(from url: URL) async throws -> Data
}


public protocol IndexBasedDownloader: Sendable {
    func findDataURLs(for request: StoreDataRequest) async throws -> [URL]
    func downloadFromIndex(for request: StoreDataRequest) async throws -> [RawData]
}

/// Protocol for providers that serve data through APIs
public protocol APIBasedDownloader: Sendable {
    func fetchFromAPI(for request: StoreDataRequest) async throws -> [RawData]
}

/// Protocol for providers that package data in archives
public protocol ArchiveBasedDownloader: Sendable {
    func downloadAndExtractArchive(from url: URL, fileExtension: String) async throws -> [RawData]
}

/// Protocol for providers with special data formats
public protocol SpecialFormatDownloader: Sendable {
    func downloadSpecialFormat(for request: StoreDataRequest) async throws -> [RawData]
}
