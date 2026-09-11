import Foundation

typealias DownloadProgressClosure = ((_ progress: Float) -> Void)
typealias DownloadCompletionClosure = ((_ filePath: String) -> Void)
typealias DownloadFailClosure = ((_ error: DownloadError) -> Void)

enum DownloadErrorDomainType: Int {
    case repeatDownloading = 1
}

final class DownloadError: Error {
    init() {}

    init(domainType: DownloadErrorDomainType, code: Int, msg: String) {}
}

class Downloader: NSObject {
    func download(url: URL,
                  progress: @escaping DownloadProgressClosure,
                  completion: @escaping DownloadCompletionClosure,
                  fail: @escaping DownloadFailClosure) {}

    func resetEventCloure() {}
    func cancel() {}
}

final class SafeDictionary<Key: Hashable, Value> {
    private var values = [Key: Value]()

    func getValue(forkey key: Key) -> Value? {
        values[key]
    }

    func set(value: Value, forkey key: Key) {
        values[key] = value
    }

    func removeValue(forkey key: Key) {
        values.removeValue(forKey: key)
    }
}

enum Log {
    static func info(text: String, tag: String = "") {}
    static func errorText(text: String, tag: String = "") {}
    static func debug(text: String, tag: String = "") {}
    static func error(error: String, tag: String = "") {}
}

private final class ImmediateFailureDownloader: Downloader {
    override func download(url: URL,
                           progress: @escaping DownloadProgressClosure,
                           completion: @escaping DownloadCompletionClosure,
                           fail: @escaping DownloadFailClosure) {
        fail(DownloadError())
    }
}

@main
struct DownloaderManagerBehaviorTest {
    static func main() {
        var createdCount = 0
        let manager = DownloaderManager(makeDownloader: {
            createdCount += 1
            return ImmediateFailureDownloader()
        })
        let url = URL(string: "https://example.com/1.zip")!

        manager.download(url: url, progress: { _ in }, completion: { _ in }, fail: { _ in })
        manager.download(url: url, progress: { _ in }, completion: { _ in }, fail: { _ in })

        guard createdCount == 2 else {
            fatalError("failed download must be removed before retry")
        }
        print("DownloaderManager behavior tests passed")
    }
}
