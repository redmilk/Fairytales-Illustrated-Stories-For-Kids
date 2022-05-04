//
//  
//  OnboardingViewController.swift
//  Fairytales
//
//  Created by Danyl Timofeyev on 14.01.2022.
//
//

import UIKit
import Combine
import AVFoundation
import AVKit

extension OnboardingViewController {
    class State: BaseState {
        override init() { } 
        
        var imageList: [UIImage] = [UIImage(named: "onboarding1")!,
                                    UIImage(named: "onboarding2")!,
                                    UIImage(named: "onboarding3")!,
                                    UIImage(named: "onboarding4")!]
        
        var headingList: [String] = ["Ваш ребенок в главной роли",
                                     "Картинки на каждой странице",
                                     "Возможность чтения оффлайн",
                                     "Обучайтесь и развивайтесь вместе с ребенком"]
        
        var descriptionList: [String] = ["Погружение в сказочный мир позволит легко и безопасно получить новый опыт и знания",
                                         "Яркие иллюстрации формируют вкус и дополняют восприятие сказочных сюжетов",
                                     "Удобно читать в дороге, не отвлекают уведомления и телефон работает дольше",
                                     "Совместное чтение и обсуждение сказок увеличит словарный запас ребенка и усилит его стремление к познанию нового"]

        lazy var currentImage: UIImage = self.imageList[currentImageIndex]
        lazy var currentHeading: String = self.headingList[currentImageIndex]
        lazy var currentDescription: String = self.descriptionList[currentImageIndex]
        var shouldEndOnboarding: Bool = false
        

        var currentImageIndex = 0 {
            didSet {
                guard currentImageIndex >= 0, currentImageIndex < imageList.count else {
                    return shouldEndOnboarding = true
                }
                currentImage = imageList[currentImageIndex]
                currentHeading = headingList[currentImageIndex]
                currentDescription = descriptionList[currentImageIndex]
            }
        }
    }
}

// MARK: - OnboardingViewController

final class OnboardingViewController: BaseViewController {
    
    @IBOutlet weak var pageControl: UIPageControl!
    @IBOutlet weak var image: UIImageView!
    @IBOutlet weak var continueButton: UIButton!
    @IBOutlet weak var skipButton: UIButton!
    @IBOutlet weak var headingLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    
    @IBOutlet weak var descriptionsStackView: UIStackView!
    @IBOutlet weak var contentView: UIView!
    
    private var player: AVQueuePlayer?
    private var playerItem: AVPlayerItem?
    private var playerView: PlayerView?
    private var asset: AVAsset?
    private var playerLooper: AVPlayerLooper?
    
    private var player1: AVQueuePlayer?
    private var playerItem1: AVPlayerItem?
    private var playerView1: PlayerView?
    private var asset1: AVAsset?
    private var playerLooper1: AVPlayerLooper?
    
    private var player2: AVQueuePlayer?
    private var playerItem2: AVPlayerItem?
    private var playerView2: PlayerView?
    private var asset2: AVAsset?
    private var playerLooper2: AVPlayerLooper?
    
    var stateValue: OnboardingViewController.State { state.value as! OnboardingViewController.State }
    
