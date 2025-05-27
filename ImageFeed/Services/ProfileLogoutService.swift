import WebKit

final class ProfileLogoutService {
    static let shared = ProfileLogoutService()
    private init() {}
    
    // MARK: - Public Methods
    
    func logout() {
        assert(Thread.isMainThread)
        
        cleanStorages()
        cleanImages()
        cleanPhotoCache()
        cleanCookies()
        
        switchToSplashViewController()
    }
    
    // MARK: - Private Methods
    
    private func cleanStorages() {
        OAuth2Storage.shared.token = nil
        ProfileStorage.shared.profile = nil
        ProfileImageStorage.shared.profileImage = nil
    }
    
    private func cleanImages() {
        ImagesListService.shared.reset()
    }
    
    private func cleanPhotoCache() {
        PhotoCacheService.shared.clearCache()
    }
    
    private func cleanCookies() {
        HTTPCookieStorage.shared.removeCookies(since: Date.distantPast)
        
        WKWebsiteDataStore.default().fetchDataRecords(ofTypes: WKWebsiteDataStore.allWebsiteDataTypes()) { records in
            records.forEach { record in
                WKWebsiteDataStore.default().removeData(ofTypes: record.dataTypes, for: [record], completionHandler: {})
            }
        }
    }
    
    private func switchToSplashViewController() {
        guard let window = UIApplication.shared.windows.first else {
            assertionFailure("Invalid configuration, no main window found")
            return
        }
        
        let splashViewController = SplashViewController()
        
        window.rootViewController = splashViewController
        window.makeKeyAndVisible()
        
        UIView.transition(
            with: window,
            duration: 0.3,
            options: .transitionCrossDissolve,
            animations: nil,
            completion: nil
        )
    }
}
