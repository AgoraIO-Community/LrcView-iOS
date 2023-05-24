//
//  Parser.swift
//  AgoraLyricsScore
//
//  Created by ZYP on 2022/12/21.
//

import Foundation

class XmlParser: NSObject {
    fileprivate let logTag = "XmlParser"
    fileprivate var parserTypes: [ParserType] = []
    fileprivate var song: LyricModel!
    
    deinit {
        Log.info(text: "deinit", tag: logTag)
    }
    
    func parseLyricData(data: Data) -> LyricModel? {
        song = nil
        parserTypes = []
        let parser = XMLParser(data: data)
        parser.delegate = self
        let success = parser.parse()
        if !success {
            let error = parser.parserError
            let line = parser.lineNumber
            let col = parser.columnNumber
            Log.error(error: "parsing Error(\(error?.localizedDescription ?? "")) at \(line):\(col)", tag: logTag)
            return nil
        }
        
        if song == nil {
            return nil
        }
        
        let model = process()
        return model
    }
    
    private func process() -> LyricModel? {
        if song.lines.count == 0 {
            let text = "data error. song.lines: \(song.lines)"
            Log.error(error: text, tag: logTag)
            return nil
        }
        var hasPitch = false
        var preludeEndPosition = -1
        for line in song.lines {
            var content = ""
            for item in line.tones.enumerated() {
                let tone = item.element
                let index = item.offset
                if tone.lang == .en, tone.word != "" { /** 处理空白 **/
                    let count = line.tones.count
                    let lead = (index >= 1 && line.tones[index - 1].lang != .en && line.tones[index - 1].word != "") ? " " : ""
                    let trail = index == count - 1 ? "" : " "
                    tone.word = "\(lead)\(tone.word)\(trail)"
                }
                if tone.pitch > 0 {
                    hasPitch = true
                }
                if preludeEndPosition == -1 {
                    preludeEndPosition = tone.beginTime
                }
                content += tone.word
            }
            
            let lineBeginTime = line.tones.first?.beginTime ?? -1
            let lineEndTime = (line.tones.last?.duration ?? -1) + (line.tones.last?.beginTime ?? -1)
            if lineBeginTime < 0 || lineEndTime < 0 || lineEndTime - lineBeginTime < 0 {
                let text = "data error. lineBeginTime: \(lineBeginTime) lineEndTime: \(lineEndTime)"
                Log.error(error: text, tag: logTag)
                return nil
            }
            line.beginTime = lineBeginTime
            line.duration = lineEndTime - lineBeginTime
            line.content = content
        }
        
        if let lastDuration = song.lines.last?.duration,
           let lastBeginTime = song.lines.last?.beginTime {
            song.duration = lastDuration + lastBeginTime
        }
        song.hasPitch = hasPitch
        song.preludeEndPosition = preludeEndPosition
        return song
    }
}

// MARK: - 状态
extension XmlParser {
    fileprivate func current(type: ParserType) -> Bool {
        return parserTypes.last == type
    }
    
    fileprivate func push(_ type: ParserType) {
        parserTypes.append(type)
    }
    
    fileprivate func pop() {
        parserTypes.removeLast()
    }
    
    fileprivate func pop(equal: ParserType) {
        if current(type: equal) {
            pop()
        }
    }
}

// MARK: - XMLParserDelegate
extension XmlParser: XMLParserDelegate {
    func parserDidStartDocument(_: XMLParser) {}
    
    func parserDidEndDocument(_: XMLParser) {}
    
    func parser(_: XMLParser, parseErrorOccurred parseError: Error) {
        Log.error(error: parseError.localizedDescription, tag: logTag)
    }
    
    func parser(_: XMLParser, validationErrorOccurred validationError: Error) {
        Log.error(error: validationError.localizedDescription, tag: logTag)
    }
    
