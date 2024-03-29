//
//  TestDownloadFile.swift
//  AgoraComponetLog-Unit-Tests
//
//  Created by ZYP on 2024/1/18.
//

import XCTest
@testable import AgoraLyricsScore

final class TestDownloadFile: XCTestCase, LyricsFileDownloaderDelegate {
    var lyricsFileDownloader: LyricsFileDownloader!
    let exp1 = XCTestExpectation(description: "down5Files conpleted  fail")
    let exp2 = XCTestExpectation(description: "downIndex=5File conpleted  fail")
    let exp3 = XCTestExpectation(description: "downIndex=6File conpleted  fail")
    let exp4 = XCTestExpectation(description: "max age test 1")
    let exp5 = XCTestExpectation(description: "max age test 2")
    var currentStep = 1
    var currentCaseNum = 0
    let urlStrings = ["https://fullapp.oss-cn-beijing.aliyuncs.com/lyricsMockDownload/1.zip",
                      "https://fullapp.oss-cn-beijing.aliyuncs.com/lyricsMockDownload/2.zip",
                      "https://fullapp.oss-cn-beijing.aliyuncs.com/lyricsMockDownload/3.zip",
                      "https://fullapp.oss-cn-beijing.aliyuncs.com/lyricsMockDownload/4.zip",
                      "https://fullapp.oss-cn-beijing.aliyuncs.com/lyricsMockDownload/5.zip"]
    override func setUpWithError() throws {
        Log.setLoggers(loggers: [ConsoleLogger()])
        lyricsFileDownloader = LyricsFileDownloader()
        exp1.expectedFulfillmentCount = 5
        exp4.expectedFulfillmentCount = 2
    }

    override func tearDownWithError() throws {
        lyricsFileDownloader = nil
    }

    func testMaxFile() throws {
        lyricsFileDownloader.cleanAll()
        Downloader.requestTimeoutInterval = 10
        lyricsFileDownloader.maxFileNum = 5
        lyricsFileDownloader.delegate = self
        
        /// 下载5个文件
        for urlString in urlStrings {
            let id = lyricsFileDownloader.download(urlString: urlString)
            /// 延时一下，保证下载的创建时间是按顺序的
            sleep(1)
            print("[test] download for id:\(id)")
        }
        wait(for: [exp1], timeout: 11)
        var fileNames = getFileNams()
        XCTAssertEqual(fileNames, [1, 2, 3, 4, 5])
        
        /// 再下载1个已存在的文件 5.xml
        currentStep = 2
        var id = lyricsFileDownloader.download(urlString: urlStrings.last!)
        print("[test] download for id:\(id)")
        wait(for: [exp2], timeout: 10)
        
        fileNames = getFileNams()
        XCTAssertEqual(fileNames, [1, 2, 3, 4, 5])
        
        /// 再下载不存在的文件 6.xml
        currentStep = 3
        id = lyricsFileDownloader.download(urlString: "https://fullapp.oss-cn-beijing.aliyuncs.com/lyricsMockDownload/6.zip")
        print("[test] download for id:\(id)")
        wait(for: [exp3], timeout: 10)
        
        fileNames = getFileNams()
        XCTAssertEqual(fileNames, [2, 3, 4, 5, 6])
    }
    
    func testMaxAge() throws {
        currentCaseNum = 1
        lyricsFileDownloader.cleanAll()
        Downloader.requestTimeoutInterval = 8
        lyricsFileDownloader.maxFileNum = 5
        lyricsFileDownloader.maxFileAge = 300
        lyricsFileDownloader.delegate = self
        let urlString = "https://fullapp.oss-cn-beijing.aliyuncs.com/lyricsMockDownload/6.zip"
        
        currentStep = 1
        var id = lyricsFileDownloader.download(urlString: urlString)
        print("[test] download for id:\(id)")
        wait(for: [exp4], timeout: 8)
        
        currentStep = 2
        id = lyricsFileDownloader.download(urlString: urlString)
        print("[test] download for id:\(id)")
        wait(for: [exp5], timeout: 8)
    }

    func onLyricsFileDownloadProgress(requestId: Int, progress: Float) {
        if currentCaseNum == 1, currentStep == 1 {
            exp4.fulfill()
        }
    }
    
    func onLyricsFileDownloadCompleted(requestId: Int, fileData: Data?, error: DownloadError?) {
        
        if currentCaseNum == 0 {
            if error != nil {
                fatalError()
            }
            
            if currentStep == 1 {
                exp1.fulfill()
            }
            if currentStep == 2 {
                exp2.fulfill()
            }
            if currentStep == 3 {
                exp3.fulfill()
            }
        }
        
        if currentCaseNum == 1 {
            if error != nil {
                fatalError()
            }
            if currentStep == 1 {
                exp4.fulfill()
            }
            if currentStep == 2 {
                exp5.fulfill()
            }
        }
    }
    
    /// 返回一个文件列表，列表里面是文件名称的数字
    func getFileNams() -> [Int] {
        let fileCache = FileCache()
        let fileNames = fileCache.findFiles(inDirectory: .cacheFolderPath()).map({ URL(fileURLWithPath: $0.path).lastPathComponent }).map({ $0.split(separator: ".").first! }).map({ Int($0)! })
        return fileNames.sorted()
    }
}
