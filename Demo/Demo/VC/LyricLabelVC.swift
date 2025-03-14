//
//  LyricLabelVC.swift
//  Demo
//
//  Created by ZYP on 2023/1/31.
//

import UIKit
import AgoraLyricsScore

class LyricLabelVC: UIViewController {
    let label = UILabel()
    var count = 0
    let string = "一二三四五六七八九十甲乙丙丁appleABCDEFGHIJKLMNOPQRSTUVWXYZ"
    
    /// 正常歌词颜色
    var textNormalColor: UIColor = .gray
    /// 选中的歌词颜色
    var textSelectedColor: UIColor = .white
    /// 高亮的歌词颜色
    var textHighlightedColor: UIColor = .orange
    /// 正常歌词文字大小
    var textNormalFontSize: UIFont = .systemFont(ofSize: 15)
    /// 高亮歌词文字大小
    var textHighlightFontSize: UIFont = .systemFont(ofSize: 18)
    
    let width: CGFloat = 130
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .blue
        
//        label.text = string
//        label.font = textHighlightFontSize
//        label.numberOfLines = 0
//        label.lineBreakMode = .byWordWrapping
//        label.textAlignment = .center
//        label.textColor = textNormalColor
        
//        let paragraphStyle = NSMutableParagraphStyle()
//        paragraphStyle.lineBreakMode = .byWordWrapping
//        paragraphStyle.alignment = .center
//        
//    
//        let attributedString = NSAttributedString(
//            string: string,
//            attributes: [
//                .font: textHighlightFontSize,
//                .foregroundColor: textSelectedColor,
//                .paragraphStyle: paragraphStyle,
//            ]
//        )
//        label.attributedText = attributedString
//    
        view.addSubview(label)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.widthAnchor.constraint(equalToConstant: width).isActive = true
        label.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        label.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        label.sizeToFit()
        
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
//        let lineRects = getLineRects()
//        print("===行位置数组: \(lineRects), count:\(lineRects.count)")
//        
//        // 清除旧标记
//        label.subviews.filter { $0.backgroundColor == .red }.forEach { $0.removeFromSuperview() }
//        label.subviews.filter { $0.backgroundColor == .yellow }.forEach { $0.removeFromSuperview() }
//        
//        // 添加新标记
//        for rect in lineRects {
//            let markView = UIView(frame: rect)
//            markView.backgroundColor = .red.withAlphaComponent(0.3)
//            label.addSubview(markView)
//        }
    }
    
    private func getLineRects() -> [CGRect] {
//        guard let attributedText = label.attributedText else { return [] }
//       
//        
//        let rect = CGRect(origin: .zero, size: CGSize(width: width, height: label.bounds.height))
//        let path = CGPath(rect: rect, transform: nil)
//        let framesetter = CTFramesetterCreateWithAttributedString(attributedText)
//        let frame = CTFramesetterCreateFrame(framesetter, CFRangeMake(0, 0), path, nil)
//        
//        let lines = CTFrameGetLines(frame) as! [CTLine]
//        
//        var lineOrigins = [CGPoint](repeating: .zero, count: lines.count)
//        CTFrameGetLineOrigins(frame, CFRangeMake(0, 0), &lineOrigins)
//        
        var rects = [CGRect]()
//        for (i, line) in lines.enumerated() {
//            var ascent: CGFloat = 0
//            var descent: CGFloat = 0
//            var leading: CGFloat = 0
//            let width = CTLineGetTypographicBounds(line, &ascent, &descent, &leading)
//            
//            // Core Text坐标系转换
//            let transform = CGAffineTransform(scaleX: 1, y: -1).translatedBy(x: 0, y: -1 * (label.bounds.height))
//            var lineRect = CGRect(
//                x: lineOrigins[i].x,
//                y: lineOrigins[i].y - descent,
//                width: CGFloat(width),
//                height: ascent + descent
//            ).applying(transform)
//            
//            let lineRange = CTLineGetStringRange(line)
//            let range = NSRange(location: lineRange.location, length: lineRange.length)
//            let lineString = (attributedText.string as NSString).substring(with: range)
//            print("===lineString:\(lineString)")
//            print("=== y: \(lineOrigins[i].y), descent: \(descent)")
//            // 对齐方式修正
//            switch label.textAlignment {
//            case .center:
//                lineRect.origin.x = (label.bounds.width - lineRect.width) / 2
//            case .right:
//                lineRect.origin.x = label.bounds.width - lineRect.width
//            default:
//                break
//            }
//            
//            
//            rects.append(lineRect)
//        }
        return rects
    }
    
}
