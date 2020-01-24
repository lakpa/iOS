//
//  WebCacheManagerTests.swift
//  UnitTests
//
//  Created by Chris Brind on 15/01/2020.
//  Copyright © 2020 DuckDuckGo. All rights reserved.
//

import XCTest
@testable import Core

class WebCacheManagerTests: XCTestCase {

    func testWhenClearedThenCookiesWithParentDomainsAreRetained() {

        let logins = MockPreservedLogins(domains: [
            "www.example.com"
        ])

        let dataStore = MockDataStore()
        dataStore.cookieStore = MockHTTPCookieStore(cookies: [
            .make(domain: ".example.com"),
            .make(domain: "facebook.com")
        ])

        let cookieStorage = MockCookieStorage()

        let expect = expectation(description: #function)
        WebCacheManager.shared.clear(dataStore: dataStore, appCookieStorage: cookieStorage, logins: logins) {
            expect.fulfill()
        }
        wait(for: [expect], timeout: 5.0)

        XCTAssertEqual(cookieStorage.cookies.count, 1)
        XCTAssertEqual(cookieStorage.cookies[0].domain, ".example.com")
        
    }

    func testWhenClearedThenDDGCookiesAreRetained() {
        let logins = MockPreservedLogins(domains: [
            "www.example.com"
        ])

        let dataStore = MockDataStore()
        dataStore.cookieStore = MockHTTPCookieStore(cookies: [
            .make(domain: "duckduckgo.com")
        ])

        let cookieStorage = MockCookieStorage()
        
        let expect = expectation(description: #function)
        WebCacheManager.shared.clear(dataStore: dataStore, appCookieStorage: cookieStorage, logins: logins) {
            expect.fulfill()
        }
        wait(for: [expect], timeout: 5.0)
        
        XCTAssertEqual(cookieStorage.cookies.count, 1)
        XCTAssertEqual(cookieStorage.cookies[0].domain, "duckduckgo.com")
    }
    
    func testWhenClearedThenCookiesForloginsAreRetained() {
        let logins = MockPreservedLogins(domains: [
            "www.example.com"
        ])

        let dataStore = MockDataStore()
        dataStore.cookieStore = MockHTTPCookieStore(cookies: [
            .make(domain: "www.example.com"),
            .make(domain: "facebook.com")
        ])

        let cookieStorage = MockCookieStorage()
        
        let expect = expectation(description: #function)
        WebCacheManager.shared.clear(dataStore: dataStore, appCookieStorage: cookieStorage, logins: logins) {
            expect.fulfill()
        }
        wait(for: [expect], timeout: 5.0)
        
        XCTAssertEqual(cookieStorage.cookies.count, 1)
        XCTAssertEqual(cookieStorage.cookies[0].domain, "www.example.com")

    }
    
    func testWhenConsumeIsCalledThenCompletionIsCalled() {
        let cookieStorage = MockCookieStorage()
        cookieStorage.setCookie(HTTPCookie.make())
        
        let httpCookieStore = MockHTTPCookieStore()
        
        let expect = expectation(description: #function)
        WebCacheManager.shared.consumeCookies(cookieStorage: cookieStorage, httpCookieStore: httpCookieStore) {
            expect.fulfill()
        }
        wait(for: [expect], timeout: 5.0)
        
        XCTAssertTrue(cookieStorage.cookies.isEmpty)
        XCTAssertEqual(httpCookieStore.cookies.count, 1)
    }
    
    func testWhenClearIsCalledThenCompletionIsCalled() {
        let dataStore = MockDataStore()
        let logins = MockPreservedLogins(domains: [])
        
        let expect = expectation(description: #function)
        WebCacheManager.shared.clear(dataStore: dataStore, logins: logins) {
            expect.fulfill()
        }
        wait(for: [expect], timeout: 5.0)
        
        XCTAssertEqual(dataStore.removeAllDataCalledCount, 1)
    }
            
    // MARK: Mocks
    
    class MockDataStore: WebCacheManagerDataStore {
        
        var removeAllDataCalledCount = 0
        
        var cookieStore: WebCacheManagerCookieStore?
        
        func removeAllData(completion: @escaping () -> Void) {
            removeAllDataCalledCount += 1
            completion()
        }
        
    }
    
    class MockPreservedLogins: PreserveLogins {
        
        let domains: [String]
        
        override var allowedDomains: [String] {
            return domains
        }
        
        init(domains: [String]) {
            self.domains = domains
        }
        
    }
    
    class MockHTTPCookieStore: WebCacheManagerCookieStore {
        
        var cookies: [HTTPCookie]
        
        init(cookies: [HTTPCookie] = []) {
            self.cookies = cookies
        }
        
        func getAllCookies(_ completionHandler: @escaping ([HTTPCookie]) -> Void) {
            completionHandler(cookies)
        }
        
        func setCookie(_ cookie: HTTPCookie, completionHandler: (() -> Void)?) {
            cookies.append(cookie)
            completionHandler?()
        }
                
    }
    
    class MockCookieStorage: CookieStorage {
        
        convenience init() {
            let userDefaults = UserDefaults(suiteName: "test")!
            userDefaults.removePersistentDomain(forName: "test")
            self.init(userDefaults: userDefaults)
        }
        
    }

}
