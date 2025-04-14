import Foundation

struct Photo {
    let id: String
    let createdAt: Date?
    let size: CGSize
    let color: String
    let isLiked: Bool
    let description: String
    let urls: PhotoURLs
    
    struct PhotoURLs {
        let small: URL
        let regular: URL
        let full: URL
    }
}

// MARK: - DateFormatter

extension Photo {
    static let dateFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()
}

// MARK: - Equatable

extension Photo: Equatable {
    static func == (lhs: Photo, rhs: Photo) -> Bool {
        return lhs.id == rhs.id
    }
}
