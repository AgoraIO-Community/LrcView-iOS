//
//  Logger.swift
//  AgoraLyricsScore
//
//  Created by ZYP on 2023/2/3.
//

import Foundation

// MARK:- ConsoleLogger

public class ConsoleLogger: NSObject, ILogger {
    @objc public func onLog(content: String,
                            tag: String?,
                            time: String,
                            level: LoggerLevel) {
        
        let text = tag == nil ? "[AgoraLyricsScore][\(level)]: " + content : "[AgoraLyricsScore][\(level)][\(tag!)]: " + content
        print(text)
    }
}

// MARK:- FileLogger

public class FileLogger: NSObject, ILogger {
    var name = "logfile"
    var maxFileSize: UInt64 = 1024 * 15
    var maxFileCount = 5
    var directory = FileLogger.defaultDirectory() {
        didSet {
            directory = NSString(string: directory).expandingTildeInPath
            
            let fileManager = FileManager.default
            if !fileManager.fileExists(atPath: directory) {
                do {
                    try fileManager.createDirectory(atPath: directory, withIntermediateDirectories: true, attributes: nil)
                } catch {
                    NSLog("Couldn't create directory at \(directory)")
                }
            }
        }
    }
    
    var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM-dd HH:mm:ss"
        return formatter
    }
    
    var currentPath: String {
        return "\(directory)/\(logName(0))"
    }
    
    func write(text: String) {
        let writeText = text
        let path = currentPath
        let fileManager = FileManager.default
        if !fileManager.fileExists(atPath: path) {
            do {
                try "".write(toFile: path, atomically: true, encoding: String.Encoding.utf8)
            } catch _ {}
        }
        if let fileHandle = FileHandle(forWritingAtPath: path) {
            fileHandle.seekToEndOfFile()
            fileHandle.write(writeText.data(using: String.Encoding.utf8)!)
            fileHandle.closeFile()
            cleanup()
        }
    }
    
    ///do the checks and cleanup
    func cleanup() {
        let path = "\(directory)/\(logName(0))"
        let size = fileSize(path)
        let maxSize: UInt64 = maxFileSize * 1024
        if size > 0 && size >= maxSize && maxSize > 0 && maxFileCount > 0 {
            rename(0)
            //delete the oldest file
            let deletePath = "\(directory)/\(logName(maxFileCount))"
            let fileManager = FileManager.default
            do {
                try fileManager.removeItem(atPath: deletePath)
            } catch _ {}
        }
    }
    
    ///check the size of a file
    func fileSize(_ path: String) -> UInt64 {
        let fileManager = FileManager.default
        let attrs: NSDictionary? = try? fileManager.attributesOfItem(atPath: path) as NSDictionary
        if let dict = attrs {
            return dict.fileSize()
        }
        return 0
    }
    
    ///Recursive method call to rename log files
    func rename(_ index: Int) {
        let fileManager = FileManager.default
        let path = "\(directory)/\(logName(index))"
        let newPath = "\(directory)/\(logName(index+1))"
        if fileManager.fileExists(atPath: newPath) {
            rename(index+1)
        }
        do {
            try fileManager.moveItem(atPath: path, toPath: newPath)
        } catch _ {}
    }
    
    ///gets the log name
    func logName(_ num :Int) -> String {
        return "\(name)-\(num).log"
    }
    
    ///get the default log directory
    class func defaultDirectory() -> String {
        var path = ""
        let fileManager = FileManager.default
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        path = "\(paths[0])/Logs"
        if !fileManager.fileExists(atPath: path) && path != ""  {
            do {
                try fileManager.createDirectory(atPath: path, withIntermediateDirectories: false, attributes: nil)
            } catch _ {}
        }
        return path
    }
    
    @objc public func onLog(content: String,
                            tag: String?,
                            time: String,
                            level: LoggerLevel) {
        let text = tag == nil ? "[AgoraLyricsScore][\(level)]: " + content : "[AgoraLyricsScore][\(level)][\(tag!)]: " + content
        write(text: text)
    }
}
