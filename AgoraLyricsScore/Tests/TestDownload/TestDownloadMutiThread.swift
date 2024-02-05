//
//  TestDownloadMutiThread.swift
//  AgoraComponetLog-Unit-Tests
//
//  Created by ZYP on 2023/12/15.
//

import XCTest
@testable import AgoraLyricsScore

final class TestDownloadMutiThread: XCTestCase, LyricsFileDownloaderDelegate {
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
    var caseNum = 0
    
    override func setUpWithError() throws {
        exp.expectedFulfillmentCount = 10
        Log.setLoggers(loggers: [ConsoleLogger()])
        
    }

    override func tearDownWithError() throws {
        Downloader.requestTimeoutInterval = 60
    }
    
    /** 测试在不同线程下，执行download
        预期是一次download之后，会执行一次回调方法`onLyricsFileDownloadCompleted`
     **/
    func testMutiThread() throws {
        caseNum = 0
        lyricsFileDownloader = LyricsFileDownloader()
        lyricsFileDownloader.cleanAll()
        Downloader.requestTimeoutInterval = 10
        let semp = DispatchSemaphore(value: 0)
        DispatchQueue.global().async { [weak self] in
            guard let self  = self else { return }
            lyricsFileDownloader.maxFileAge = 5
            lyricsFileDownloader.maxFileNum = 6
            lyricsFileDownloader.cleanAll()
            semp.signal()
        }
        lyricsFileDownloader.delegate = self
        semp.wait()
        for urlString in urlStrings {
            DispatchQueue.global().async { [weak self] in
                guard let self  = self else { return }
                let id = self.lyricsFileDownloader.download(urlString: urlString)
                print("[test] download for id:\(id)")
            }
        }
        
        wait(for: [exp, expFail], timeout: 20)
    }
    
    let queue1 = DispatchQueue(label: "test.queue.1")
    let queue2 = DispatchQueue(label: "test.queue.1")
    let expectation = XCTestExpectation(description: "异步方法未调用")
    /** 测试在不同线程下，执行download和cancelDownload，url是一个预期不存在域名的类型
        预期是不会执行回调方法`onLyricsFileDownloadCompleted`
     **/
    func testMutiThread1() throws {
        caseNum = 1
        Downloader.requestTimeoutInterval = 3
        let semp = DispatchSemaphore(value: 0)
        lyricsFileDownloader = LyricsFileDownloader()
        lyricsFileDownloader.delegate = self
        queue1.sync { [weak self] in
            guard let self = self else { return }
            lyricsFileDownloader.maxFileAge = 5
            lyricsFileDownloader.maxFileNum = 6
            lyricsFileDownloader.cleanAll()
            let id = self.lyricsFileDownloader.download(urlString: "https://agora.fake.domain.com/lyricsMockDownload/1.zip")
            print("[test] download for id:\(id)")
            semp.signal()
            
        }
        
        queue2.async { [weak self] in
            guard let self  = self else { return }
            semp.wait()
            let _ = lyricsFileDownloader.cancelDownload(requestId: 0)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
            self.expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 5)
    }
    
    func onLyricsFileDownloadProgress(requestId: Int, progress: Float) {
        
    }
    
    func onLyricsFileDownloadCompleted(requestId: Int,
                                       fileData: Data?,
                                       error: DownloadError?) {
        if caseNum == 0 {
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
        if caseNum == 1 {
            print("testMutiThread1 fail")
            XCTAssert(false)
        }
    }
}
