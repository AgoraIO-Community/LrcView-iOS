import Foundation
import AgoraLyricsScore

struct TmeSong {
    let id: String
    let name: String
    let artist: String
}

enum TmeSongCatalog {
    enum ParseError: Error, Equatable {
        case httpStatus(Int)
        case apiError(Int, String)
        case invalidResponse
    }

    static func parse(response: String, httpCode: Int) throws -> [TmeSong] {
        guard (200..<300).contains(httpCode) else {
            throw ParseError.httpStatus(httpCode)
        }
        let source = Data(response.utf8)
        guard let status = try? JSONDecoder().decode(TMEAPIStatus.self, from: source) else {
            throw ParseError.invalidResponse
        }
        guard status.code == 0 else {
            throw ParseError.apiError(status.code, status.msg ?? "Unknown error")
        }
        guard let body = try? JSONDecoder().decode(TMEAPIEnvelope<TMESongsResult>.self,
                                                   from: source),
              let data = body.data else {
            throw ParseError.invalidResponse
        }
        return Array(data.songList.filter { !$0.songId.isEmpty }.prefix(6)).map {
            TmeSong(id: $0.songId, name: $0.songName, artist: $0.artistList?.first?.artistName ?? "")
        }
    }
}
