import Foundation
import SwiftData

@Model
final class Photo {
    var id: UUID
    var createdAt: Date
    var importedAt: Date
    var type: PhotoType
    
    // Image data
    @Attribute(.externalStorage) var imageData: Data?
    @Attribute(.externalStorage) var thumbnailData: Data?
    var width: Int
    var height: Int
    
    // Source info
    var sourceType: SourceType
    var sourceURL: String?
    var sourceAssetID: String?
    
    // AI features
    var embedding: [Float]?
    var dominantColors: [String]?
    var analyzedAt: Date?
    
    init(
        id: UUID = UUID(),
        createdAt: Date = Date(),
        importedAt: Date = Date(),
        type: PhotoType = .myWork,
        imageData: Data? = nil,
        thumbnailData: Data? = nil,
        width: Int = 0,
        height: Int = 0,
        sourceType: SourceType = .photoLibrary,
        sourceURL: String? = nil,
        sourceAssetID: String? = nil,
        embedding: [Float]? = nil,
        dominantColors: [String]? = nil,
        analyzedAt: Date? = nil
    ) {
        self.id = id
        self.createdAt = createdAt
        self.importedAt = importedAt
        self.type = type
        self.imageData = imageData
        self.thumbnailData = thumbnailData
        self.width = width
        self.height = height
        self.sourceType = sourceType
        self.sourceURL = sourceURL
        self.sourceAssetID = sourceAssetID
        self.embedding = embedding
        self.dominantColors = dominantColors
        self.analyzedAt = analyzedAt
    }
}

enum PhotoType: String, Codable {
    case myWork = "my_work"
    case inspiration = "inspiration"
    
    var displayName: String {
        switch self {
        case .myWork: return "我的作品"
        case .inspiration: return "灵感"
        }
    }
    
    var icon: String {
        switch self {
        case .myWork: return "camera.fill"
        case .inspiration: return "star.fill"
        }
    }
}

enum SourceType: String, Codable {
    case photoLibrary
    case clipboard
    case url
}
