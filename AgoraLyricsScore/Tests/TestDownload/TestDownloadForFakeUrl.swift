//
//  TestDownloadForFakeUrl.swift
//  AgoraComponetLog-Unit-Tests
//
//  Created by ZYP on 2023/12/14.
//

import XCTest
@testable import AgoraLyricsScore

final class TestDownloadForFakeUrl: XCTestCase, LyricsFileDownloaderDelegate {
    var lyricsFileDownloader: LyricsFileDownloader!
    var currentTestingCaseNum = 0
    let urlStrings = ["https://127.0.0.1/lyricsMockDownload/1.zip",
                      "https://agora.fake.domain.com/lyricsMockDownload/1.zip",
                      "https://fullapp.oss-cn-beijing.aliyuncs.com/lyricsMockDownload/10000.zip",
                      "https://8.141.208.82/lyricsMockDownload/1.zip",]

    override func setUpWithError() throws {
        Log.setLoggers(loggers: [ConsoleLogger()])
    }
    
    override func tearDownWithError() throws {
        lyricsFileDownloader = nil
    }
    
    func testFakeUrlString() {
        lyricsFileDownloader = LyricsFileDownloader()
        XCTAssertEqual(lyricsFileDownloader.download(urlString: ""), -1)
        XCTAssertEqual(lyricsFileDownloader.download(urlString: "yhhp://baidu.com"), -1)
    }

    let expFakeUrlFail = XCTestExpectation(description: "test TestDownload FakeUrlFail")
    func testFakeUrlFail() throws {
        currentTestingCaseNum = 0
        Downloader.requestTimeoutInterval = 4
        lyricsFileDownloader = LyricsFileDownloader()
        lyricsFileDownloader.delegate = self
        
        let urlString = urlStrings[0]
        let _ = lyricsFileDownloader.download(urlString: urlString)
        wait(for: [expFakeUrlFail], timeout: 6)
    }
    
    let expFakeUrlFail2 = XCTestExpectation(description: "test TestDownload FakeUrlFail2")
    func testFakeUrlFail2() throws {
        currentTestingCaseNum = 1
        Downloader.requestTimeoutInterval = 4
        lyricsFileDownloader = LyricsFileDownloader()
        lyricsFileDownloader.delegate = self
        
        let urlString = urlStrings[1]
        let _ = lyricsFileDownloader.download(urlString: urlString)
        wait(for: [expFakeUrlFail2], timeout: 6)
    }
    
    let expFakeUrlFail3 = XCTestExpectation(description: "test TestDownload FakeUrlFail3")
    func testFakeUrlFail3() throws {
        currentTestingCaseNum = 2
        Downloader.requestTimeoutInterval = 4
        lyricsFileDownloader = LyricsFileDownloader()
        lyricsFileDownloader.delegate = self
        
        let urlString = urlStrings[2]
        let _ = lyricsFileDownloader.download(urlString: urlString)
        wait(for: [expFakeUrlFail3], timeout: 6)
    }
    
    let expFakeUrlFail4 = XCTestExpectation(description: "test TestDownload FakeUrlFail4")
    func testFakeUrlFail4() throws {
        currentTestingCaseNum = 3
        Downloader.requestTimeoutInterval = 4
        lyricsFileDownloader = LyricsFileDownloader()
        lyricsFileDownloader.delegate = self
        
        let urlString = urlStrings[3]
        let _ = lyricsFileDownloader.download(urlString: urlString)
        wait(for: [expFakeUrlFail4], timeout: 6)
    }
    
    func onLyricsFileDownloadProgress(requestId: Int, progress: Float) {
        
    }
    
    func onLyricsFileDownloadCompleted(requestId: Int,
                                       fileData: Data?,
                                       error: DownloadError?) {
        if currentTestingCaseNum == 0, let e = error, e.domainType == .httpDownloadError, e.code == -1004 { /** not connect **/
            expFakeUrlFail.fulfill()
        }
        if currentTestingCaseNum == 1, let e = error, e.domainType == .httpDownloadError, (e.code == -1003 || e.code == -1001) { /** time out **/
            /// A server with the specified hostname could not be found.
            /// or The request timed out.
            expFakeUrlFail2.fulfill()
        }
        if currentTestingCaseNum == 2, let e = error, e.domainType == .httpDownloadErrorLogic, e.code == 404 {
            expFakeUrlFail3.fulfill()
        }
        if currentTestingCaseNum == 3, let e = error, e.domainType == .httpDownloadError, e.code == -1001 { /** time out **/
            expFakeUrlFail4.fulfill()
        }
    }

}
