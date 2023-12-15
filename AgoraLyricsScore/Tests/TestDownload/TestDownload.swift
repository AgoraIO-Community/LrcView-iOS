//
//  TestDownload.swift
//  AgoraComponetLog-Unit-Tests
//
//  Created by ZYP on 2023/12/13.
//

import XCTest
@testable import AgoraLyricsScore

final class TestDownload: XCTestCase, LyricsFileDownloaderDelegate {
    var lyricsFileDownloader: LyricsFileDownloader!
    let expNormalXMLSucess = XCTestExpectation(description: "test TestDownload NormalXMLSucess")
    let expNormalXMLProgress = XCTestExpectation(description: "test TestDownload expNormalXMLProgress")
    let expNormalLRCSucess = XCTestExpectation(description: "test TestDownload NormalLRCSucess")
    let expNormalLRCProgress = XCTestExpectation(description: "test TestDownload expNormalLRCProgress")
    let expUrlRepeatFail = XCTestExpectation(description: "test TestDownload UrlRepeatFail")
    
    var currentTestingCaseNum = 0
    let urlStrings = ["https://fullapp.oss-cn-beijing.aliyuncs.com/lyricsMockDownload/1.zip",
                      "https://fullapp.oss-cn-beijing.aliyuncs.com/lyricsMockDownload/2.zip",
                      "https://fullapp.oss-cn-beijing.aliyuncs.com/lyricsMockDownload/3.zip",
                      "https://fullapp.oss-cn-beijing.aliyuncs.com/lyricsMockDownload/4.zip",
                      "https://fullapp.oss-cn-beijing.aliyuncs.com/lyricsMockDownload/5.zip",
                      "https://fullapp.oss-cn-beijing.aliyuncs.com/lyricsMockDownload/6.zip",
                      "https://fullapp.oss-cn-beijing.aliyuncs.com/lyricsMockDownload/7.zip",
                      "https://fullapp.oss-cn-beijing.aliyuncs.com/lyricsMockDownload/8.lrc",
                      "https://fullapp.oss-cn-beijing.aliyuncs.com/lyricsMockDownload/9.lrc",
                      "https://fullapp.oss-cn-beijing.aliyuncs.com/lyricsMockDownload/10.lrc"]
    
    
    override func setUpWithError() throws {
        Log.setLoggers(loggers: [ConsoleLogger()])
    }
    
    override func tearDownWithError() throws {
        Downloader.requestTimeoutInterval = 60
        lyricsFileDownloader = nil
    }
    
    func testNormalXMLSucess() throws {
        currentTestingCaseNum = 0
        Downloader.requestTimeoutInterval = 9
        lyricsFileDownloader = LyricsFileDownloader()
        lyricsFileDownloader.delegate = self
        lyricsFileDownloader.cleanAll()
        
        let urlString = urlStrings.first!
        let _ = lyricsFileDownloader.download(urlString: urlString)
        wait(for: [expNormalXMLSucess, expNormalXMLProgress], timeout: 10)
    }
    
    func testNormalLRCSucess() throws {
        currentTestingCaseNum = 1
        Downloader.requestTimeoutInterval = 9
        lyricsFileDownloader = LyricsFileDownloader()
        lyricsFileDownloader.delegate = self
        lyricsFileDownloader.cleanAll()
        
        let urlString = urlStrings.last!
        let _ = lyricsFileDownloader.download(urlString: urlString)
        wait(for: [expNormalLRCSucess, expNormalLRCProgress], timeout: 10)
    }
    
    func testUrlRepeatFail() throws {
        currentTestingCaseNum = 2
        Downloader.requestTimeoutInterval = 8
        lyricsFileDownloader = LyricsFileDownloader()
        lyricsFileDownloader.delegate = self
        lyricsFileDownloader.cleanAll()
        
        let urlString = urlStrings.first!
        let _ = lyricsFileDownloader.download(urlString: urlString)
        let _ = lyricsFileDownloader.download(urlString: urlString)
        wait(for: [expUrlRepeatFail], timeout: 10)
    }
    
    func onLyricsFileDownloadProgress(requestId: Int, progress: Float) {
        if currentTestingCaseNum == 0 {
            expNormalXMLProgress.fulfill()
        }
        if currentTestingCaseNum == 1 {
            expNormalLRCProgress.fulfill()
        }
    }
    
    func onLyricsFileDownloadCompleted(requestId: Int,
                                       fileData: Data?,
                                       error: DownloadError?) {
        if currentTestingCaseNum == 0, fileData != nil {
            expNormalXMLSucess.fulfill()
        }
        if currentTestingCaseNum == 1, fileData != nil {
            expNormalLRCSucess.fulfill()
        }
        if currentTestingCaseNum == 2, error != nil, error!.domainType == .repeatDownloading {
            expUrlRepeatFail.fulfill()
        }
    }
}
