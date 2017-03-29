

import Alamofire
import Foundation
import Locksmith

enum OAuthGrantType: String {
    case Code = "authorization_code"
    case ClientCredentials = "client_credentials"
    case PasswordCredentials = "password"
    case Refresh = "refresh_token"
}

/**
 `OAuthCredential` models the credentials returned from an OAuth server, storing the token type, access & refresh tokens, and whether the token is expired.
 
 OAuth credentials can be stored in the user's keychain, and retrieved on subsequent launches.
 */
class OAuthCredential: NSObject, NSCoding {
    
    /// Service name for storing the credential.
    private static let service = "OAuthCredentialService"
    
    override var description: String {
        get {
            return "<\(type(of: self)) accessToken:\"\(self.accessToken)\"\n tokenType:\"\(self.tokenType)\"\n refreshToken:\"\(self.refreshToken ?? "none")\"\n expiration:\"\(self.expiration ?? Date.distantFuture)\">"
        }
    }
    
    
    /// The OAuth access token.
    private(set) var accessToken: String
    
    /// The OAuth token type (e.g. "bearer").
    private(set) var tokenType: String
    
    /// The OAuth refresh token.
    var refreshToken: String?
    
    /// Boolean value indicating the expired status of the credential.
    var expired: Bool {
        return self.expiration?.compare(Date()) == .orderedAscending
    }
    
    /// The expiration date of the credential.
    var expiration: Date?
    
    /**
     Initializes an OAuth credential from a token string, with a specified type.
     
     - Parameter token: The OAuth token string.
     - Parameter type:  The OAuth token type.
     */
    required init(token: String, tokenType: String) {
        self.accessToken = token
        self.tokenType = tokenType
        super.init()
    }
    
    /**
     Creates an OAuth credential from the specified URL string, username, password and scope. 
     
     - Important: It is recommended that this function would be run on a background thread to stop UI from locking up..
     
     - Parameter url:                       The URL string used to create the request URL.
     - Parameter username:                  The username used for authentication.
     - Parameter password:                  The password used for authentication.
     - Parameter scope:                     The authorization scope.
     - Parameter clientID:                  Your client ID for the service.
     - Parameter clientSecret:              Your client secret for the service.
     - Parameter useBasicAuthentication:    Whether you want to send your client ID and client secret as parameters or headers. Defaults to true.
     
     - Throws: Error if request fails
     */
    convenience init(
        _ url: String,
        username: String,
        password: String,
        scope: String? = nil,
        clientID: String,
        clientSecret: String,
        useBasicAuthentication: Bool = true
        ) throws {
        var params = ["username": username, "password": password, "grant_type": OAuthGrantType.PasswordCredentials.rawValue]
        if scope != nil {
            params["scope"] = scope!
        }
        try self.init(url, parameters: params as [String : AnyObject], clientID: clientID, clientSecret: clientSecret, useBasicAuthentication: useBasicAuthentication)
    }
    
    /**
     Refreshes the OAuth token for the specified URL string, username, password and scope. 
     
     - Important: It is recommended that this function would be run on a background thread to stop UI from locking up..
     
     - Parameter url:                       The URL string used to create the request URL.
     - Parameter refreshToken:              The refresh token returned from the authorization code exchange.
     - Parameter clientID:                  Your client ID for the service.
     - Parameter clientSecret:              Your client secret for the service.
     - Parameter useBasicAuthentication:    Whether you want to send your client ID and client secret as parameters or headers. Defaults to true.
     
     - Throws: Error if request fails.
     */
    convenience init(
        _ url: String,
        refreshToken: String,
        clientID: String,
        clientSecret: String,
        useBasicAuthentication: Bool = true
        ) throws {
        let params = ["refresh_token": refreshToken, "grant_type": OAuthGrantType.Refresh.rawValue]
        try self.init(url, parameters: params as [String : AnyObject], clientID: clientID, clientSecret: clientSecret, useBasicAuthentication: useBasicAuthentication)
    }
    
    /**
     Creates an OAuth credential from the specified URL string, code. 
     
     - Important: It is recommended that this function would be run on a background thread to stop UI from locking up..
     
     - Parameter url:                       The URL string used to create the request URL.
     - Parameter code:                      The authorization code.
     - Parameter redirectURI:               The URI to redirect to after successful authentication.
     - Parameter clientID:                  Your client ID for the service.
     - Parameter clientSecret:              Your client secret for the service.
     - Parameter useBasicAuthentication:    Whether you want to send your client ID and client secret as parameters or headers. Defaults to true.
     
     - Throws: Error if request fails
     */
    convenience init(
        _ url: String,
        code: String,
        redirectURI: String,
        clientID: String,
        clientSecret: String,
        useBasicAuthentication: Bool = true
        ) throws {
        let params = ["grant_type": OAuthGrantType.Code.rawValue, "code": code, "redirect_uri": redirectURI]
        try self.init(url, parameters: params as [String : AnyObject], clientID: clientID, clientSecret: clientSecret, useBasicAuthentication: useBasicAuthentication)
    }
    
