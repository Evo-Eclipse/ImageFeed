import Foundation

enum AuthServiceError: Error {
    case invalidRequest
}

final class OAuth2Service {
    static let shared = OAuth2Service()
    
    private let urlSession = URLSession.shared
    private var task: URLSessionTask?
    private var lastCode: String?
    
    private init() {}
    
    private func makeOAuthTokenRequest(code: String) -> URLRequest? {
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

extension OAuth2Service {
    func fetchOAuthToken(
        _ code: String,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        assert(Thread.isMainThread)
        
        guard lastCode != code else {
            completion(.failure(AuthServiceError.invalidRequest))
            return
        }
        
        task?.cancel()
        
        lastCode = code
        
        guard let request = makeOAuthTokenRequest(code: code) else {
            print("OAuth2Service :: Ошибка создания запроса на получение токена")
            completion(.failure(AuthServiceError.invalidRequest))
            lastCode = nil
            return
        }
        
        let newTask = urlSession.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                defer {
                    self.task = nil
                    self.lastCode = nil
                }
                
                if let error = error {
                    print("OAuth2Service :: Сетевая ошибка при получении токена: \(error)")
                    completion(.failure(error))
                    return
                }
                
                guard let data = data else {
                    print("OAuth2Service :: Отсутствуют данные в ответе")
                    completion(.failure(NetworkError.invalidRequest))
                    return
                }
                
                do {
                    let decoder = JSONDecoder()
                    let responseBody = try decoder.decode(OAuthTokenResponseBody.self, from: data)
                    
                    let token = responseBody.accessToken
                    OAuth2TokenStorage.shared.token = token
                    completion(.success(token))
                } catch {
                    print("OAuth2Service :: Ошибка декодирования OAuthTokenResponseBody: \(error)")
                    completion(.failure(NetworkError.decodingError(error)))
                }
            }
        }
        
        self.task = newTask
        newTask.resume()
    }
}

extension NetworkError {
    static let invalidRequest = NetworkError.httpStatusCode(-1)
    
    static func decodingError(_ error: Error) -> NetworkError {
        return .httpStatusCode(-2)
    }
}