    func parser(_: XMLParser,
                didStartElement elementName: String,
                namespaceURI _: String?,
                qualifiedName _: String?,
                attributes attributeDict: [String: String] = [:]) {
        switch elementName {
        case "song":
            song = LyricModel(name: "",
                              singer: "",
                              type: .slow,
                              lines: [],
                              preludeEndPosition: 0,
                              duration: 0,
                              hasPitch: false,
                              sourceType: .xml)
        case "general":
            push(.general)
        case "name":
            push(.name)
        case "singer":
            push(.singer)
        case "type":
            push(.type)
        case "sentence":
            push(.sentence)
            let line = LyricLineModel(beginTime: -1, duration: -1, content: "", tones: [])
            song.lines.append(line)
        case "tone":
            push(.tone)
            if let sentence = song.lines.last {
                let beginValue = Double(attributeDict["begin"] ?? "0") ?? 0
                let endValue = Double(attributeDict["end"] ?? "0") ?? 0
                let pitchValue = Float(attributeDict["pitch"] ?? "0") ?? 0
                let begin = Int(beginValue * 1000)
                let end = Int(endValue * 1000)
                let pitch = Double(pitchValue)
                let pronounce = attributeDict["pronounce"] ?? ""
                let langValue = Int(attributeDict["lang"] ?? "") ?? -1
                let lang = Lang(rawValue: langValue)!
                let tone = LyricToneModel(beginTime: begin,
                                          duration: end - begin,
                                          word: "",
                                          pitch: pitch,
                                          lang: lang,
                                          pronounce: pronounce)
                sentence.tones.append(tone)
            }
        case "word":
            push(.word)
        case "overlap":
            push(.overlap)
            let beginValue = Double(attributeDict["begin"] ?? "0") ?? 0
            let endValue = Double(attributeDict["end"] ?? "0") ?? 0
            let begin = Int(beginValue * 1000)
            let end = Int(endValue * 1000)
            let pitch: Double = 0
            let pronounce = ""
            let langValue = Int(attributeDict["lang"] ?? "") ?? -1
            let lang = Lang(rawValue: langValue)!
            let tone = LyricToneModel(beginTime: begin,
                                      duration: end - begin,
                                      word: "",
                                      pitch: pitch,
                                      lang: lang,
                                      pronounce: pronounce)
            let line = LyricLineModel(beginTime: 0, duration: 0, content: "", tones: [tone])
            song.lines.append(line)
        default:
            break
        }
    }
    
    func parser(_: XMLParser, foundCharacters string: String) {
        if let last = parserTypes.last {
            switch last {
            case .name:
                song.name = string
            case .singer:
                song.singer = string
            case .type:
                if let value = Int(string) {
                    song.type = MusicType(rawValue: value) ?? .fast
                }
                else {
                    song.type = .fast
                }
            case .word, .overlap:
                if let tone = song.lines.last?.tones.last {
                    tone.word = tone.word + string
                    if tone.lang == .unknow { /** 补偿语言 **/
                        do {
                            let regular = try NSRegularExpression(pattern: "[a-zA-Z]", options: .caseInsensitive)
                            let count = regular.numberOfMatches(in: tone.word, options: .anchored, range: NSRange(location: 0, length: tone.word.count))
                            if count > 0 {
                                tone.lang = .en
                            } else {
                                tone.lang = .zh
                            }
                        } catch {
                            tone.lang = .en
                        }
                    }
                }
            default:
                break
            }
        }
    }
    
    func parser(_: XMLParser,
                didEndElement elementName: String,
                namespaceURI _: String?,
                qualifiedName _: String?) {
        switch elementName {
        case "general":
            pop(equal: .general)
        case "name":
            pop(equal: .name)
        case "singer":
            pop(equal: .singer)
        case "type":
            pop(equal: .type)
        case "sentence":
            pop(equal: .sentence)
        case "tone":
            pop(equal: .tone)
        case "word":
            pop(equal: .word)
        case "overlap":
            pop(equal: .overlap)
        default:
            break
        }
    }
}

private enum ParserType {
    case general
    case name
    case singer
    case type
    case sentence
    case tone
    case word
    case overlap
}
