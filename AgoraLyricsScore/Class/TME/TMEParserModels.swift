import Foundation

public struct TMEAPIStatus: Decodable {
    public let code: Int
    public let msg: String?
}

public struct TMEAPIEnvelope<DataType: Decodable>: Decodable {
    public let code: Int
    public let msg: String?
    public let data: DataType?
}

public struct TMEImagePath: Decodable {
    public let key: String
    public let value: String
}

public struct TMEAlbum: Decodable {
    public let albumId: String?
    public let albumName: String?
    public let imagePathMapList: [TMEImagePath]?
}

public struct TMEArtist: Decodable {
    public let artistId: String?
    public let artistName: String?
}

public struct TMELyric: Decodable {
    public let type: String
    public let url: String
}

public struct TMECopyright: Decodable {
    public let sceneId: String
    public let terminalIdList: [String]
}

public struct TMESongDetail: Decodable {
    public let songId: String
    public let songName: String
    public let version: String?
    public let duration: Int?
    public let status: Int?
    public let sequence: Int?
    public let grantStatus: Int?
    public let grantStartTime: String?
    public let publicTime: String?
    public let language: String?
    public let genre: String?
    public let grantedAreaCodes: [String]?
    public let pitchUrl: String?
    public let chorusStartMS: Int?
    public let chorusEndMS: Int?
    public let copyrightList: [TMECopyright]?
    public let album: TMEAlbum?
    public let artistList: [TMEArtist]?
    public let lrcList: [TMELyric]?
}

public struct TMESongsResult: Decodable {
    public let songList: [TMESongDetail]
    public let nextQueryInfo: String?
}

public struct TMESearchSongsResult: Decodable {
    public let total: Int
    public let songList: [TMESongDetail]
}

public struct TMESongInfoResult: Decodable {
    public let songList: [TMESongDetail]
}

public struct TMEMedia: Decodable {
    public let fileType: String
    public let url: String
    public let expire: String
}

public struct TMESongUrlResult: Decodable {
    public let mediaList: [TMEMedia]
}

public struct TMEPageItem: Decodable {
    public let code: String
    public let title: String
    public let description: String?
    public let url: String?
    public let status: Int?
}

public struct TMEPageResult: Decodable {
    public let total: Int
    public let list: [TMEPageItem]
}

public struct TMESongReference: Decodable {
    public let songId: String
}

public struct TMEDetailResult: Decodable {
    public let code: String
    public let title: String
    public let description: String?
    public let status: Int?
    public let imgUrl: String?
    public let songList: [TMESongReference]
}
