import Foundation

final class AuthHelper: AuthHelperProtocol {
    
    // MARK: - Private Properties
    
    private let configuration: AuthConfiguration
    
    // MARK: - Initializers
    
    init(configuration: AuthConfiguration = .standard) {
        self.configuration = configuration
    }
    
    // MARK: - Public Methods
    
    func authRequest() -> URLRequest? {
        guard let authURL = configuration.unsplashAuthURL else { return nil }
        
        var components = URLComponents(url: authURL, resolvingAgainstBaseURL: true)
        components?.queryItems = [
            URLQueryItem(name: "client_id", value: configuration.accessKey),
            URLQueryItem(name: "redirect_uri", value: configuration.redirectURI),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "scope", value: configuration.accessScope)
        ]
        
        guard let url = components?.url else { return nil }
        return URLRequest(url: url)
    }
    
    func code(from url: URL) -> String? {
        guard let urlComponents = URLComponents(string: url.absoluteString),
              urlComponents.path == "/oauth/authorize/native",
              let queryItems = urlComponents.queryItems,
              let codeItem = queryItems.first(where: { $0.name == "code" })
        else { return nil }
        
        return codeItem.value
    }
}
