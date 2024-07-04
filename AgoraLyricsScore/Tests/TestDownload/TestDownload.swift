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
    let expNormalXMLLocal = XCTestExpectation(description: "test TestDownload expNormalXML Local")
    let expNormalLRCSucess = XCTestExpectation(description: "test TestDownload NormalLRCSucess")
    let expNormalLRCProgress = XCTestExpectation(description: "test TestDownload expNormalLRCProgress")
    let expNormalLRCLocal = XCTestExpectation(description: "test TestDownload expNormalLRCLocal")
    let expUrlRepeatFail = XCTestExpectation(description: "test TestDownload UrlRepeatFail")
    let expSame1 = XCTestExpectation(description: "test TestDownload expSame1")
    let expSame2 = XCTestExpectation(description: "test TestDownload expSame2")
    
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
        
        currentTestingCaseNum = 1
        let _ = lyricsFileDownloader.download(urlString: urlString)
        wait(for: [expNormalXMLLocal], timeout: 3)
    }
    
    func testNormalLRCSucess() throws {
        currentTestingCaseNum = 10
        Downloader.requestTimeoutInterval = 9
        lyricsFileDownloader = LyricsFileDownloader()
        lyricsFileDownloader.delegate = self
        lyricsFileDownloader.cleanAll()
        
        let urlString = urlStrings.last!
        let _ = lyricsFileDownloader.download(urlString: urlString)
        wait(for: [expNormalLRCSucess, expNormalLRCProgress], timeout: 10)
        
        /// test local
        currentTestingCaseNum = 11
        let _ = lyricsFileDownloader.download(urlString: urlString)
        wait(for: [expNormalLRCLocal], timeout: 2)
    }
    
    func testUrlRepeatFail() throws {
        currentTestingCaseNum = 20
        Downloader.requestTimeoutInterval = 8
        lyricsFileDownloader = LyricsFileDownloader()
        lyricsFileDownloader.delegate = self
        lyricsFileDownloader.cleanAll()
        
        let urlString = urlStrings.first!
        let _ = lyricsFileDownloader.download(urlString: urlString)
        let _ = lyricsFileDownloader.download(urlString: urlString)
        wait(for: [expUrlRepeatFail], timeout: 10)
    }
    
    let sempSame = DispatchSemaphore(value: 0)
    var isTestSamePart1Success = false
    func testSame() { /** 测试相同的的url下载 **/
        currentTestingCaseNum = 30
        Downloader.requestTimeoutInterval = 5
        lyricsFileDownloader = LyricsFileDownloader()
        lyricsFileDownloader.delegate = self
        lyricsFileDownloader.cleanAll()
        
        let urlString = urlStrings.first!
        let _ = lyricsFileDownloader.download(urlString: urlString)
        wait(for: [expSame1], timeout: 6)
        
        sempSame.wait()
        lyricsFileDownloader.cleanAll()
        let _ = lyricsFileDownloader.download(urlString: urlString)
        wait(for: [expSame2], timeout: 6)
    }
    
    func onLyricsFileDownloadProgress(requestId: Int, progress: Float) {
        if currentTestingCaseNum == 0 {
            expNormalXMLProgress.fulfill()
        }
        if currentTestingCaseNum == 10 {
            expNormalLRCProgress.fulfill()
        }
    }
    
    func onLyricsFileDownloadCompleted(requestId: Int,
                                       fileData: Data?,
                                       error: DownloadError?) {
        if currentTestingCaseNum == 0, fileData != nil {
            XCTAssertEqual(fileData!.count, 42964)
            expNormalXMLSucess.fulfill()
        }
        if currentTestingCaseNum == 1, fileData != nil {
            expNormalXMLLocal.fulfill()
        }
        if currentTestingCaseNum == 10, fileData != nil {
            let fileName = FileCache().findFiles(inDirectory: .cacheFolderPath()).first?.path.fileName
            XCTAssertEqual(fileName, "10.lrc")
            XCTAssertEqual(fileData!.count, 2304)
            expNormalLRCSucess.fulfill()
        }
        if currentTestingCaseNum == 11, fileData != nil {
            let fileName = FileCache().findFiles(inDirectory: .cacheFolderPath()).first?.path.fileName
            XCTAssertEqual(fileName, "10.lrc")
            XCTAssertEqual(fileData!.count, 2304)
            expNormalLRCLocal.fulfill()
        }
        if currentTestingCaseNum == 20, error != nil, error!.domainType == .repeatDownloading {
            expUrlRepeatFail.fulfill()
        }
        if currentTestingCaseNum == 30 {
            if error == nil {
                if isTestSamePart1Success {
                    expSame2.fulfill()
                }
                else {
                    expSame1.fulfill()
                    sempSame.signal()
                    isTestSamePart1Success = true
                }
            }
        }
    }
}
