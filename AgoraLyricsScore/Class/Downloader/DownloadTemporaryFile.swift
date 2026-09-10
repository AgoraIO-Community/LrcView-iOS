//
//  DownloadTemporaryFile.swift
//  AgoraLyricsScore
//

import Foundation

enum DownloadTemporaryFileError: Error {
    case createOutputStreamFailed
    case outputStreamNotOpen
    case writeFailed
}

final class DownloadTemporaryFile {
    static var defaultRootURL: URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent("LyricDownloadFiles", isDirectory: true)
    }

    let directoryURL: URL
    let fileURL: URL

    private let fileManager: FileManager
    private var outputStream: OutputStream?

    init(filename: String,
         rootURL: URL = DownloadTemporaryFile.defaultRootURL,
         identifier: String = UUID().uuidString,
         fileManager: FileManager = .default) throws {
        self.fileManager = fileManager
        directoryURL = rootURL.appendingPathComponent(identifier, isDirectory: true)
        let safeFilename = URL(fileURLWithPath: filename).lastPathComponent
        fileURL = directoryURL.appendingPathComponent(safeFilename, isDirectory: false)
        try fileManager.createDirectory(at: directoryURL,
                                        withIntermediateDirectories: true,
                                        attributes: nil)
    }

    func open() throws {
        close()
        guard let stream = OutputStream(url: fileURL, append: false) else {
            throw DownloadTemporaryFileError.createOutputStreamFailed
        }
        outputStream = stream
        stream.open()
    }

    func write(_ data: Data) throws {
        guard let stream = outputStream else {
            throw DownloadTemporaryFileError.outputStreamNotOpen
        }

        try data.withUnsafeBytes { rawBuffer in
            guard var pointer = rawBuffer.bindMemory(to: UInt8.self).baseAddress else {
                return
            }
            var remaining = rawBuffer.count
            while remaining > 0 {
                let written = stream.write(pointer, maxLength: remaining)
                guard written > 0 else {
                    throw stream.streamError ?? DownloadTemporaryFileError.writeFailed
                }
                pointer = pointer.advanced(by: written)
                remaining -= written
            }
        }
    }

    func close() {
        outputStream?.close()
        outputStream = nil
    }

    func remove() throws {
        close()
        if fileManager.fileExists(atPath: directoryURL.path) {
            try fileManager.removeItem(at: directoryURL)
        }
    }
}
