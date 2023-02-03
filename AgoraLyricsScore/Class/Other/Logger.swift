//
//  Logger.swift
//  AgoraLyricsScore
//
//  Created by ZYP on 2023/2/3.
//

import Foundation

///The log class containing all the needed methods
open class Logger {
    
    ///The max size a log file can be in Kilobytes. Default is 1024 (1 MB)
    open var maxFileSize: UInt64 = 1024 * 8
    
    ///The max number of log file that will be stored. Once this point is reached, the oldest file is deleted.
    open var maxFileCount = 8
    
    ///The directory in which the log files will be written
    open var directory = Logger.defaultDirectory() {
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

    open var currentPath: String {
        return "\(directory)/\(logName(0))"
    }

    ///The name of the log files
    open var name = "logfile"
    
    ///Whether or not logging also prints to the console
    open var printToConsole = true
    
    ///logging singleton
    open class var logger: Logger {
        
        struct Static {
            static let instance: Logger = Logger()
        }
        return Static.instance
    }
    //the date formatter
    var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM-dd HH:mm:ss"
        return formatter
    }
    
    ///write content to the current log file.
    open func write(_ text: String) {
        let path = currentPath
        let fileManager = FileManager.default
        if !fileManager.fileExists(atPath: path) {
            do {
                try "".write(toFile: path, atomically: true, encoding: String.Encoding.utf8)
            } catch _ {
            }
        }
        if let fileHandle = FileHandle(forWritingAtPath: path) {
            let dateStr = dateFormatter.string(from: Date())
            let writeText = "[\(dateStr)]\(text)\n"
            fileHandle.seekToEndOfFile()
            fileHandle.write(writeText.data(using: String.Encoding.utf8)!)
            fileHandle.closeFile()
            if printToConsole {
                print(writeText, terminator: "")
            }
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
            } catch _ {
            }
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
        } catch _ {
        }
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
            } catch _ {
            }
        }
        return path
    }
    
}


