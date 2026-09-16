//
//  LyricsArchiveContent.swift
//  AgoraLyricsScore
//

import Foundation

enum LyricsArchiveProcessingStep: String {
    case createExtractionDirectory = "create extraction directory"
    case unzipArchive = "unzip archive"
    case selectLyricsFile = "select lyrics file"
    case readLyricsFile = "read lyrics file"
    case createCacheDirectory = "create cache directory"
    case writeCacheFile = "write cache file"

    func failureDescription(requestId: Int,
                            archivePath: String,
                            error: Error) -> String {
        return "zip processing failed requestId:\(requestId) step:\(rawValue) archive:\(archivePath) error:\(error.localizedDescription)"
    }
}

enum LyricsArchiveContentError: LocalizedError {
    case invalidRegularFileCount(Int)

    var errorDescription: String? {
        switch self {
        case .invalidRegularFileCount(let count):
            return "expected one regular file in lyrics archive, found \(count)"
        }
    }
}

enum LyricsArchiveContent {
    static func onlyRegularFile(in directoryURL: URL,
                                fileManager: FileManager = .default) throws -> URL {
        guard let enumerator = fileManager.enumerator(at: directoryURL,
                                                      includingPropertiesForKeys: [.isRegularFileKey],
                                                      options: []) else {
            throw LyricsArchiveContentError.invalidRegularFileCount(0)
        }

        var files = [URL]()
        for case let fileURL as URL in enumerator {
            let values = try fileURL.resourceValues(forKeys: [.isRegularFileKey])
            if values.isRegularFile == true {
                files.append(fileURL)
            }
        }

        guard files.count == 1, let fileURL = files.first else {
            throw LyricsArchiveContentError.invalidRegularFileCount(files.count)
        }
        return fileURL
    }
}
