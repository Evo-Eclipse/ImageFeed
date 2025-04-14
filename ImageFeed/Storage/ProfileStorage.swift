import Foundation

final class ProfileStorage {
    static let shared = ProfileStorage()
    
    private let profileKey = "ProfileStorageKey"
    private let timestampKey = "ProfileTimestampKey"
    private var cachedProfile: Profile?
    
    private init() {}
    
    var profile: Profile? {
        get {
            if let cachedProfile = cachedProfile {
                return cachedProfile
            }
            
            guard let data = UserDefaults.standard.data(forKey: profileKey) else {
                return nil
            }
            
            let decodedProfile = try? JSONDecoder().decode(Profile.self, from: data)
            cachedProfile = decodedProfile
            return decodedProfile
        }
        set {
            cachedProfile = newValue
            
            if let newValue = newValue,
               let encodedData = try? JSONEncoder().encode(newValue) {
                UserDefaults.standard.set(encodedData, forKey: profileKey)
                timestamp = Date()
            } else {
                UserDefaults.standard.removeObject(forKey: profileKey)
            }
        }
    }
    
    var timestamp: Date? {
        get {
            return UserDefaults.standard.object(forKey: timestampKey) as? Date
        }
        set {
            UserDefaults.standard.set(newValue, forKey: timestampKey)
        }
    }
    
    var isExpired: Bool {
        guard let timestamp = timestamp else { return true }
        return Date().timeIntervalSince(timestamp) > 900 // 15 Minutes
    }
}
