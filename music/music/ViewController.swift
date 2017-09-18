//
//  ViewController.swift
//  music
//
//  Created by 三只鸟 on 2017/9/18.
//  Copyright © 2017年 三只鸟. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    var player = SEEPlayer()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        player.play(URL(string: "http://dl.stream.qqmusic.qq.com/C400002FHFPu0ii4cV.m4a?vkey=CC2274EE2679336DE105603131F3FDA28DFBB7E3345BCBB0CC73D1BD1FF878777C776B77F83300F19A69CB09114E8FCB8CD61EA7D285D199&guid=8887448240&uin=436005247&fromtag=66")!)
        
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

