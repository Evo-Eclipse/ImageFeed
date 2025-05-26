import XCTest
import CoreData
@testable import ImageFeed

final class PhotoCacheServiceTests: XCTestCase {
    
    var mockCacheService: MockPhotoCacheService!
    
    override func setUpWithError() throws {
        super.setUp()
        mockCacheService = MockPhotoCacheService()
    }
    
    override func tearDownWithError() throws {
        mockCacheService = nil
        super.tearDown()
    }
    
    // MARK: - Cache Expiration Tests
    
    func testCacheNeedsRefreshWhenEmpty() {
        let needsRefresh = mockCacheService.needsCacheRefresh()
        XCTAssertTrue(needsRefresh)
    }
    
    func testCacheDoesNotNeedRefreshWhenFresh() {
        let testPhotos = [createTestPhoto(id: "fresh1"), createTestPhoto(id: "fresh2")]
        mockCacheService.savePhotos(testPhotos, startingFromPosition: 0)
        mockCacheService.setLastUpdateTime(Date())
        
        let needsRefresh = mockCacheService.needsCacheRefresh()
        XCTAssertFalse(needsRefresh)
    }
    
    func testCacheNeedsRefreshWhenStale() {
        let testPhotos = [createTestPhoto(id: "stale1")]
        mockCacheService.savePhotos(testPhotos, startingFromPosition: 0)
        
        let staleDate = Date().addingTimeInterval(-11 * 60)
        mockCacheService.setLastUpdateTime(staleDate)
        
        let needsRefresh = mockCacheService.needsCacheRefresh()
        XCTAssertTrue(needsRefresh)
    }
    
    // MARK: - Photo Storage Tests
    
    func testSaveAndFetchPhotos() {
        let testPhotos = [
            createTestPhoto(id: "photo1", description: "First photo"),
            createTestPhoto(id: "photo2", description: "Second photo")
        ]
        
        mockCacheService.savePhotos(testPhotos, startingFromPosition: 0)
        let cachedPhotos = mockCacheService.fetchAllCachedPhotos()
        
        XCTAssertEqual(cachedPhotos.count, 2)
        XCTAssertTrue(cachedPhotos.contains { $0.id == "photo1" })
        XCTAssertTrue(cachedPhotos.contains { $0.id == "photo2" })
        XCTAssertEqual(cachedPhotos[0].id, "photo1")
        XCTAssertEqual(cachedPhotos[1].id, "photo2")
    }
    
    func testSavePhotosWithDifferentStartingPositions() {
        let firstBatch = [createTestPhoto(id: "batch1_1"), createTestPhoto(id: "batch1_2")]
        let secondBatch = [createTestPhoto(id: "batch2_1"), createTestPhoto(id: "batch2_2")]
        
        mockCacheService.savePhotos(firstBatch, startingFromPosition: 0)
        mockCacheService.savePhotos(secondBatch, startingFromPosition: 2)
        
        let cachedPhotos = mockCacheService.fetchAllCachedPhotos()
        
        XCTAssertEqual(cachedPhotos.count, 4)
        XCTAssertEqual(cachedPhotos[0].id, "batch1_1")
        XCTAssertEqual(cachedPhotos[1].id, "batch1_2")
        XCTAssertEqual(cachedPhotos[2].id, "batch2_1")
        XCTAssertEqual(cachedPhotos[3].id, "batch2_2")
    }
    
    func testPhotoExistsCheck() {
        let testPhoto = createTestPhoto(id: "existing_photo")
        mockCacheService.savePhotos([testPhoto], startingFromPosition: 0)
        
        XCTAssertTrue(mockCacheService.photoExists(withId: "existing_photo"))
        XCTAssertFalse(mockCacheService.photoExists(withId: "nonexistent_photo"))
    }
    
    func testGetCachedPhotosCount() {
        let photos = [
            createTestPhoto(id: "count1"),
            createTestPhoto(id: "count2"),
            createTestPhoto(id: "count3")
        ]
        
        mockCacheService.savePhotos(photos, startingFromPosition: 0)
        let count = mockCacheService.getCachedPhotosCount()
        
        XCTAssertEqual(count, 3)
    }
    
    func testGetCachedPhotosInRange() {
        let photos = Array(0..<10).map { createTestPhoto(id: "photo\($0)") }
        mockCacheService.savePhotos(photos, startingFromPosition: 0)
        
        let rangePhotos = mockCacheService.getCachedPhotos(from: 2, count: 3)
        
        XCTAssertEqual(rangePhotos.count, 3)
        XCTAssertEqual(rangePhotos[0].id, "photo2")
        XCTAssertEqual(rangePhotos[1].id, "photo3")
        XCTAssertEqual(rangePhotos[2].id, "photo4")
    }
    
    // MARK: - Position Shifting Tests
    
    func testShiftCachedPhotosPositions() {
        let initialPhotos = [
            createTestPhoto(id: "shift1"),
            createTestPhoto(id: "shift2"),
            createTestPhoto(id: "shift3")
        ]
        mockCacheService.savePhotos(initialPhotos, startingFromPosition: 0)
        
        mockCacheService.shiftCachedPhotosPositions(by: 2)
        
        let newPhotos = [createTestPhoto(id: "new1"), createTestPhoto(id: "new2")]
        mockCacheService.savePhotos(newPhotos, startingFromPosition: 0)
        
        let allPhotos = mockCacheService.fetchAllCachedPhotos()
        
        XCTAssertEqual(allPhotos.count, 5)
        XCTAssertEqual(allPhotos[0].id, "new1")
        XCTAssertEqual(allPhotos[1].id, "new2")
        XCTAssertEqual(allPhotos[2].id, "shift1")
        XCTAssertEqual(allPhotos[3].id, "shift2")
        XCTAssertEqual(allPhotos[4].id, "shift3")
    }
    
