//
//  TestDownloadCancle.swift
//  AgoraComponetLog-Unit-Tests
//
//  Created by ZYP on 2024/1/17.
//

import XCTest
@testable import AgoraLyricsScore

final class TestDownloadCancle: XCTestCase, LyricsFileDownloaderDelegate {
    let exp = XCTestExpectation(description: "TestDownloadCancle.cancel")
    var actualSuccessCount = 0
    var lyricsFileDownloader: LyricsFileDownloader!
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
        exp.expectedFulfillmentCount = 7
        Downloader.requestTimeoutInterval = 9
        Log.setLoggers(loggers: [ConsoleLogger()])
    }

    override func tearDownWithError() throws {
        lyricsFileDownloader = nil
    }

    func testExample() throws {
        lyricsFileDownloader = LyricsFileDownloader()
        lyricsFileDownloader.delegate = self
        lyricsFileDownloader.cleanAll()
        
        for url in urlStrings {
            let id = lyricsFileDownloader.download(urlString: url)
            print("[test] download for id:\(id)")
        }
        
        lyricsFileDownloader.cancleDownload(requestId: 7)
        lyricsFileDownloader.cancleDownload(requestId: 8)
        lyricsFileDownloader.cancleDownload(requestId: 9)
        
        wait(for: [exp], timeout: 10)
        
        let fileCache = FileCache()
        let count = fileCache.findFiles(inDirectory: .cacheFolderPath()).count
        XCTAssertEqual(count, actualSuccessCount)
    }

    func onLyricsFileDownloadCompleted(requestId: Int,
                                       fileData: Data?,
                                       error: DownloadError?) {
        if error == nil {
            actualSuccessCount += 1
        }
        exp.fulfill()
    }
    
    func onLyricsFileDownloadProgress(requestId: Int, progress: Float) {
        
    }
}
