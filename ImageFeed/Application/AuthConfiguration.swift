import Foundation

/// Configuration for Unsplash API authorization.
///
/// To set up your application:
/// 1. Register at [Unsplash Developer portal](https://unsplash.com/developers)
/// 2. Create a new application and obtain API credentials
/// 3. Insert your Unsplash API credentials in place of the example values
/// 4. Add `AuthConfiguration.swift` to `.gitignore` or setup git hooks
///
/// - Important: Never commit `AuthConfiguration.swift` to version control as it contains sensitive information.
enum Constants {
    /// The client ID (Access Key) for your Unsplash application
    /// - Note: Replace with your actual Access Key from Unsplash Developer portal
    static let accessKey = "YOUR_UNSPLASH_ACCESS_KEY_HERE"
    
    /// The client secret (Secret Key) for your Unsplash application
    /// - Note: Replace with your actual Secret Key from Unsplash Developer portal
    static let secretKey = "YOUR_UNSPLASH_SECRET_KEY_HERE"
    
    /// The OAuth redirect URI for your application
    /// Default value suitable for OAuth authentication without custom scheme
    static let redirectURI = "urn:ietf:wg:oauth:2.0:oob"
    
    /// The OAuth scope defining requested permissions
    ///
    /// Current permissions include:
    /// - public: Access public information
    /// - read_user: Read user information
    /// - write_likes: Like/unlike photos
    static let accessScope = "public+read_user+write_likes"
    
    /// The base URL for the Unsplash API
    ///
    /// - Returns: URL object constructed with HTTPS scheme and api.unsplash.com host
    static var unsplashBaseURL: URL? {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "api.unsplash.com"
        return components.url
    }
    
    /// The authorization URL for the Unsplash OAuth
    ///
    /// - Returns: URL object constructed with HTTPS scheme, unsplash.com host and /oauth/authorize path
    static var unsplashAuthURL: URL? {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "unsplash.com"
        components.path = "/oauth/authorize"
        return components.url
    }
}

/// A configuration structure that encapsulates all necessary Unsplash API authorization parameters.
struct AuthConfiguration {
    /// The client ID used for API authentication
    let accessKey: String
    /// The client secret used for API authentication
    let secretKey: String
    /// The URI where the OAuth flow redirects after authorization
    let redirectURI: String
    /// The permissions requested during authorization
    let accessScope: String
    /// The base URL for all API requests
    let unsplashBaseURL: URL?
    /// The URL used to initiate OAuth authorization
    let unsplashAuthURL: URL?
    
    /// Creates a new configuration instance with the specified parameters.
    ///
    /// - Parameters:
    ///   - accessKey: The client ID for API authentication
    ///   - secretKey: The client secret for API authentication
    ///   - redirectURI: The OAuth redirect URI
    ///   - accessScope: The requested permissions scope
    ///   - unsplashBaseURL: The base URL for API requests
    ///   - unsplashAuthURL: The OAuth authorization URL
    init(
        accessKey: String,
        secretKey: String,
        redirectURI: String,
        accessScope: String,
        unsplashBaseURL: URL?,
        unsplashAuthURL: URL?
    ) {
        self.accessKey = accessKey
        self.secretKey = secretKey
        self.redirectURI = redirectURI
        self.accessScope = accessScope
        self.unsplashBaseURL = unsplashBaseURL
        self.unsplashAuthURL = unsplashAuthURL
    }
    
    /// The standard configuration using values from Constants.
    static var standard: AuthConfiguration {
        AuthConfiguration(
            accessKey: Constants.accessKey,
            secretKey: Constants.secretKey,
            redirectURI: Constants.redirectURI,
            accessScope: Constants.accessScope,
            unsplashBaseURL: Constants.unsplashBaseURL,
            unsplashAuthURL: Constants.unsplashAuthURL
        )
    }
}
