//
//  ScoringViewEx+Events.swift
//  AgoraLyricsScore
//
//  Created by ZYP on 2023/1/13.
//

import Foundation

protocol ScoringViewDelegate: NSObjectProtocol {
    /// 更新UI
    func scoringViewShouldUpdateViewLayout(view: ScoringViewEx)
}
