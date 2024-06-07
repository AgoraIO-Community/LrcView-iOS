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
    
    let songs: [Song] = [
        Song(name: "十年", id: 6625526605291650),
        Song(name: "爱情转移", id: 6246262727282860),
        Song(name: "说爱你", id: 6654550221757560),
        Song(name: "江南", id: 6246262727300580),
        Song(name: "容易受伤的女人", id: 6625526608670440)
    ]
    
    func getNextSong() -> Song {
        let song = songs[currentIndex]
        if currentIndex == songs.count - 1 {
            currentIndex = 0
        }
        else {
            currentIndex += 1
        }
        return song
    }
}
