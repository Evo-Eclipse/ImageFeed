protocol PhotoCacheServiceProtocol {
    func savePhotos(_ photos: [Photo], startingFromPosition position: Int)
    func shiftCachedPhotosPositions(by offset: Int)
    func fetchAllCachedPhotos() -> [Photo]
    func needsCacheRefresh() -> Bool
    func photoExists(withId id: String) -> Bool
    func getCachedPhotosCount() -> Int
    func updatePhotoLikeStatus(photoId: String, isLiked: Bool)
    func clearCache()
    func getCachedPhotos(from startPosition: Int, count: Int) -> [Photo]
}
