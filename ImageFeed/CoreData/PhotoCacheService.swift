import CoreData
import Foundation

final class PhotoCacheService: PhotoCacheServiceProtocol {
    static let shared = PhotoCacheService()
    
    private init() {}
    
    private let coreDataStack = CoreDataStack.shared
    private let cacheExpirationInterval: TimeInterval = 10 * 60 // 10 minutes
    
    // MARK: - Public Methods
    
    /// Saves photos to Core Data cache with position-based approach
    func savePhotos(_ photos: [Photo], startingFromPosition position: Int) {
        let context = coreDataStack.newBackgroundContext()
        
        context.perform {
            for (index, photo) in photos.enumerated() {
                let photoPosition = position + index
                
                // Check if photo already exists
                if let existingPhoto = self.fetchPhoto(withId: photo.id, in: context) {
                    existingPhoto.updateFrom(photo: photo, position: Int32(photoPosition))
                } else {
                    _ = PhotoEntity.create(from: photo, position: Int32(photoPosition), in: context)
                }
            }
            
            self.coreDataStack.saveContext(context)
        }
    }
    
    /// Efficiently shifts all cached photos positions by given offset using batch update
    func shiftCachedPhotosPositions(by offset: Int) {
        let context = coreDataStack.newBackgroundContext()
        
        context.perform {
            // Use NSBatchUpdateRequest for efficiency - updates all records without loading into memory
            let batchUpdateRequest = NSBatchUpdateRequest(entityName: "PhotoEntity")
            batchUpdateRequest.propertiesToUpdate = [
                "position": NSExpression(format: "position + %d", offset)
            ]
            batchUpdateRequest.resultType = .updatedObjectsCountResultType
            
            do {
                let batchResult = try context.execute(batchUpdateRequest) as? NSBatchUpdateResult
                let updatedCount = batchResult?.result as? Int ?? 0
                
                print("[PhotoCacheService] Efficiently shifted \(updatedCount) photos by \(offset) positions")
                
                // Refresh the view context to see the changes
                DispatchQueue.main.async {
                    self.coreDataStack.viewContext.refreshAllObjects()
                }
                
            } catch {
                print("[PhotoCacheService] Error shifting positions with batch update: \(error)")
                // Fallback to individual updates if batch fails
                self.shiftCachedPhotosPositionsFallback(by: offset, in: context)
            }
        }
    }
    
    /// Fallback method for shifting positions if batch update fails
    private func shiftCachedPhotosPositionsFallback(by offset: Int, in context: NSManagedObjectContext) {
        let request: NSFetchRequest<PhotoEntity> = PhotoEntity.fetchRequest()
        
        do {
            let entities = try context.fetch(request)
            for entity in entities {
                entity.position += Int32(offset)
            }
            self.coreDataStack.saveContext(context)
            print("[PhotoCacheService] Fallback: Shifted \(entities.count) photos by \(offset) positions")
        } catch {
            print("[PhotoCacheService] Error in fallback shift: \(error)")
        }
    }
    
    /// Fetches cached photos ordered by position
    func fetchAllCachedPhotos() -> [Photo] {
        let context = coreDataStack.viewContext
        let request: NSFetchRequest<PhotoEntity> = PhotoEntity.fetchRequest()
        
        // Sort by position (which represents order in the feed)
        let positionSort = NSSortDescriptor(key: "position", ascending: true)
        request.sortDescriptors = [positionSort]
        
        do {
            let entities = try context.fetch(request)
            return entities.compactMap { $0.toPhoto() }
        } catch {
            print("[PhotoCacheService] Error fetching cached photos: \(error)")
            return []
        }
    }
    
    /// Checks if cache needs refresh based on last update time
    func needsCacheRefresh() -> Bool {
        let context = coreDataStack.viewContext
        let request: NSFetchRequest<PhotoEntity> = PhotoEntity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "lastUpdated", ascending: false)]
        request.fetchLimit = 1
        
        do {
            let entities = try context.fetch(request)
            guard let lastUpdated = entities.first?.lastUpdated else {
                return true // No cached data, needs refresh
            }
            
            let timeSinceLastUpdate = Date().timeIntervalSince(lastUpdated)
            return timeSinceLastUpdate > cacheExpirationInterval
        } catch {
            print("[PhotoCacheService] Error checking cache refresh: \(error)")
            return true
        }
    }
    
    /// Checks if photo with given ID exists in cache
    func photoExists(withId id: String) -> Bool {
        let context = coreDataStack.viewContext
        return fetchPhoto(withId: id, in: context) != nil
    }
    
    /// Gets the count of cached photos
    func getCachedPhotosCount() -> Int {
        let context = coreDataStack.viewContext
        let request: NSFetchRequest<PhotoEntity> = PhotoEntity.fetchRequest()
        
        do {
            return try context.count(for: request)
        } catch {
            print("[PhotoCacheService] Error getting cached photos count: \(error)")
            return 0
        }
    }
    
    /// Updates like status for a photo in cache
    func updatePhotoLikeStatus(photoId: String, isLiked: Bool) {
        let context = coreDataStack.newBackgroundContext()
        
        context.perform {
            if let photo = self.fetchPhoto(withId: photoId, in: context) {
                photo.isLiked = isLiked
                self.coreDataStack.saveContext(context)
            }
        }
    }
    
    /// Clears all cached photos
    func clearCache() {
        let context = coreDataStack.newBackgroundContext()
        
        context.perform {
            let request: NSFetchRequest<NSFetchRequestResult> = PhotoEntity.fetchRequest()
            let deleteRequest = NSBatchDeleteRequest(fetchRequest: request)
            
            do {
                try context.execute(deleteRequest)
                self.coreDataStack.saveContext(context)
                print("[PhotoCacheService] Cache cleared successfully")
            } catch {
                print("[PhotoCacheService] Error clearing cache: \(error)")
            }
        }
    }
    
    /// Gets cached photos in a specific range
    func getCachedPhotos(from startPosition: Int, count: Int) -> [Photo] {
        let context = coreDataStack.viewContext
        let request: NSFetchRequest<PhotoEntity> = PhotoEntity.fetchRequest()
        
        let startPos = Int32(startPosition)
        let endPos = Int32(startPosition + count - 1)
        request.predicate = NSPredicate(format: "position >= %d AND position <= %d", startPos, endPos)
        request.sortDescriptors = [NSSortDescriptor(key: "position", ascending: true)]
        
        do {
            let entities = try context.fetch(request)
            return entities.compactMap { $0.toPhoto() }
        } catch {
            print("[PhotoCacheService] Error fetching cached photos in range: \(error)")
            return []
        }
    }
    
    // MARK: - Private Methods
    
    private func fetchPhoto(withId id: String, in context: NSManagedObjectContext) -> PhotoEntity? {
        let request: NSFetchRequest<PhotoEntity> = PhotoEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id)
        request.fetchLimit = 1
        
        do {
            return try context.fetch(request).first
        } catch {
            print("[PhotoCacheService] Error fetching photo with id \(id): \(error)")
            return nil
        }
    }
}
