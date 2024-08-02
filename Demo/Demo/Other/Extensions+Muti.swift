//
//  Extensions+Muti.swift
//  Demo
//
//  Created by ZYP on 2024/8/2.
//

import AgoraLyricsScore
import AgoraRtcKit

extension LyricModel {
    static func instanceByMccLyricInfo(info: AgoraLyricInfo) -> LyricModel {
        let lines = info.sentences.map { sentence in
            let tones = sentence.words.map({ LyricToneModel(beginTime: $0.begin, duration: $0.duration, word: $0.word, pitch: $0.refPitch, lang: .zh, pronounce: "") })
            let line = LyricLineModel(beginTime: sentence.begin,
                                      duration: sentence.duration,
                                      content: sentence.content,
                                      tones: tones)
            return line
        }
        
        let lyricsType = (info.sourceType == .xml) ? LyricsType.xml : LyricsType.lrc
        return LyricModel(name: info.name,
                          singer: info.singer,
                          lyricsType: lyricsType,
                          lines: lines,
                          preludeEndPosition: info.preludeEndPosition,
                          duration: info.duration,
                          hasPitch: info.hasPitch)
    }
}
