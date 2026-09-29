import Foundation
import CoreFoundation

final class TMEToneParser {
    private struct Note {
        let start: UInt
        let duration: UInt
        let pitch: Double
    }

    func parse(tone: Data, lyric: Data) -> LyricModel? {
        guard let rows = try? JSONSerialization.jsonObject(with: tone) as? [Any],
              let lyricText = String(data: lyric, encoding: .utf8) else {
            return nil
        }

        let (name, singer, lines) = parseLyrics(lyricText)
        guard !lines.isEmpty else { return nil }

        for row in rows {
            guard let note = parseNote(row),
                  let index = lines.indices.last(where: { lines[$0].beginTime <= note.start }) else {
                continue
            }

            let line = lines[index]
            guard !isCredit(line.content, name: name, singer: singer) else { continue }
            let end = note.start + note.duration
            let lineEnd = index + 1 < lines.count ? lines[index + 1].beginTime : end
            let duration = min(end, lineEnd) - note.start
            guard duration > 0 else { continue }

            line.tones.append(LyricToneModel(beginTime: note.start,
                                             duration: duration,
                                             word: "",
                                             pitch: note.pitch,
                                             lang: .unknown,
                                             pronounce: ""))
        }

        for line in lines {
            line.tones.sort { $0.beginTime < $1.beginTime }
        }
        let scoringLines = lines.filter { !$0.tones.isEmpty }
        guard let first = scoringLines.first else { return nil }

        let last = lines[lines.count - 1]
        if let toneEnd = last.tones.map(\.endTime).max() {
            last.duration = toneEnd - last.beginTime
        }
        let model = LyricModel(name: name,
                               singer: singer,
                               lyricsType: .lrc,
                               lines: lines,
                               preludeEndPosition: first.beginTime,
                               duration: last.endTime,
                               hasPitch: true)
        model.scoringLines = scoringLines
        return model
    }

    private func parseNote(_ row: Any) -> Note? {
        guard let item = row as? [String: Any],
              let start = numberString(item["st"]).flatMap(UInt.init),
              let duration = numberString(item["d"]).flatMap(UInt.init),
              duration > 0,
              let tone = numberString(item["p"]).flatMap(Double.init),
              tone.isFinite, tone >= 32 else { return nil }

        let (end, overflow) = start.addingReportingOverflow(duration)
        guard !overflow, end <= Int.max else { return nil }
        let pitch = 55 * (pow(2, (tone - 32) / 12) - 1e-6)
        guard pitch.isFinite, pitch > 0 else { return nil }
        return Note(start: start, duration: duration, pitch: pitch)
    }

    private func numberString(_ value: Any?) -> String? {
        if let text = value as? String { return text }
        guard let number = value as? NSNumber,
              CFGetTypeID(number) != CFBooleanGetTypeID() else { return nil }
        return number.stringValue
    }

    private func parseLyrics(_ text: String) -> (String, String, [LyricLineModel]) {
        guard let expression = try? NSRegularExpression(pattern: "^\\[(\\d+):(\\d{2})\\.(\\d{1,3})\\](.*)$") else {
            return ("", "", [])
        }
        var name = ""
        var singer = ""
        var lines = [LyricLineModel]()

        for rawLine in text.components(separatedBy: .newlines) {
            let line = rawLine.trimmingCharacters(in: .newlines)
            if line.hasPrefix("[ti:"), line.hasSuffix("]") {
                name = String(line.dropFirst(4).dropLast())
                continue
            }
            if line.hasPrefix("[ar:"), line.hasSuffix("]") {
                singer = String(line.dropFirst(4).dropLast())
                continue
            }
            let nsLine = line as NSString
            guard let match = expression.firstMatch(in: line,
                                                    range: NSRange(location: 0, length: nsLine.length)),
                  let minutes = UInt(nsLine.substring(with: match.range(at: 1))),
                  let seconds = UInt(nsLine.substring(with: match.range(at: 2))),
                  seconds < 60 else { continue }

            let fractionText = nsLine.substring(with: match.range(at: 3))
            guard let fraction = UInt(fractionText) else { continue }
            let (minuteMs, minuteOverflow) = minutes.multipliedReportingOverflow(by: 60_000)
            let (secondMs, secondOverflow) = seconds.multipliedReportingOverflow(by: 1_000)
            let fractionalMs = fraction * (fractionText.count == 1 ? 100 : fractionText.count == 2 ? 10 : 1)
            let (wholeMs, wholeOverflow) = minuteMs.addingReportingOverflow(secondMs)
            let (beginTime, timeOverflow) = wholeMs.addingReportingOverflow(fractionalMs)
            guard !minuteOverflow, !secondOverflow, !wholeOverflow, !timeOverflow,
                  beginTime <= Int.max else { continue }

            lines.append(LyricLineModel(beginTime: beginTime,
                                        duration: 0,
                                        content: nsLine.substring(with: match.range(at: 4)),
                                        tones: []))
        }

        lines.sort { $0.beginTime < $1.beginTime }
        for index in 0..<(max(lines.count - 1, 0)) {
            let start = lines[index].beginTime
            let next = lines[index + 1].beginTime
            lines[index].duration = next > start ? next - start - 1 : 0
        }
        return (name, singer, lines)
    }

    private func isCredit(_ content: String, name: String, singer: String) -> Bool {
        let text = content.trimmingCharacters(in: .whitespacesAndNewlines)
        if text.isEmpty { return true }
        if !name.isEmpty, (text == name ||
                           (text.hasPrefix(name + " - ") && !singer.isEmpty && text.contains(singer))) {
            return true
        }
        return ["词：", "曲：", "作词：", "作曲：", "编曲：",
                "词:", "曲:", "作词:", "作曲:", "编曲:"].contains { text.hasPrefix($0) }
    }
}
