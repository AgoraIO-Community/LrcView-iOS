//
//  SongSourceProvider.swift
//  Demo
//
//  Created by ZYP on 2024/6/6.
//

import Foundation
import AgoraLyricsScore

struct Song {
    let name: String
    let id: Int
}

class SongSourceProvider {
    var currentIndex = 0
    
    let songs: [Song]
    let sourceType: SourceType
    
    init(sourceType: SourceType) {
        self.sourceType = sourceType
        switch sourceType {
        case .useForMcc:
            self.songs = [
                Song(name: "十年", id: 6625526605291650),
                Song(name: "爱情转移", id: 6246262727282860),
                Song(name: "说爱你", id: 6654550221757560),
                Song(name: "江南", id: 6246262727300580),
                Song(name: "容易受伤的女人", id: 6625526608670440)
            ]
        case .useForMccEx:
            self.songs = [Song(name: "offset test", id: 32183724),
                          Song(name: "绿光", id: 32133593),
                          Song(name: "在你的身边", id: 89488966),
                          Song(name: "奢香夫人", id: 32259070),
                          Song(name: "十年", id: 40289835),
                          Song(name: "明月几时有", id: 239038150)]
        }
    }
    
    func getNextSong() -> Song {
        let index = genNextIndex()
        let song = songs[index]
        return song
    }
    
    func genNextIndex() -> Int {
        let index = currentIndex
        if currentIndex == songs.count - 1 {
            currentIndex = 0
        }
        else {
            currentIndex += 1
        }
        return index
    }
}

extension SongSourceProvider {
    enum SourceType {
        case useForMcc
        case useForMccEx
    }
}
