import Foundation
import SwiftKeychainWrapper

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
            
            let storedToken = KeychainWrapper.standard.string(forKey: tokenKey)
            cachedToken = storedToken
            return storedToken
        }
        set {
            cachedToken = newValue
            
            if let newValue {
                KeychainWrapper.standard.set(newValue, forKey: tokenKey)
            } else {
                KeychainWrapper.standard.removeObject(forKey: tokenKey)
            }
        }
    }
}
