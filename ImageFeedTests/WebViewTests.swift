import XCTest
@testable import ImageFeed

/// Tests for WebView functionality including presenter, view controller and auth helper
final class WebViewTests: XCTestCase {
    
    /// Tests that view controller calls presenter's viewDidLoad method
    /// - Verifies the connection between view controller and presenter
    func testViewControllerCallsViewDidLoad() {
        // Given
        let controller = WebViewViewController()
        let presenter = WebViewPresenterSpy()
        
        controller.presenter = presenter
        presenter.view = controller
        
        // When
        _ = controller.view // This will trigger viewDidLoad
        
        // Then
        XCTAssertTrue(presenter.viewDidLoadCalled)
    }
    
    /// Tests that presenter calls loadRequest on its view
    /// - Verifies the presenter properly interacts with the view
    func testPresenterCallsLoadRequest() {
        // Given
        let controller = WebViewViewControllerSpy()
        let authHelper = AuthHelper()
        let presenter = WebViewPresenter(authHelper: authHelper)
        
        controller.presenter = presenter
        presenter.view = controller
        
        // When
        presenter.viewDidLoad()
        
        // Then
        XCTAssertTrue(controller.loadRequestCalled)
    }
    
    /// Tests that progress indicator is visible when progress value is less than 1.0
    /// - Verifies correct progress visibility logic
    func testProgressVisibleWhenLessThenOne() {
        // Given
        let authHelper = AuthHelper()
        let presenter = WebViewPresenter(authHelper: authHelper)
        let progressValue: Float = 0.5
        
        // When
        let shouldHideProgress = presenter.shouldHideProgress(for: progressValue)
        
        // Then
        XCTAssertFalse(shouldHideProgress)
    }
    
    /// Tests that progress indicator is hidden when progress value is exactly 1.0
    /// - Verifies correct progress visibility logic
    func testProgressHiddenWhenOne() {
        // Given
        let authHelper = AuthHelper()
        let presenter = WebViewPresenter(authHelper: authHelper)
        let progressValue: Float = 1.0
        
        // When
        let shouldHideProgress = presenter.shouldHideProgress(for: progressValue)
        
        // Then
        XCTAssertTrue(shouldHideProgress)
    }
    
    /// Tests that AuthHelper correctly constructs the OAuth URL with all required parameters
    /// - Verifies authentication request formation
    func testAuthHelperAuthURL() {
        // Given
        let configuration = AuthConfiguration.standard
        let authHelper = AuthHelper(configuration: configuration)
        
        // When
        guard let request = authHelper.authRequest(),
              let url = request.url else {
            XCTFail("Auth request URL is nil")
            return
        }
        
        let urlString = url.absoluteString
        
        // Then
        XCTAssertTrue(urlString.contains(configuration.unsplashAuthURL?.absoluteString ?? ""))
        XCTAssertTrue(urlString.contains(configuration.accessKey))
        XCTAssertTrue(urlString.contains(configuration.redirectURI))
        XCTAssertTrue(urlString.contains("response_type=code"))
        XCTAssertTrue(urlString.contains(configuration.accessScope))
    }
    
    /// Tests extraction of authorization code from callback URL
    /// - Verifies the correct parsing of OAuth callback
    func testCodeFromURL() {
        // Given
        let configuration = AuthConfiguration.standard
        let authHelper = AuthHelper(configuration: configuration)
        
        var components = URLComponents()
        components.scheme = "https"
        components.host = "unsplash.com"
        components.path = "/oauth/authorize/native"
        components.queryItems = [URLQueryItem(name: "code", value: "test code")]
        
        guard let url = components.url else {
            XCTFail("Failed to create URL from components")
            return
        }
        
        // When
        let code = authHelper.code(from: url)
        
        // Then
        XCTAssertEqual(code, "test code")
    }
}

/// Test spy for WebViewPresenter to verify interactions
final class WebViewPresenterSpy: WebViewPresenterProtocol {
    var viewDidLoadCalled: Bool = false
    var view: WebViewViewControllerProtocol?
    
    func viewDidLoad() {
        viewDidLoadCalled = true
    }
    
    func didUpdateProgressValue(_ newValue: Double) {
    
    }
    
    func code(from url: URL) -> String? {
        return nil
    }
}

/// Test spy for WebViewController to verify interactions
final class WebViewViewControllerSpy: WebViewViewControllerProtocol {
    var loadRequestCalled: Bool = false
    var presenter: WebViewPresenterProtocol?
    
    func load(request: URLRequest) {
        loadRequestCalled = true
    }
    
    func setProgressValue(_ newValue: Float) {
        
    }
    
    func setProgressHidden(_ isHidden: Bool) {
        
    }
}
