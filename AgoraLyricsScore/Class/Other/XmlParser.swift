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
    fileprivate var parseFail = false
    
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
        
        return process()
    }
    
    private func process() -> LyricModel? {
        if song.lines.count == 0 {
            let text = "data error. song.lines: \(song.lines)"
            Log.error(error: text, tag: logTag)
            return nil
        }
        var hasPitch = false
        var preludeEndPosition: UInt = 0
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
                if preludeEndPosition == 0 {
                    preludeEndPosition = tone.beginTime
                }
                content += tone.word
            }
            
            guard let lineBeginTime = line.tones.first?.beginTime,
                  let lastToneDurationInLine = line.tones.last?.duration,
                  let lastToneBeginTineInLine = line.tones.last?.beginTime else {
                let text = "data error. lines is empty"
                Log.error(error: text, tag: logTag)
                return nil
            }
            
            let lineEndTime = lastToneDurationInLine + lastToneBeginTineInLine
            
            if lineEndTime < lineBeginTime {
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
        guard !parseFail else {
            return
        }
        switch elementName {
        case "song":
            song = LyricModel()
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
            let line = LyricLineModel(beginTime: 0, duration: 0, content: "", tones: [])
            song.lines.append(line)
        case "tone":
            push(.tone)
            if let sentence = song.lines.last {
                let beginValue = Double(attributeDict["begin"] ?? "0") ?? 0
                let endValue = Double(attributeDict["end"] ?? "0") ?? 0
                let pitchValue = Float(attributeDict["pitch"] ?? "0") ?? 0
                let begin = UInt(beginValue * 1000)
                var end = UInt(endValue * 1000)
                let pitch = Double(pitchValue)
                let pronounce = attributeDict["pronounce"] ?? ""
                let langValue = Int(attributeDict["lang"] ?? "") ?? -1
                let lang = Lang(rawValue: langValue)!
                if begin > end {
                    Log.errorText(text: "begin is gater than end, begin: \(begin) end: \(end)", tag: logTag)
                    song = nil
                    parseFail = true
                    return
                }
                let duration: UInt = end - begin
                let tone = LyricToneModel(beginTime: begin,
                                          duration: duration,
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
            let begin = UInt(beginValue * 1000)
            let end = UInt(endValue * 1000)
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
                break
            case .word, .overlap:
                if let tone = song.lines.last?.tones.last {
                    tone.word = tone.word + string
                    if tone.lang == .unknown { /** 补偿语言 **/
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
