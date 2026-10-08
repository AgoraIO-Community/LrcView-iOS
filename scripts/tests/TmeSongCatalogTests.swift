import Foundation
import AgoraLyricsScore

@main
struct TmeSongCatalogTests {
    static func main() throws {
        let items = (0..<7).map { index in
            """
            {"songId":"00\(index)A", "songName":"Song \(index)", "artistList":[{"artistName":"Artist \(index)"}]}
            """
        }.joined(separator: ",")
        let response = """
        {"code":0,"msg":"SUCCESS","data":{"songList":[\(items)],"nextQueryInfo":"next"}}
        """
        let songs = try TmeSongCatalog.parse(response: response, httpCode: 200)
        precondition(songs.count == 6)
        precondition(songs[0].id == "000A")
        precondition(songs[0].name == "Song 0")
        precondition(songs[0].artist == "Artist 0")
        precondition(songs[5].id == "005A")

        do {
            _ = try TmeSongCatalog.parse(response: response, httpCode: 401)
            fatalError("HTTP error must not produce a song list")
        } catch TmeSongCatalog.ParseError.httpStatus(401) {}

        do {
            _ = try TmeSongCatalog.parse(response: "{\"code\":1,\"msg\":\"denied\"}", httpCode: 200)
            fatalError("Application error must not produce a song list")
        } catch TmeSongCatalog.ParseError.apiError(1, "denied") {}

        do {
            let response = "{\"code\":1,\"msg\":\"denied\",\"data\":{\"other\":\"value\"}}"
            _ = try TmeSongCatalog.parse(response: response, httpCode: 200)
            fatalError("Application error must take precedence over response data")
        } catch TmeSongCatalog.ParseError.apiError(1, "denied") {}

        do {
            _ = try TmeSongCatalog.parse(response: "not json", httpCode: 200)
            fatalError("Invalid JSON must not produce a song list")
        } catch TmeSongCatalog.ParseError.invalidResponse {}

        let detailed = """
        {"code":0,"data":{"songList":[{"songId":"s1","songName":"要强","version":"",
        "duration":220,"status":1,"sequence":8,"grantStatus":1,
        "grantStartTime":"2022-06-15 00:00:00","publicTime":"2004-09-15 00:00:00",
        "language":"普通话","genre":"POP","grantedAreaCodes":["CN"],
        "pitchUrl":"https://example.com/pitch.txt","chorusStartMS":21923,"chorusEndMS":42983,
        "copyrightList":[{"sceneId":"1","terminalIdList":["1","2"]}],
        "album":{"albumId":"a1","albumName":"专辑","imagePathMapList":[{"key":"cover","value":"https://example.com/a.jpg"}]},
        "artistList":[{"artistId":"r1","artistName":"歌手"}],
        "lrcList":[{"type":"lrc","url":"https://example.com/a.lrc"}]}]}}
        """
        let decoded = try JSONDecoder().decode(TMEAPIEnvelope<TMESongsResult>.self,
                                               from: Data(detailed.utf8))
        let detail = decoded.data?.songList.first
        precondition(detail?.album?.imagePathMapList?.first?.key == "cover")
        precondition(detail?.lrcList?.first?.url == "https://example.com/a.lrc")
        precondition(detail?.copyrightList?.first?.terminalIdList == ["1", "2"])
        precondition(detail?.chorusStartMS == 21923)
        precondition(detail?.grantedAreaCodes == ["CN"])
        precondition(detail?.duration == 220)
        let mapped = try TmeSongCatalog.parse(response: detailed, httpCode: 200)
        precondition(mapped.first?.artist == "歌手")

        print("TmeSongCatalogTests passed")
    }
}
