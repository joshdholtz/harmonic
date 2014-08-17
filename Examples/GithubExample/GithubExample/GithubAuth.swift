//
//  GithubAuth.swift
//  GithubExample
//
//  Created by Josh Holtz on 8/17/14.
//  Copyright (c) 2014 Josh Holtz. All rights reserved.
//

import Foundation
import UIKit

private let _GithubAuthedSession = GithubAuth()

class GithubAuth: HarmonicModel {

    struct Config {
        static var redirectURI: String?
        static var clientId: String?
        static var clientSecret: String?
        static var state = "1233456"
    }
    
    class var session: GithubAuth {
        return _GithubAuthedSession
    }
    
    typealias authCallbackClosure = (NSError?) -> ()
    var authCallback: authCallbackClosure?
    
    var accessToken: String?
    var scope: String?
    var tokenType: String?
    
    override func parse(json : JSONObject) {
        super.parse(json)
        self.accessToken = json["access_token"] >>> ToString
        self.scope = json["scope"] >>> ToString
        self.tokenType = json["token_type"] >>> ToString
    }
    
    func isLoggedIn() -> Bool {
        return self.accessToken != nil
    }
    
    func login() {
        UIApplication.sharedApplication().openURL(NSURL.URLWithString("https://github.com/login/oauth/authorize?client_id=\(GithubAuth.Config.clientId!)&state=\(GithubAuth.Config.state)&redirect_uri=\(GithubAuth.Config.redirectURI!)"))
    }
    
    func handleOpenURL(url: NSURL) -> Bool {
        if (!url.absoluteString.hasPrefix("harmonicexample://githubcallback")) { return false }
        
        var queryParams = url.absoluteString.stringByReplacingOccurrencesOfString("\(GithubAuth.Config.redirectURI!)?", withString: "")

        for group in queryParams.componentsSeparatedByString("&") {
            var pieces = group.componentsSeparatedByString("=")
            if (pieces[0] == "code") {
                var code = pieces[1]
                
                var postUrl = "https://github.com/login/oauth/access_token"
                var url = NSURL(string: postUrl)
                var request = NSMutableURLRequest(URL: url)
                request.HTTPMethod = "POST"
                
                var dataString = "client_id=\(GithubAuth.Config.clientId!)&client_secret=\(GithubAuth.Config.clientSecret!)&code=\(code)"
                
                let data = (dataString as NSString).dataUsingEncoding(NSUTF8StringEncoding)
                var requestBodyData: NSData = data
                request.HTTPBody = requestBodyData
                request.setValue("application/json", forHTTPHeaderField: "Accept")

                self.request(request) { (request, response, model, error) -> Void in
                    if (self.authCallback != nil) { self.authCallback!(error) }
                }
                
            }
        }
        
        return true
    }
    
}
