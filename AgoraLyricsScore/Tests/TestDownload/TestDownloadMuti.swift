//
//  TestDownloadMuti.swift
//  AgoraLyricsScore
//
//  Created by ZYP on 2023/12/14.
//

import XCTest
@testable import AgoraLyricsScore

final class TestDownloadMuti: XCTestCase, LyricsFileDownloaderDelegate {
    var lyricsFileDownloader: LyricsFileDownloader!
    let exp = XCTestExpectation(description: "TestDownloadMuti")
    let expFail = XCTestExpectation(description: "TestDownloadMuti fail")
    let urlStrings = ["https://127.0.0.1/lyricsMockDownload/1.zip",
                      "https://fullapp.oss-cn-beijing.aliyuncs.com/lyricsMockDownload/1.zip",
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
        exp.expectedFulfillmentCount = 10
        Log.setLoggers(loggers: [ConsoleLogger()])
        lyricsFileDownloader = LyricsFileDownloader()
        lyricsFileDownloader.cleanAll()
    }
    
    override func tearDownWithError() throws {
        Downloader.requestTimeoutInterval = 60
        lyricsFileDownloader.cleanAll()
        lyricsFileDownloader = nil
    }
    
    func testMuti() throws {
        Downloader.requestTimeoutInterval = 10
        lyricsFileDownloader.delegate = self
        
        for urlString in urlStrings {
            let id = lyricsFileDownloader.download(urlString: urlString)
            print("[test] download for id:\(id)")
        }
        
        wait(for: [exp, expFail], timeout: 40)
    }
    
    func onLyricsFileDownloadProgress(requestId: Int, progress: Float) {
        
    }
    
    func onLyricsFileDownloadCompleted(requestId: Int,
                                       fileData: Data?,
                                       error: DownloadError?) {
        let result = error != nil ? "fail" : "success"
        print("[test]requestId:\(requestId) \(result)")
        exp.fulfill()
        
        if requestId == 0, error != nil {
            expFail.fulfill()
        }
        if requestId == 0, error == nil {
            fatalError()
        }
    }
}
