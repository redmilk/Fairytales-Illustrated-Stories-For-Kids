//
//  PlayerView.swift
//  Fairytales
//
//  Created by Danyl Timofeyev on 14.02.2022.
//

import UIKit.UIView
import AVFoundation.AVPlayer

final class PlayerView: UIView {
    var player: AVPlayer? {
        get {
            return playerLayer.player
        }
        set {
            playerLayer.player = newValue
            playerLayer.videoGravity = .resizeAspectFill
        }
    }
    
    var playerLayer: AVPlayerLayer {
        return layer as! AVPlayerLayer
    }
    
    override static var layerClass: AnyClass {
        return AVPlayerLayer.self
    }
}
