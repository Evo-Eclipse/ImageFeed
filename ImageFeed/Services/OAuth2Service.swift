import Foundation

final class OAuth2Service {
    static let shared = OAuth2Service()
    private init() {}
    
    // MARK: - Private Properties
    
    private let urlSession = URLSession.shared
    private var task: URLSessionTask?
    private var lastCode: String?
    
    // MARK: - Structures
    
    struct OAuthResult: Decodable {
        let accessToken: String
        let tokenType: String
        let scope: String
        let createdAt: Int
        
        enum CodingKeys: String, CodingKey {
            case accessToken = "access_token"
            case tokenType = "token_type"
            case scope
            case createdAt = "created_at"
        }
    }
    
    // MARK: - Public Methods
    
    func fetchOAuthToken(_ code: String, completion: @escaping (Result<String, Error>) -> Void) {
        assert(Thread.isMainThread)
        
        guard lastCode != code else {
            completion(.failure(NetworkError.invalidRequest))
            return
        }
        
        task?.cancel()
        lastCode = code
        
        guard let request = makeOAuthRequest(code: code) else {
            print("[OAuth2Service.fetchOAuthToken] Error: Failed to create OAuth2 token request")
            completion(.failure(NetworkError.invalidRequest))
            lastCode = nil
            return
        }
        
        let task = urlSession.objectTask(for: request) { [weak self] (result: Result<OAuthResult, Error>) in
            guard let self = self else { return }
            print("[OAuth2Service.fetchOAuthToken] Network: Request completed")
            
            defer {
                self.task = nil
                self.lastCode = nil
            }
            
            switch result {
            case .success(let oauthResult):
                completion(.success(oauthResult.accessToken))
                
            case .failure(let error):
                print("[OAuth2Service.fetchOAuthToken]: Error - \(error.localizedDescription)")
                completion(.failure(error))
            }
        }
        
        self.task = task
        task.resume()
    }
    
    // MARK: - Network Methods
    
    private func makeOAuthRequest(code: String) -> URLRequest? {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "unsplash.com"
        components.path = "/oauth/token"
        
        components.queryItems = [
            URLQueryItem(name: "client_id", value: Constants.accessKey),
            URLQueryItem(name: "client_secret", value: Constants.secretKey),
            URLQueryItem(name: "redirect_uri", value: Constants.redirectURI),
            URLQueryItem(name: "code", value: code),
            URLQueryItem(name: "grant_type", value: "authorization_code")
        ]
        
        guard let url = components.url else {
            return nil
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        return request
    }
}
