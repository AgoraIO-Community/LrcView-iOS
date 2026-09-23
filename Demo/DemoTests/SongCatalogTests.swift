import XCTest
@testable import Demo

final class SongCatalogTests: XCTestCase {
    func testCatalogContainsTheApprovedFiveSongsInOrder() {
        XCTAssertEqual(
            SongCatalog.songs.map(\.name),
            ["十年", "爱情转移", "说爱你", "江南", "容易受伤的女人"]
        )
    }

    func testNextSongWrapsToTheBeginning() {
        XCTAssertEqual(SongCatalog.next(after: SongCatalog.songs[4]), SongCatalog.songs[0])
    }
}
