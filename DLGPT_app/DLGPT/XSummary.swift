import Foundation

struct XSummary: Decodable {
    let summaryType: String
    let generatedAt: String
    let feedWindowStart: String
    let feedWindowEnd: String
    let weightedMeanTime: String?
    let totalRawItems: Int
    let totalCleanedItems: Int
    let excludedReplyCount: Int
    let excludedAdCount: Int
    let excludedOtherCount: Int
    let totalAnalysedItems: Int
    let headline: String
    let themes: [XTheme]
    let notableItems: [XNotableItem]
}

struct XTheme: Decodable {
    let name: String
    let count: Int
    let percentage: Double
}

struct XNotableItem: Decodable {
    let id: String
    let authorName: String
    let authorHandle: String
    let text: String
    let reason: String
    let url: String?
    let publishedAt: String
    let themeName: String?
}
