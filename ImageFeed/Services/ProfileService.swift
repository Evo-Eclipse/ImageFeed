import Foundation

final class ProfileService {
    static let shared = ProfileService()
    private init() {}
    
    // MARK: - Private Properties
    
    private let urlSession = URLSession.shared
    private var task: URLSessionTask?
    private var lastToken: String?
    
    // MARK: - Structures
    
    struct ProfileResult: Decodable {
        let username: String
        let firstName: String?
        let lastName: String?
        let bio: String?
        
        enum CodingKeys: String, CodingKey {
            case username
            case firstName = "first_name"
            case lastName = "last_name"
            case bio
        }
    }
    
    // MARK: - Public Methods
    
    func fetchProfile(_ token: String, completion: @escaping (Result<Profile, Error>) -> Void) {
        assert(Thread.isMainThread)
        
        guard lastToken != token else {
            completion(.failure(NetworkError.invalidRequest))
            return
        }
        
        task?.cancel()
        lastToken = token
        
        guard let request = makeProfileRequest(token: token) else {
            print("[ProfileImageService.fetchProfileImageURL] Error: Failed to create profile image request")
            completion(.failure(NetworkError.invalidRequest))
            lastToken = nil
            return
        }
        
        let task = urlSession.data(for: request) { [weak self] result in
            guard let self = self else { return }
            
            defer {
                self.task = nil
                self.lastToken = nil
            }
            
            switch result {
            case .success(let data):
                do {
                    let decoder = JSONDecoder()
                    let profileResult = try decoder.decode(ProfileResult.self, from: data)
                    
                    let profile = self.createProfile(from: profileResult)
                    completion(.success(profile))
                } catch {
                    print("[ProfileImageService.fetchProfileImageURL] Error: Failed to decode profile image response - \(error)")
                    completion(.failure(NetworkError.decodingError(error)))
                }
                
            case .failure(let error):
                print("[ProfileImageService.fetchProfileImageURL] Error: Network error while fetching profile image - \(error)")
                completion(.failure(error))
            }
        }
        
        self.task = task
        task.resume()
    }
    
    // MARK: - Network Methods
    
    private func makeProfileRequest(token: String) -> URLRequest? {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "api.unsplash.com"
        components.path = "/me"
        
        guard let url = components.url else {
            return nil
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        return request
    }
    
    // MARK: - Private Methods
    
    private func createProfile(from profileResult: ProfileResult) -> Profile {
        let firstName = profileResult.firstName ?? ""
        let lastName = profileResult.lastName ?? ""
        let name = "\(firstName) \(lastName)".trimmingCharacters(in: .whitespacesAndNewlines)
        let loginName = "@\(profileResult.username)"
        
        return Profile(
            username: profileResult.username,
            name: name,
            loginName: loginName,
            bio: profileResult.bio
        )
    }
}
