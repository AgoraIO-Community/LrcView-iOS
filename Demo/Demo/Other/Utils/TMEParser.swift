import Foundation

enum TMEParseError: Error, Equatable {
    case invalidRequest
    case unsupportedAction(String)
    case httpStatus(Int)
    case apiError(Int, String?)
    case invalidResponse
}

protocol TMEParserDelegate: AnyObject {
    func onSongs(_ requestId: String, result: TMESongsResult)
    func onSearchSongs(_ requestId: String, result: TMESearchSongsResult)
    func onSongInfo(_ requestId: String, result: TMESongInfoResult)
    func onSongUrl(_ requestId: String, result: TMESongUrlResult)
    func onSonglistPage(_ requestId: String, result: TMEPageResult)
    func onSonglistDetail(_ requestId: String, result: TMEDetailResult)
    func onRanklistPage(_ requestId: String, result: TMEPageResult)
    func onRanklistDetail(_ requestId: String, result: TMEDetailResult)
    func onParseError(_ requestId: String, jsonOption: String, responseBody: String,
                      error: TMEParseError)
}

extension TMEParserDelegate {
    func onSongs(_ requestId: String, result: TMESongsResult) {}
    func onSearchSongs(_ requestId: String, result: TMESearchSongsResult) {}
    func onSongInfo(_ requestId: String, result: TMESongInfoResult) {}
    func onSongUrl(_ requestId: String, result: TMESongUrlResult) {}
    func onSonglistPage(_ requestId: String, result: TMEPageResult) {}
    func onSonglistDetail(_ requestId: String, result: TMEDetailResult) {}
    func onRanklistPage(_ requestId: String, result: TMEPageResult) {}
    func onRanklistDetail(_ requestId: String, result: TMEDetailResult) {}
}

private struct TMERequestOption: Decodable {
    let vendorId: Int
    let actionType: String
}

private struct TMEAPIStatus: Decodable {
    let code: Int
    let msg: String?
}

private enum TMEParsedResponse {
    case songs(TMESongsResult)
    case searchSongs(TMESearchSongsResult)
    case songInfo(TMESongInfoResult)
    case songUrl(TMESongUrlResult)
    case songlistPage(TMEPageResult)
    case songlistDetail(TMEDetailResult)
    case ranklistPage(TMEPageResult)
    case ranklistDetail(TMEDetailResult)
}

final class TMEParser {
    weak var delegate: TMEParserDelegate?
    private let queue = DispatchQueue(label: "com.klyrics.tme.parser", qos: .userInitiated)

    func parse(requestId: String, jsonOption: String, httpCode: Int, responseBody: String) {
        queue.async { [weak self] in
            let parsed = Self.decode(jsonOption: jsonOption, httpCode: httpCode,
                                     responseBody: responseBody)
            DispatchQueue.main.async { [weak self] in
                guard let delegate = self?.delegate else { return }
                switch parsed {
                case .failure(let error):
                    delegate.onParseError(requestId, jsonOption: jsonOption,
                                          responseBody: responseBody, error: error)
                case .success(let value):
                    switch value {
                    case .songs(let result): delegate.onSongs(requestId, result: result)
                    case .searchSongs(let result): delegate.onSearchSongs(requestId, result: result)
                    case .songInfo(let result): delegate.onSongInfo(requestId, result: result)
                    case .songUrl(let result): delegate.onSongUrl(requestId, result: result)
                    case .songlistPage(let result): delegate.onSonglistPage(requestId, result: result)
                    case .songlistDetail(let result): delegate.onSonglistDetail(requestId, result: result)
                    case .ranklistPage(let result): delegate.onRanklistPage(requestId, result: result)
                    case .ranklistDetail(let result): delegate.onRanklistDetail(requestId, result: result)
                    }
                }
            }
        }
    }

    private static func body<T: Decodable>(_ type: T.Type, response: String) throws -> T {
        let source = Data(response.utf8)
        guard let status = try? JSONDecoder().decode(TMEAPIStatus.self, from: source) else {
            throw TMEParseError.invalidResponse
        }
        guard status.code == 0 else {
            throw TMEParseError.apiError(status.code, status.msg)
        }
        guard let envelope = try? JSONDecoder().decode(TMEAPIEnvelope<T>.self, from: source),
              let value = envelope.data else {
            throw TMEParseError.invalidResponse
        }
        return value
    }

    private static func decode(jsonOption: String, httpCode: Int,
                               responseBody: String) -> Result<TMEParsedResponse, TMEParseError> {
        guard let request = try? JSONDecoder().decode(TMERequestOption.self,
                                                       from: Data(jsonOption.utf8)),
              request.vendorId == 2 else { return .failure(.invalidRequest) }
        let action = request.actionType
        let actions = ["songs", "search-song", "song-info", "song-url", "songlist-page",
                       "songlist-detail", "ranklist-page", "ranklist-detail"]
        guard actions.contains(action) else { return .failure(.unsupportedAction(action)) }
        guard (200..<300).contains(httpCode) else { return .failure(.httpStatus(httpCode)) }
        do {
            switch action {
            case "songs": return .success(.songs(try body(TMESongsResult.self, response: responseBody)))
            case "search-song": return .success(.searchSongs(try body(TMESearchSongsResult.self, response: responseBody)))
            case "song-info": return .success(.songInfo(try body(TMESongInfoResult.self, response: responseBody)))
            case "song-url": return .success(.songUrl(try body(TMESongUrlResult.self, response: responseBody)))
            case "songlist-page": return .success(.songlistPage(try body(TMEPageResult.self, response: responseBody)))
            case "songlist-detail": return .success(.songlistDetail(try body(TMEDetailResult.self, response: responseBody)))
            case "ranklist-page": return .success(.ranklistPage(try body(TMEPageResult.self, response: responseBody)))
            case "ranklist-detail": return .success(.ranklistDetail(try body(TMEDetailResult.self, response: responseBody)))
            default: return .failure(.unsupportedAction(action))
            }
        } catch let error as TMEParseError {
            return .failure(error)
        } catch {
            return .failure(.invalidResponse)
        }
    }
}
