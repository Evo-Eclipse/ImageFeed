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
            print("[ProfileService.fetchProfile] Error: Failed to create profile request")
            completion(.failure(NetworkError.invalidRequest))
            lastToken = nil
            return
        }
        
        let task = urlSession.objectTask(for: request) { [weak self] (result: Result<ProfileResult, Error>) in
            guard let self = self else { return }
            print("[ProfileService.fetchProfile] Network: Request completed")
            
            defer {
                self.task = nil
                self.lastToken = nil
            }
            
            switch result {
            case .success(let profileResult):
                let profile = self.createProfile(from: profileResult)
                completion(.success(profile))
                
            case .failure(let error):
                print("[ProfileService.fetchProfile]: Error - \(error.localizedDescription)")
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
    
    private func createProfile(from result: ProfileResult) -> Profile {
        let firstName = result.firstName ?? ""
        let lastName = result.lastName ?? ""
        let name = "\(firstName) \(lastName)".trimmingCharacters(in: .whitespacesAndNewlines)
        let loginName = "@\(result.username)"
        
        return Profile(
            username: result.username,
            name: name,
            loginName: loginName,
            bio: result.bio
        )
    }
}
