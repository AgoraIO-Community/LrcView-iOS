//
//  Extensions.swift
//  AgoraLyricsScore
//
//  Created by ZYP on 2022/12/21.
//

import Foundation

class AgoraLyricsScore {}

extension String {
    // 字符串截取
    func textSubstring(startIndex: Int, length: Int) -> String {
        let startIndex = index(self.startIndex, offsetBy: startIndex)
        let endIndex = index(startIndex, offsetBy: length)
        let subvalues = self[startIndex ..< endIndex]
        return String(subvalues)
    }
}

extension LyricLineModel {
    var endTime: Int {
        beginTime + duration
    }
}

extension LyricToneModel {
    var endTime: Int {
        beginTime + duration
    }
}

extension Bundle {
    static var currentBundle: Bundle {
        let bundle = Bundle(for: AgoraLyricsScore.self)
        let path = bundle.path(forResource: "AgoraLyricsScoreBundle", ofType: "bundle")
        if path == nil {
            Log.error(error: "bundle not found path", tag: "Bundle")
        }
        let current = Bundle(path: path!)
        if current == nil {
            Log.error(error: "bundle not found path: \(path!)", tag: "Bundle")
        }
        return current!
    }
    
    func image(name: String) -> UIImage? {
        return UIImage(named: name, in: self, compatibleWith: nil)
    }
}

extension UIColor{
    class func colorWithHex(hexStr:String) -> UIColor{
        return UIColor.colorWithHex(hexStr : hexStr, alpha:1)
    }
    
    class func colorWithHex(hexStr:String, alpha:Float) -> UIColor{
        
        var cStr = hexStr.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines).uppercased() as NSString;
        
        if(cStr.length < 6){
            return UIColor.clear;
        }
        
        if(cStr.hasPrefix("0x")){
            cStr = cStr.substring(from: 2) as NSString
        }
        
        if(cStr.hasPrefix("#")){
            cStr = cStr.substring(from: 1) as NSString
        }
        
        if(cStr.length != 6){
            return UIColor.clear
        }
        
        let rStr = (cStr as NSString).substring(to: 2)
        let gStr = ((cStr as NSString).substring(from: 2) as NSString).substring(to: 2)
        let bStr = ((cStr as NSString).substring(from: 4) as NSString).substring(to: 2)
        
        var r: UInt32 = 0x0
        var g: UInt32 = 0x0
        var b: UInt32 = 0x0
        
        Scanner.init(string: rStr).scanHexInt32(&r)
        Scanner.init(string: gStr).scanHexInt32(&g)
        Scanner.init(string: bStr).scanHexInt32(&b)
        
        return UIColor.init(red: CGFloat(r)/255.0, green: CGFloat(g)/255.0, blue: CGFloat(b)/255.0, alpha: CGFloat(alpha));
        
    }
}

extension Date {
    /// 获取当前 秒级 时间戳 - 10位
    var timeStamp: Int {
        let timeInterval = timeIntervalSince1970
        let timeStamp = Int(timeInterval)
        return timeStamp
    }
    
    /// 获取当前 毫秒级 时间戳 - 13位
    var milliStamp: CLongLong {
        let timeInterval = timeIntervalSince1970
        let millisecond = CLongLong(round(timeInterval * 1000))
        return millisecond
    }
}

extension Double {
    /// 保留2位小数
    var keep2: Double {
        return Double(Darwin.round(self * 100)/100)
    }
}
