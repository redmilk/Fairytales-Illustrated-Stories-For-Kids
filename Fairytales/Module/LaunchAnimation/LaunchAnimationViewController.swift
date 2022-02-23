//
//  
//  LaunchAnimationViewController.swift
//  Fairytales
//
//  Created by Danyl Timofeyev on 06.02.2022.
//
//

import UIKit
import Combine
import AVFoundation
import AVKit

final class VideoPlayerController: AVPlayerViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        videoGravity = .resizeAspectFill
    }
}

// MARK: - LaunchAnimationViewController

final class LaunchAnimationViewController: BaseViewController {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var animatableView: UIView!
    private var player: AVQueuePlayer?
    private var playerLooper: AVPlayerLooper?
    private let playerView = PlayerView()

    let emitter = CartoonStarsEmitter()
    
    init(coordinator: Coordinatable) {
        super.init(coordinator: coordinator, type: Self.self, initialState: BaseState())
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    deinit {
        Logger.log(String(describing: self), type: .deinited)
    }
    override func applyStyling() {
        view.insertSubview(emitter, at: 1)
    }
    override func configure() {
        //setupVideoPlayer(videoName: "video-iphone")
        
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
//        animatableView.clipsToBounds = true
//        view.subviews.first?.bringSubviewToFront(imageView)
//        emitter.center = view.center
        
//        player?.play()
//        playerView.isHidden = false
//        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
//            (self.coordinator as? LaunchAnimationCoordinator)?.startAppFlow()
//        }
        guard let path = Bundle.main.path(forResource: UIDevice.current.isIPad ? "video-ipad" : "video-iphone", ofType:"mp4") else {
            return debugPrint("video.m4v not found")
        }
        let player = AVPlayer(url: URL(fileURLWithPath: path))
        let playerController = VideoPlayerController()
        playerController.view.backgroundColor = view.backgroundColor
        playerController.showsPlaybackControls = false
        playerController.view.isUserInteractionEnabled = false
        playerController.player = player
        present(playerController, animated: false) { [weak player] in
            player?.play()
            UIView.animate(withDuration: 1.0, delay: 3.5, options: [], animations: { [weak playerController] in
                playerController?.view.alpha = 0.1
            }, completion: { [weak playerController, weak self] _ in
                playerController?.dismiss(animated: false, completion: nil)
                (self?.coordinator as? LaunchAnimationCoordinator)?.startAppFlow()
            })
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
//        animatableView.layer.cornerRadius = animatableView.bounds.height / 2
//
//        let finalTransform = CGAffineTransform.identity.scaledBy(x: 10, y: 10)
//        UIView.animate(withDuration: 1, delay: 0.0, options: [], animations: {
//            self.animatableView.transform = finalTransform
//            self.emitter.frame = self.animatableView.frame
//            self.emitter.center = self.animatableView.center
//        }, completion: { [weak self] _ in
//            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
//                (self?.coordinator as? LaunchAnimationCoordinator)?.startAppFlow()
//            }
//        })
    }
    
    private func setupVideoPlayer(videoName: String) {
        guard let videoUrl = Bundle.main.url(forResource: videoName, withExtension: "mp4") else { return }

        let asset = AVAsset(url: videoUrl)
        let playerItem = AVPlayerItem(asset: asset)
        player = AVQueuePlayer(playerItem: playerItem)
        player!.isMuted = false
        playerLooper = AVPlayerLooper(player: player!, templateItem: playerItem)
        view.addSubview(playerView)
        playerView.frame = .zero
        playerView.player = player
        playerView.layer.opacity = 0
        playerView.subviews.forEach { $0.isHidden = true }
        playerView.layer.sublayers?.forEach { $0.opacity = 0}
    }
}
