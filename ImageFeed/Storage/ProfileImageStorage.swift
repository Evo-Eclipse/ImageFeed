import Foundation

final class ProfileImageStorage {
    static let shared = ProfileImageStorage()
    
    private let profileImageKey = "ProfileImageStorageKey"
    private let timestampKey = "ProfileImageTimestampKey"
    private var cachedProfileImage: ProfileImage?
    
    private init() {}
    
    var profileImage: ProfileImage? {
        get {
            if let cachedProfileImage = cachedProfileImage {
                return cachedProfileImage
            }
            
            guard let data = UserDefaults.standard.data(forKey: profileImageKey) else {
                return nil
            }
            
            let decodedProfileImage = try? JSONDecoder().decode(ProfileImage.self, from: data)
            cachedProfileImage = decodedProfileImage
            return decodedProfileImage
        }
        set {
            cachedProfileImage = newValue
            
            if let newValue = newValue,
               let encodedData = try? JSONEncoder().encode(newValue) {
                UserDefaults.standard.set(encodedData, forKey: profileImageKey)
                timestamp = Date()
            } else {
                UserDefaults.standard.removeObject(forKey: profileImageKey)
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
