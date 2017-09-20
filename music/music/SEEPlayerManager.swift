//
//  SEEPlayerManager.swift
//  music
//
//  Created by 三只鸟 on 2017/9/19.
//  Copyright © 2017年 三只鸟. All rights reserved.
//

import UIKit
import AVFoundation
class SEEPlayerManager: NSObject {
    //player
    var player: AVPlayer?
    //item
    var playerItem: AVPlayerItem?
    //    /// avplayer
    //    lazy private var player: AVPlayer = {
    //
    //        //创建item
    //        let item: AVPlayerItem = AVPlayerItem(asset: self.videoURLAsset, automaticallyLoadedAssetKeys: nil)
    //        //监听状态  当状态为准备播放时开始播放   否则停止播放
    //        item.addObserver(self, forKeyPath: #keyPath(AVPlayerItem.status), options: .new, context: nil)
    //        //监听加载range  加载进度条
    //        item.addObserver(self, forKeyPath: #keyPath(AVPlayerItem.loadedTimeRanges), options: .new, context: nil)
    //        //监听缓冲区状态  如果缓冲区为空则需要等待一段时间后再播放  防止进度条走而视频不播放
    //        item.addObserver(self, forKeyPath: #keyPath(AVPlayerItem.playbackBufferEmpty), options: .new, context: nil)
    //        //创建player
    //        let player: AVPlayer = AVPlayer(playerItem: item)
    //        player.automaticallyWaitsToMinimizeStalling = false
    //        return player
    //    }()
    
    /// 播放目标URL
    var targetURL: URL?
    /// asset
    var videoURLAsset: AVURLAsset?
    //下载器
    var resourceLoader: SEEResourceLoader?
    
    
    
    
    
    
    public func play(_ url: URL) {
        targetURL = url
        //创建下载器
        resourceLoader = SEEResourceLoader(with: url)
        //创建assets
        videoURLAsset = AVURLAsset(url: url)
        //设置代理
        videoURLAsset?.resourceLoader.setDelegate(resourceLoader, queue: DispatchQueue.main)
        
        //创建item
        playerItem = AVPlayerItem(asset: videoURLAsset!)
        playerItem?.addObserver(self, forKeyPath: #keyPath(AVPlayerItem.status), options: .new, context: nil)
        //监听加载range  加载进度条
        playerItem?.addObserver(self, forKeyPath: #keyPath(AVPlayerItem.loadedTimeRanges), options: .new, context: nil)
        //监听缓冲区状态  如果缓冲区为空则需要等待一段时间后再播放  防止进度条走而视频不播放
        playerItem?.addObserver(self, forKeyPath: #keyPath(AVPlayerItem.playbackBufferEmpty), options: .new, context: nil)
        //创建player
        if let player = self.player {
            player.replaceCurrentItem(with: playerItem)
        }
        else {
            player = AVPlayer(playerItem: playerItem)
        }
        
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
                player?.play()
            }
            else {
                player?.pause()
            }
        }
        
        //数据缓冲区变化
        if keyPath == #keyPath(AVPlayerItem.playbackBufferEmpty) {
            
        }
        
        //加载数据量变化  计算
        if keyPath == #keyPath(AVPlayerItem.loadedTimeRanges) {
            
        }
    }
    
    
    
}

