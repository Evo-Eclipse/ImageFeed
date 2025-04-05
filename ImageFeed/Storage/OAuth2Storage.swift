import Foundation

final class OAuth2Storage {
    static let shared = OAuth2Storage()
    
    private let tokenKey = "OAuth2TokenStorage"
    private var cachedToken: String?
    
    private init() {}
    
    var token: String? {
        get {
            if let cachedToken = cachedToken {
                return cachedToken
            }
            
            let storedToken = UserDefaults.standard.string(forKey: tokenKey)
            cachedToken = storedToken
            return storedToken
        }
        set {
            cachedToken = newValue
            UserDefaults.standard.set(newValue, forKey: tokenKey)
        }
    }
}
