import CoreData
import Foundation

@objc(PhotoEntity)
public class PhotoEntity: NSManagedObject {
    
    // MARK: - Convenience Methods
    
    func toPhoto() -> Photo? {
        guard
            let id = self.id,
            let smallURLString = self.smallURL,
            let regularURLString = self.regularURL,
            let fullURLString = self.fullURL,
            let smallURL = URL(string: smallURLString),
            let regularURL = URL(string: regularURLString),
            let fullURL = URL(string: fullURLString),
            let color = self.color
        else {
            return nil
        }
        
        return Photo(
            id: id,
            createdAt: self.createdAt,
            size: CGSize(width: CGFloat(self.width), height: CGFloat(self.height)),
            color: color,
            isLiked: self.isLiked,
            description: self.photoDescription ?? "",
            urls: Photo.PhotoURLs(
                small: smallURL,
                regular: regularURL,
                full: fullURL
            )
        )
    }
    
    func updateFrom(photo: Photo, position: Int32) {
        self.id = photo.id
        self.createdAt = photo.createdAt
        self.width = Int32(photo.size.width)
        self.height = Int32(photo.size.height)
        self.color = photo.color
        self.isLiked = photo.isLiked
        self.photoDescription = photo.description
        self.smallURL = photo.urls.small.absoluteString
        self.regularURL = photo.urls.regular.absoluteString
        self.fullURL = photo.urls.full.absoluteString
        self.position = position  // Changed from pageNumber to position
        self.lastUpdated = Date()
    }
    
    static func create(from photo: Photo, position: Int32, in context: NSManagedObjectContext) -> PhotoEntity {
        let entity = PhotoEntity(context: context)
        entity.updateFrom(photo: photo, position: position)
        return entity
    }
}

extension PhotoEntity {
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<PhotoEntity> {
        return NSFetchRequest<PhotoEntity>(entityName: "PhotoEntity")
    }
    
    @NSManaged public var id: String?
    @NSManaged public var createdAt: Date?
    @NSManaged public var width: Int32
    @NSManaged public var height: Int32
    @NSManaged public var color: String?
    @NSManaged public var isLiked: Bool
    @NSManaged public var photoDescription: String?
    @NSManaged public var smallURL: String?
    @NSManaged public var regularURL: String?
    @NSManaged public var fullURL: String?
    @NSManaged public var position: Int32      // Changed from pageNumber to position
    @NSManaged public var lastUpdated: Date?
    
}

extension PhotoEntity : Identifiable {
    
}
