//
//  TestDownloadCancle.swift
//  AgoraComponetLog-Unit-Tests
//
//  Created by ZYP on 2024/1/17.
//

import XCTest
@testable import AgoraLyricsScore

final class TestDownloadCancle: XCTestCase, LyricsFileDownloaderDelegate {
    
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
        
        lyricsFileDownloader.cancleDownload(requestId: 5)
        lyricsFileDownloader.cancleDownload(requestId: 6)
        lyricsFileDownloader.cancleDownload(requestId: 7)
        
        sleep(10)
        let fileCache = FileCache()
        let count = fileCache.findFiles(inDirectory: .cacheFolderPath()).count
        XCTAssertEqual(count, 7)
    }

    func onLyricsFileDownloadProgress(requestId: Int, progress: Float) {
        
    }
    
    func onLyricsFileDownloadCompleted(requestId: Int,
                                       fileData: Data?,
                                       error: DownloadError?) {
        
    }
}
