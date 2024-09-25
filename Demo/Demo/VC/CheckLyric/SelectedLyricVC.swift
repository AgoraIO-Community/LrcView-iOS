//
//  SelectedLyricVC.swift
//  Demo
//
//  Created by ZYP on 2024/5/22.
//

import UIKit
import AgoraRtcKit
import AgoraLyricsScore

class SelectedLyricVC: UIViewController {
    private let mccManager = MccManagerEx()
    let textField = UITextField()
    let confirmButton = UIButton()
    let logTag = "SelectedLyricVC"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        commonInit()
    }
    
    private func setupUI() {
        title = "init..."
        view.backgroundColor = .white
        textField.text = "\(32182792)"
        textField.placeholder = "请输入歌曲id"
        textField.borderStyle = .roundedRect
        view.addSubview(textField)
        textField.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            textField.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 50),
            textField.leftAnchor.constraint(equalTo: view.leftAnchor),
            textField.rightAnchor.constraint(equalTo: view.rightAnchor)
        ])
        
        confirmButton.isEnabled = false
        confirmButton.setTitle("确定", for: .normal)
        confirmButton.setTitleColor(.white, for: .normal)
        confirmButton.setTitleColor(.gray, for: .disabled)
        confirmButton.backgroundColor = .blue
        confirmButton.addTarget(self, action: #selector(confirmButtonClicked), for: .touchUpInside)
        view.addSubview(confirmButton)
        confirmButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            confirmButton.topAnchor.constraint(equalTo: textField.bottomAnchor, constant: 20),
            confirmButton.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }
    
    private func commonInit() {
        Log.info(text: "commonInit", tag: logTag)
        mccManager.delegate = self
        if let token = Config.token, let userId = Config.userId {
            mccManager.initEngine()
            mccManager.joinChannel()
            mccManager.initMCC(pid: Config.pid,
                               pKey: Config.pKey,
                               token: token,
                               userId: userId)
        }
        else {
            AccessProvider.fetchAccessData(url: Config.accessUrl) { [weak self](userId, token, errorMsg) in
                guard let self = self else { return }
                if let errorMsg = errorMsg  {
                    Log.errorText(text: errorMsg, tag: logTag)
                    showAlertVC()
                    return
                }
                mccManager.initEngine()
                mccManager.joinChannel()
                self.mccManager.initMCC(pid: Config.pid,
                                        pKey: Config.pKey,
                                        token: token,
                                        userId: userId)
            }
        }
        
        confirmButton.isEnabled = true
        title = "init ok"
    }
    
    private func showAlertVC() {
        let alertVC = UIAlertController(title: "获取权限失败",
                                        message: "请检查网络连接",
                                        preferredStyle: .alert)
        let action = UIAlertAction(title: "确定",
                                   style: .default,
                                   handler: { [weak self] _ in
            self?.navigationController?.popViewController(animated: true)
        })
        alertVC.addAction(action)
        present(alertVC, animated: true, completion: nil)
    }
    
    @objc func confirmButtonClicked() {
        guard let songId = textField.text else {
            return
        }
        title = "loading"
        mccManager.preload(songCode: songId)
    }
}
// MARK: - RTCManagerDelegate
extension SelectedLyricVC: MccManagerExDelegate {
    func onPreloadMusic(_ manager: MccManagerEx,
                        songId: Int,
                        percent: Int,
                        lyricData: Data,
                        pitchData: Data,
                        lyricOffset: Int,
                        songOffsetBegin: Int,
                        errorMsg: String?) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            title = "load ok"
            let vc = CheckLyricVC(krcFileData: lyricData,
                                  pitchFileData: pitchData,
                                  songId: songId,
                                  lyricOffset: lyricOffset)
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    func onLyricResult(url: String) {}
    func onMccExScoreStart(_ manager: MccManagerEx) {}
    func onOpenMusic(_ manager: MccManagerEx) {}
    func onPitch(_ manager: MccManagerEx, rawScoreData: AgoraRawScoreData) {}
    func onLineScore(_ songCode: Int, lineScoreData: AgoraLineScoreData) {}
}

