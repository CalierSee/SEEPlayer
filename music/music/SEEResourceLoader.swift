//
//  SEEResourceLoader.swift
//  music
//
//  Created by 三只鸟 on 2017/9/19.
//  Copyright © 2017年 三只鸟. All rights reserved.
//

import UIKit
import AVFoundation
class SEEResourceLoader: NSObject,AVAssetResourceLoaderDelegate {
    
    /// 下载的链接
    var url: URL!

    convenience init(with url: URL) {
        self.init()
        self.url = url
    }
    
    //MARK AVAssetResourceLoaderDelegate
    func resourceLoader(_ resourceLoader: AVAssetResourceLoader, shouldWaitForLoadingOfRequestedResource loadingRequest: AVAssetResourceLoadingRequest) -> Bool {
        
        return true
    }
    
}
