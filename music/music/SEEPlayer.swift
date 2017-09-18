//
//  SEEPlayer.swift
//  music
//
//  Created by 三只鸟 on 2017/9/18.
//  Copyright © 2017年 三只鸟. All rights reserved.
//

import UIKit
import AVFoundation

class SEEPlayerTask: NSObject {
    
}

class SEEPlayer: NSObject,AVAssetResourceLoaderDelegate {

    /// avplayer
    lazy private var player: AVPlayer = {
        assert(self.targetURL != nil, "URL is empty")
        //创建item
        let item: AVPlayerItem = AVPlayerItem(asset: self.videoURLAsset, automaticallyLoadedAssetKeys: nil)
        //监听状态  当状态为准备播放时开始播放   否则停止播放
        item.addObserver(self, forKeyPath: #keyPath(AVPlayerItem.status), options: .new, context: nil)
        //监听加载range  加载进度条
        item.addObserver(self, forKeyPath: #keyPath(AVPlayerItem.loadedTimeRanges), options: .new, context: nil)
        //监听缓冲区状态  如果缓冲区为空则需要等待一段时间后再播放  防止进度条走而视频不播放
        item.addObserver(self, forKeyPath: #keyPath(AVPlayerItem.playbackBufferEmpty), options: .new, context: nil)
        //创建player
        let player: AVPlayer = AVPlayer(playerItem: item)
        return player
    }()
    
    /// 播放目标URL
    private var targetURL: URL?
    
    /// asset
    lazy private var videoURLAsset: AVURLAsset = {
        assert(self.targetURL != nil, "URL is empty")
        let urlAsset: AVURLAsset = AVURLAsset(url: self.targetURL!)
        //设置loader代理  将数据的下载操作交给代理
        urlAsset.resourceLoader.setDelegate(self, queue: DispatchQueue.main)
        return urlAsset
    }()
    
    /// 负责下载文件的task
    private var videoTask: URLSessionDataTask?
    
    
    
    public func play(_ url: URL) {
        targetURL = url
        let _ = player
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        guard let _ = keyPath else {
            return;
        }
        //状态改变
        if keyPath == #keyPath(AVPlayerItem.status) {
            let status: AVPlayerItemStatus
            
            // Get the status change from the change dictionary
            if let statusNumber = change?[.newKey] as? NSNumber {
                status = AVPlayerItemStatus(rawValue: statusNumber.intValue)!
            } else {
                status = .unknown
            }
            
            if status == .readyToPlay {
                player.play()
            }
            else {
                player.pause()
            }
        }
        
        //数据缓冲区变化
        if keyPath == #keyPath(AVPlayerItem.playbackBufferEmpty) {
            
        }
        
        //加载数据量变化
        if keyPath == #keyPath(AVPlayerItem.loadedTimeRanges) {
            
        }
    }
    
    //MARK - AVAssetResourceLoaderDelegate
    func resourceLoader(_ resourceLoader: AVAssetResourceLoader, shouldWaitForLoadingOfRequestedResource loadingRequest: AVAssetResourceLoadingRequest) -> Bool {
        
        return true
    }
    
}