    /**
     Creates an OAuth credential from the specified parameters.
     
     - Important: It is recommended that this function would be run on a background thread to stop UI from locking up.
     
     - Parameter url:                       The URL string used to create the request URL.
     - Parameter parameters:                The parameters to be encoded and set in the request HTTP body.
     - Parameter clientID:                  Your client ID for the service.
     - Parameter clientSecret:              Your client secret for the service.
     - Parameter useBasicAuthentication:    Whether you want to send your client ID and client secret as parameters or headers. Defaults to true.
     
     - Throws: Error if request fails
     */
    init(
        _ url: String,
        parameters: [String: Any],
        clientID: String,
        clientSecret: String,
        useBasicAuthentication: Bool = true
        ) throws {
        accessToken = ""; tokenType = "" // Initialize variables with blank values to keep compiler happy.
        super.init()
        if Thread.isMainThread { print("Consider moving this method to a background thread to prevent performance loss.") }
        var headers: [String: String]?
        var parameters = parameters
        if useBasicAuthentication {
            headers = ["Authorization": "Basic \("\(clientID):\(clientSecret)".data(using: .utf8)!.base64EncodedString())"]
        } else {
            parameters["client_id"] = clientID
            parameters["client_secret"] = clientSecret
        }
        let semaphore = DispatchSemaphore(value: 0)
        var error: NSError?
        let queue = DispatchQueue(label: "com.popcorntimetv.popcornkit.response.queue", attributes: DispatchQueue.Attributes.concurrent)
        Alamofire.request(url, method: .post, parameters: parameters, headers: headers).validate().responseJSON(queue: queue, options: .allowFragments, completionHandler: { response in
            guard let responseObject = response.result.value as? [String: Any] else {
                error = response.result.error as NSError?
                DispatchQueue.main.async(execute: { semaphore.signal() })
                return
            }
            let refreshToken = responseObject["refresh_token"] as? String ?? parameters["refresh_token"] as? String
            self.accessToken = responseObject["access_token"] as! String
            self.tokenType = responseObject["token_type"] as! String
            if refreshToken != nil // refreshToken is optional in the OAuth2 spec.
            {
                self.refreshToken = refreshToken!
            }
            
            // Expiration is optional, but recommended in the OAuth2 spec. It not provide, assume distantFuture == never expires.
            var expireDate = Date.distantFuture
            if let expiresIn = responseObject["expires_in"] as? Int {
                expireDate = Date(timeIntervalSinceNow: Double(expiresIn))
            }
            self.expiration = expireDate
            
            DispatchQueue.main.async(execute: { semaphore.signal() })
        })
        semaphore.wait()
        if error != nil { throw error!}
    }
    
    /**
     Sets the credential refresh token, with a specified expiration.
     
     - Parameter refreshToken:  The OAuth refresh token.
     - Parameter expiration:    The expiration of the access token.
     */
    func setRefreshToken(_ refreshToken: String, expiration: Date) {
        self.refreshToken = refreshToken
        self.expiration = expiration
    }
    
    /**
     Stores the specified OAuth credential for a given web service identifier in the Keychain.
     with the default Keychain Accessibilty of kSecAttrAccessibleWhenUnlocked.
     
     - Parameter credential:            The OAuth credential to be stored.
     - Parameter identifier:            The service identifier associated with the specified token.
     - Parameter securityAccessibility: The Keychain security accessibility to store the credential with default Keychain Accessibilty of kSecAttrAccessibleWhenUnlocked.
     
     - Throws: Error if storing credential fails.
     */
    func store(
        withIdentifier identifier: String,
        accessibility: AnyObject = kSecAttrAccessibleWhenUnlocked
        ) throws {
        return try Locksmith.updateData(data: ["credential": NSKeyedArchiver.archivedData(withRootObject: self)], forUserAccount: identifier, inService: OAuthCredential.service)
    }
    
    /**
     Retrieves the OAuth credential stored with the specified service identifier from the Keychain.
     
     - Parameter identifier: The service identifier associated with the specified credential.
     
     - Returns: The OAuthCredential if it existed, `nil` otherwise.
     */
    init?(identifier: String) {
        
        guard let result = Locksmith.loadDataForUserAccount(userAccount: identifier, inService: OAuthCredential.service)?["credential"] as? Data, let credential = NSKeyedUnarchiver.unarchiveObject(with: result) as? OAuthCredential else { return nil }
        
        self.accessToken = credential.accessToken
        self.expiration = credential.expiration
        self.refreshToken = credential.refreshToken
        self.tokenType = credential.tokenType
        super.init()
    }
    
    /**
     Deletes the OAuth credential stored with the specified service identifier from the Keychain.
     
     - Parameter identifier: The service identifier associated with the specified credential.
     
      - Throws: Error if deleting the credential fails.
     */
    class func delete(withIdentifier identifier: String) throws {
        return try Locksmith.deleteDataForUserAccount(userAccount: identifier, inService: service)
    }
    
    // MARK: - NSCoding
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(accessToken, forKey: "accessToken")
        aCoder.encode(tokenType, forKey: "tokenType")
        aCoder.encode(refreshToken, forKey: "refreshToken")
        aCoder.encode(expiration, forKey: "expiration")
    }
    
    required init(coder aDecoder: NSCoder) {
        accessToken = aDecoder.decodeObject(forKey: "accessToken") as! String
        tokenType = aDecoder.decodeObject(forKey: "tokenType") as! String
        refreshToken = aDecoder.decodeObject(forKey: "refreshToken") as? String
        expiration = aDecoder.decodeObject(forKey: "expiration") as? Date
        super.init()
    }
}
