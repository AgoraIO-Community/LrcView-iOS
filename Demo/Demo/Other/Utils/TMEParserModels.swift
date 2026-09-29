import Foundation

struct TMEAPIStatus: Decodable {
    let code: Int
    let msg: String?
}

struct TMEAPIEnvelope<DataType: Decodable>: Decodable {
    let code: Int
    let msg: String?
    let data: DataType?
}

struct TMEImagePath: Decodable {
    let key: String
    let value: String
}

struct TMEAlbum: Decodable {
    let albumId: String?
    let albumName: String?
    let imagePathMapList: [TMEImagePath]?
}

struct TMEArtist: Decodable {
    let artistId: String?
    let artistName: String?
}

struct TMELyric: Decodable {
    let type: String
    let url: String
}

struct TMECopyright: Decodable {
    let sceneId: String
    let terminalIdList: [String]
}

struct TMESongDetail: Decodable {
    let songId: String
    let songName: String
    let version: String?
    let duration: Int?
    let status: Int?
    let sequence: Int?
    let grantStatus: Int?
    let grantStartTime: String?
    let publicTime: String?
    let language: String?
    let genre: String?
    let grantedAreaCodes: [String]?
    let pitchUrl: String?
    let chorusStartMS: Int?
    let chorusEndMS: Int?
    let copyrightList: [TMECopyright]?
    let album: TMEAlbum?
    let artistList: [TMEArtist]?
    let lrcList: [TMELyric]?
}

struct TMESongsResult: Decodable {
    let songList: [TMESongDetail]
    let nextQueryInfo: String?
}

struct TMESearchSongsResult: Decodable {
    let total: Int
    let songList: [TMESongDetail]
}

struct TMESongInfoResult: Decodable {
    let songList: [TMESongDetail]
}

struct TMEMedia: Decodable {
    let fileType: String
    let url: String
    let expire: String
}

struct TMESongUrlResult: Decodable {
    let mediaList: [TMEMedia]
}

struct TMEPageItem: Decodable {
    let code: String
    let title: String
    let description: String?
    let url: String?
    let status: Int?
}

struct TMEPageResult: Decodable {
    let total: Int
    let list: [TMEPageItem]
}

struct TMESongReference: Decodable {
    let songId: String
}

struct TMEDetailResult: Decodable {
    let code: String
    let title: String
    let description: String?
    let status: Int?
    let imgUrl: String?
    let songList: [TMESongReference]
}
