//
//  TestFileCache.swift
//  AgoraComponetLog-Unit-Tests
//
//  Created by ZYP on 2023/12/13.
//

import XCTest
@testable import AgoraLyricsScore

final class TestFileCache: XCTestCase {
    var fileCache: FileCache!
    
    override func setUpWithError() throws {
        Log.setLoggers(loggers: [ConsoleLogger()])
    }

    override func tearDownWithError() throws {
        fileCache = nil
    }

    func testMaxFile() {
        fileCache = FileCache()
        fileCache.maxFileNum = 10
        fileCache.clearAll()
        
        let fileManager = FileManager.default
        let directory = String.cacheFolderPath()
        for index in 0...fileCache.maxFileNum {
            let filePath = directory + "/" + "\(index).xml"
            fileManager.createFile(atPath: filePath,
                                   contents: "123".data(using: .utf8),
                                   attributes: nil)
        }
        
        var files = fileCache.findXMLandLRCFiles(inDirectory: .cacheFolderPath()).sorted { l, r in
            l.createdTimeStamp < r.createdTimeStamp
        }
        
        for file in files {
            print("\(file.createdTimeStamp)-\(file.path.fileName)")
        }
        XCTAssertEqual(files.count, Int(fileCache.maxFileNum)+1)
        
        fileCache.removeFilesIfNeeded()
        
        files = fileCache.findXMLandLRCFiles(inDirectory: .cacheFolderPath()).sorted { l, r in
            l.createdTimeStamp < r.createdTimeStamp
        }
        for file in files {
            print("\(file.createdTimeStamp)-\(file.path.fileName)")
        }
        
        let fileNames = files.map({ $0.path.fileName })
        XCTAssertEqual(fileNames.count, Int(fileCache.maxFileNum))
        XCTAssertFalse(fileNames.contains("0.xml"))
        
        fileCache.clearAll()
        
        files = fileCache.findXMLandLRCFiles(inDirectory: .cacheFolderPath()).sorted { l, r in
            l.createdTimeStamp < r.createdTimeStamp
        }
        
        XCTAssertEqual(files.count, 0)
    }
    
    func testMaxFileAge() {
        fileCache = FileCache()
        fileCache.maxFileNum = 5
        fileCache.maxFileAge = 1
        fileCache.clearAll()
        
        let fileManager = FileManager.default
        let directory = String.cacheFolderPath()
        for index in 0...fileCache.maxFileNum {
            let filePath = directory + "/" + "\(index).xml"
            fileManager.createFile(atPath: filePath,
                                   contents: "123".data(using: .utf8),
                                   attributes: nil)
        }
        
        var files = fileCache.findXMLandLRCFiles(inDirectory: .cacheFolderPath()).sorted { l, r in
            l.createdTimeStamp < r.createdTimeStamp
        }
        
        for file in files {
            print("\(file.createdTimeStamp)-\(file.path.fileName)")
        }
        XCTAssertEqual(files.count, Int(fileCache.maxFileNum)+1)
        
        Thread.sleep(forTimeInterval: 2)
        fileCache.removeFilesIfNeeded()
        
        files = fileCache.findXMLandLRCFiles(inDirectory: .cacheFolderPath()).sorted { l, r in
            l.createdTimeStamp < r.createdTimeStamp
        }
        
        XCTAssertEqual(files.count, 0)
        
    }
}