    init(coordinator: OnboardingCoordinator) {
        super.init(coordinator: coordinator, type: Self.self, initialState: State())
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
  
    override func configure() {
        pageControl.preferredIndicatorImage = UIImage(named: "page-control-indicator")!
        pageControl.numberOfPages = 3
        pageControl.currentPage = 0
    }
    override func handleEvents() {
        continueButton.publisher().map { _ in }
        .sink(receiveValue: { [weak self] in
            guard let state = self?.stateValue else { return }
            switch state.currentImageIndex {
            case 0:
                self?.playerView?.isHidden = true
                self?.playerView1?.isHidden = false
                self?.player1?.play()
            case 1:
                self?.playerView1?.isHidden = true
                self?.playerView2?.isHidden = false
                self?.player2?.play()
            default: break
            }
            if state.currentImageIndex == 2 {
                (self?.coordinator as? OnboardingCoordinator)?.displayGenderSettings()
                return
            }
            state.currentImageIndex += 1
            self?.pageControl.currentPage += 1
            self?.state.value = state
        }).store(in: &bag)
        
        skipButton.publisher().map { _ in }
        .sink(receiveValue: { [weak self] in
            guard let state = self?.stateValue else { return }
            state.currentImageIndex -= 1
            self?.pageControl.currentPage -= 1
            self?.state.value = state
        }).store(in: &bag)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupVideoPlayers()
    }
    override func handleState() {
        state.compactMap { $0 as? OnboardingViewController.State }
        .sink(receiveValue: { [weak self] state in
                guard let self = self else { return }
                guard !state.shouldEndOnboarding else {
                    OnboardingManager.shared?.onboardingFinishAction()
                    OnboardingManager.shared = nil
                    return
                }
                self.headingLabel.text = state.currentHeading
                self.descriptionLabel.text = state.currentDescription
        }).store(in: &bag)
    }
    
    private func playVideo() {
        guard let path = Bundle.main.path(forResource: "Onboarding1", ofType:"mp4") else {
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
    
    func startPlayVideo() {
        player?.play()
    }
    
    func pauseVideo() {
        player?.pause()
    }

    private func setupVideoPlayers() {
        guard let videoUrl = Bundle.main.url(forResource: UIDevice.current.isIPad ? "Onboarding3ipad" : "Onboarding3", withExtension: "mp4") else { return }
        asset = AVAsset(url: videoUrl)
        playerItem = AVPlayerItem(asset: asset!)
        player = AVQueuePlayer(playerItem: playerItem)
        player!.isMuted = false
        playerLooper = AVPlayerLooper(player: player!, templateItem: playerItem!)
        playerView = PlayerView()
        playerView?.translatesAutoresizingMaskIntoConstraints = false
        //view.addSubview(playerView!)
        contentView.insertSubview(playerView!, belowSubview: pageControl)
        playerView?.leadingAnchor.constraint(equalTo: contentView.leadingAnchor).isActive = true
        playerView?.trailingAnchor.constraint(equalTo: contentView.trailingAnchor).isActive = true
        playerView?.topAnchor.constraint(equalTo: contentView.topAnchor).isActive = true
        playerView?.bottomAnchor.constraint(equalTo: contentView.bottomAnchor).isActive = true
        playerView?.player = player
        player?.play()
        
        guard let videoUrl = Bundle.main.url(forResource: UIDevice.current.isIPad ? "Onboarding1ipad" : "Onboarding1", withExtension: "mp4") else { return }
        asset1 = AVAsset(url: videoUrl)
        playerItem1 = AVPlayerItem(asset: asset1!)
        player1 = AVQueuePlayer(playerItem: playerItem1)
        player1!.isMuted = false
        playerLooper1 = AVPlayerLooper(player: player1!, templateItem: playerItem1!)
        playerView1 = PlayerView()
        playerView1?.translatesAutoresizingMaskIntoConstraints = false
        //view.addSubview(playerView!)
        contentView.insertSubview(playerView1!, belowSubview: pageControl)
        playerView1?.leadingAnchor.constraint(equalTo: contentView.leadingAnchor).isActive = true
        playerView1?.trailingAnchor.constraint(equalTo: contentView.trailingAnchor).isActive = true
        playerView1?.topAnchor.constraint(equalTo: contentView.topAnchor).isActive = true
        playerView1?.bottomAnchor.constraint(equalTo: contentView.bottomAnchor).isActive = true
        playerView1?.player = player1
        playerView1?.isHidden = true
        //player1?.play()

        guard let videoUrl = Bundle.main.url(forResource: UIDevice.current.isIPad ? "Onboarding2ipad" : "Onboarding2", withExtension: "mp4") else { return }
        asset2 = AVAsset(url: videoUrl)
        playerItem2 = AVPlayerItem(asset: asset2!)
        player2 = AVQueuePlayer(playerItem: playerItem2)
        player2!.isMuted = false
        playerLooper2 = AVPlayerLooper(player: player2!, templateItem: playerItem2!)
        playerView2 = PlayerView()
        playerView2?.translatesAutoresizingMaskIntoConstraints = false
        //view.addSubview(playerView!)
        contentView.insertSubview(playerView2!, belowSubview: pageControl)
        playerView2?.leadingAnchor.constraint(equalTo: contentView.leadingAnchor).isActive = true
        playerView2?.trailingAnchor.constraint(equalTo: contentView.trailingAnchor).isActive = true
        playerView2?.topAnchor.constraint(equalTo: contentView.topAnchor).isActive = true
        playerView2?.bottomAnchor.constraint(equalTo: contentView.bottomAnchor).isActive = true
        playerView2?.player = player2
        playerView2?.isHidden = true
        //player2?.play()
                
        contentView.bringSubviewToFront(pageControl)
        contentView.bringSubviewToFront(continueButton)
        contentView.bringSubviewToFront(descriptionLabel)
        contentView.bringSubviewToFront(descriptionsStackView)
    }
    
    private func playNextVideo(_ videoName: String) {
        guard let videoUrl = Bundle.main.url(forResource: videoName, withExtension: "mp4") else { return }
        asset = AVAsset(url: videoUrl)
        let playerItem = AVPlayerItem(asset: asset!)
        DispatchQueue.main.async {
            self.player?.replaceCurrentItem(with: playerItem)
            self.player?.playImmediately(atRate: 1)
        }
    }
  
}
