struct Song: Equatable {
    let name: String
    let id: Int
}

enum SongCatalog {
    static let songs = [
        Song(name: "十年", id: 6625526605291650),
        Song(name: "爱情转移", id: 6246262727282860),
        Song(name: "说爱你", id: 6654550221757560),
        Song(name: "江南", id: 6246262727300580),
        Song(name: "容易受伤的女人", id: 6625526608670440)
    ]

    static func next(after song: Song) -> Song {
        guard let index = songs.firstIndex(of: song) else { return songs[0] }
        return songs[(index + 1) % songs.count]
    }
}