    // MARK: - Like Status Tests
    
    func testUpdatePhotoLikeStatus() {
        let testPhoto = createTestPhoto(id: "likeable", isLiked: false)
        mockCacheService.savePhotos([testPhoto], startingFromPosition: 0)
        
        mockCacheService.updatePhotoLikeStatus(photoId: "likeable", isLiked: true)
        
        let cachedPhotos = mockCacheService.fetchAllCachedPhotos()
        let updatedPhoto = cachedPhotos.first { $0.id == "likeable" }
        
        XCTAssertNotNil(updatedPhoto)
        XCTAssertTrue(updatedPhoto?.isLiked ?? false)
    }
    
    // MARK: - Cache Clearing Tests
    
    func testClearCache() {
        let testPhotos = [createTestPhoto(id: "clear1"), createTestPhoto(id: "clear2")]
        mockCacheService.savePhotos(testPhotos, startingFromPosition: 0)
        
        XCTAssertEqual(mockCacheService.getCachedPhotosCount(), 2)
        
        mockCacheService.clearCache()
        
        XCTAssertEqual(mockCacheService.getCachedPhotosCount(), 0)
        XCTAssertFalse(mockCacheService.photoExists(withId: "clear1"))
        XCTAssertTrue(mockCacheService.needsCacheRefresh())
    }
    
    // MARK: - Helper Methods
    
    private func createTestPhoto(id: String = "test", isLiked: Bool = false, description: String = "Test photo") -> Photo {
        return Photo(
            id: id,
            createdAt: Date(),
            size: CGSize(width: 400, height: 600),
            color: "#FF0000",
            isLiked: isLiked,
            description: description,
            urls: Photo.PhotoURLs(
                small: URL(string: "https://example.com/\(id)_small.jpg")!,
                regular: URL(string: "https://example.com/\(id)_regular.jpg")!,
                full: URL(string: "https://example.com/\(id)_full.jpg")!
            )
        )
    }
}

// MARK: - Mock PhotoCacheService

final class MockPhotoCacheService: PhotoCacheServiceProtocol {
    
    private var cachedPhotos: [CachedPhoto] = []
    private var lastUpdateTime: Date?
    private let cacheExpirationInterval: TimeInterval = 10 * 60
    
    private struct CachedPhoto {
        let photo: Photo
        var position: Int
    }
    
    func savePhotos(_ photos: [Photo], startingFromPosition position: Int) {
        for (index, photo) in photos.enumerated() {
            let cachedPhoto = CachedPhoto(photo: photo, position: position + index)
            cachedPhotos.removeAll { $0.photo.id == photo.id }
            cachedPhotos.append(cachedPhoto)
        }
        cachedPhotos.sort { $0.position < $1.position }
        lastUpdateTime = Date()
    }
    
    func shiftCachedPhotosPositions(by offset: Int) {
        guard offset != 0 else { return }
        
        for i in 0..<cachedPhotos.count {
            cachedPhotos[i] = CachedPhoto(
                photo: cachedPhotos[i].photo,
                position: cachedPhotos[i].position + offset
            )
        }
        cachedPhotos.sort { $0.position < $1.position }
    }
    
    func fetchAllCachedPhotos() -> [Photo] {
        return cachedPhotos.sorted { $0.position < $1.position }.map { $0.photo }
    }
    
    func needsCacheRefresh() -> Bool {
        guard let lastUpdateTime = lastUpdateTime else { return true }
        let timeSinceLastUpdate = Date().timeIntervalSince(lastUpdateTime)
        return timeSinceLastUpdate > cacheExpirationInterval
    }
    
    func photoExists(withId id: String) -> Bool {
        return cachedPhotos.contains { $0.photo.id == id }
    }
    
    func getCachedPhotosCount() -> Int {
        return cachedPhotos.count
    }
    
    func updatePhotoLikeStatus(photoId: String, isLiked: Bool) {
        guard let index = cachedPhotos.firstIndex(where: { $0.photo.id == photoId }) else { return }
        
        let currentCachedPhoto = cachedPhotos[index]
        let updatedPhoto = Photo(
            id: currentCachedPhoto.photo.id,
            createdAt: currentCachedPhoto.photo.createdAt,
            size: currentCachedPhoto.photo.size,
            color: currentCachedPhoto.photo.color,
            isLiked: isLiked,
            description: currentCachedPhoto.photo.description,
            urls: currentCachedPhoto.photo.urls
        )
        
        cachedPhotos[index] = CachedPhoto(photo: updatedPhoto, position: currentCachedPhoto.position)
    }
    
    func clearCache() {
        cachedPhotos.removeAll()
        lastUpdateTime = nil
    }
    
    func getCachedPhotos(from startPosition: Int, count: Int) -> [Photo] {
        let endPosition = startPosition + count - 1
        return cachedPhotos
            .filter { $0.position >= startPosition && $0.position <= endPosition }
            .sorted { $0.position < $1.position }
            .map { $0.photo }
    }
    
    func setLastUpdateTime(_ date: Date) {
        lastUpdateTime = date
    }
}
