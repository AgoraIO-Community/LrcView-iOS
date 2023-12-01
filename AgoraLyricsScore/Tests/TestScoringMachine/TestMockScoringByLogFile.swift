//
//  TestMockScoringByLogFile.swift
//  AgoraLyricsScore-Unit-Tests
//
//  Created by ZYP on 2023/11/8.
//

import XCTest
@testable import AgoraLyricsScore

final class TestMockScoringByLogFile: XCTestCase {
    struct Item {
        let progress: UInt
        let pitch: Double?
    }
    var vm: ScoringMachine!
    var items1 = [Item]()
    var items2 = [Item]()
    
    override func setUpWithError() throws {
        Log.setLoggers(loggers: [ConsoleLogger()])
        readFromFile(fileName: "程紫薇-十年-稻香")
    }
    
    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() throws {
        /// 十年
        goTest(xmlFileName: "745012-new", items: items1)
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
}

extension TestMockScoringByLogFile {
    func readFromFile(fileName: String) {
        let name = "TestLogFile/\(fileName).txt"
        let fileUrl = URL(fileURLWithPath: Bundle.current.path(forResource: name, ofType:nil)!)
        let fileData = try! Data(contentsOf: fileUrl)
        let string = String(data: fileData, encoding: .utf8)!
        let array = string.split(separator: "\n").map({ String($0) })
        
        
        var start = false
        var lastProgress: UInt?
        var result1 = [Item]()
        var result2 = [Item]()
        var currentResult = [Item]()
        for str in array {
            if str.contains("[ALS][I][KaraokeView]: setLyricData") {
                start = !start
                lastProgress = nil
                if !currentResult.isEmpty {
                    result1 = currentResult
                    currentResult = [Item]()
                }
                continue
            }
            if !start { continue }
            
            if str.contains("[ALS][D][ScoringMachine]: progress: ") {
                let strVal = String(str.split(separator: " ").last!)
                let progress = UInt(strVal)!
//                print("\(progress)")
                lastProgress = progress
                if (progress == 18770) {
//                    print("")
                }
                continue
            }
            
            if str.contains("[ALS][D][ScoringMachine]: pitch:") {
                if (lastProgress == nil) {
                    fatalError("log err ??")
                }
                
                if #available(iOS 16.0, *) {
                    let strVal = String(str.split(separator: "pitch: ").last!.split(separator: " after: ").first!)
                    let pitch = Double(strVal)!
                    let item = Item(progress: lastProgress!, pitch: pitch)
                    currentResult.append(item)
                } else {
                    fatalError("#available not 16")
                }
            }
        }
        result2 = currentResult
        
        items1 = result1
        items2 = result2
    }
    
    func goTest(xmlFileName: String, items: [Item]) {
        vm = ScoringMachine()
        let url = URL(fileURLWithPath: Bundle.current.path(forResource: xmlFileName, ofType: "xml")!)
        let data = try! Data(contentsOf: url)
        guard let model = KaraokeView.parseLyricData(data: data) else {
            XCTFail()
            return
        }
        
        vm.delegate = self
        vm.setLyricData(data: model)
        
        for item in items {
            vm.setProgress(progress: Int(item.progress))
            vm.setPitch(pitch: item.pitch)
            usleep(15)
        }
        vm.setProgress(progress: 186022 + 1)
        
    }
}

extension TestMockScoringByLogFile: ScoringMachineDelegate {
    func sizeOfCanvasView(_ scoringMachine: ScoringMachine) -> CGSize {
        return .init(width: 380, height: 100)
    }
    
    func scoringMachine(_ scoringMachine: ScoringMachine, didUpdateDraw standardInfos: [ScoringMachine.DrawInfo], highlightInfos: [ScoringMachine.DrawInfo]) {
        
    }
    
    func scoringMachine(_ scoringMachine: ScoringMachine, didUpdateCursor centerY: CGFloat, showAnimation: Bool, debugInfo: ScoringMachine.DebugInfo) {
        
    }
   
    func scoringMachine(_ scoringMachine: ScoringMachine,
                        didFinishLineWith model: LyricLineModel,
                        score: Int,
                        cumulativeScore: Int,
                        lineIndex: Int,
                        lineCount: Int) {
        print("didFinishLineWith score[\(lineIndex)]: \(score) \(model.content)")
    }
}
