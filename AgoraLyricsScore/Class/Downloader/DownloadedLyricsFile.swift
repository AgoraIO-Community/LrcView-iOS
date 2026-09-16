//
//  DownloadedLyricsFile.swift
//  AgoraLyricsScore
//

import Foundation

struct DownloadedLyricsFileResult {
    let data: Data
    let cacheError: Error?
}

enum DownloadedLyricsFile {
    static func consume(sourceURL: URL,
                        cacheURL: URL,
                        fileManager: FileManager = .default) throws -> DownloadedLyricsFileResult {
        let data = try Data(contentsOf: sourceURL)

        do {
            try fileManager.createDirectory(at: cacheURL.deletingLastPathComponent(),
                                            withIntermediateDirectories: true,
                                            attributes: nil)
            try data.write(to: cacheURL, options: .atomic)
            return DownloadedLyricsFileResult(data: data, cacheError: nil)
        } catch {
            return DownloadedLyricsFileResult(data: data, cacheError: error)
        }
    }
}
