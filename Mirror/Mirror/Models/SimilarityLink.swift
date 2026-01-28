import Foundation
import SwiftData

@Model
final class SimilarityLink {
    var id: UUID
    var photoAId: UUID
    var photoBId: UUID
    var overallScore: Float
    var compositionScore: Float?
    var colorScore: Float?
    var subjectScore: Float?
    var createdAt: Date
    var description: String?
    
    init(
        id: UUID = UUID(),
        photoAId: UUID,
        photoBId: UUID,
        overallScore: Float,
        compositionScore: Float? = nil,
        colorScore: Float? = nil,
        subjectScore: Float? = nil,
        createdAt: Date = Date(),
        description: String? = nil
    ) {
        self.id = id
        self.photoAId = photoAId
        self.photoBId = photoBId
        self.overallScore = overallScore
        self.compositionScore = compositionScore
        self.colorScore = colorScore
        self.subjectScore = subjectScore
        self.createdAt = createdAt
        self.description = description
    }
}
