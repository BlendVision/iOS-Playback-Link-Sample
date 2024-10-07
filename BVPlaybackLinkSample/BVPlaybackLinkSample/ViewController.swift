//
//  PlaybackViewController.swift
//  BVPlaybackLinkSample
//
//  Created by Sunny on 2024/10/4.
//

import UIKit
import BVPlayer
import BVUIControls
import BVPlaybackLink

class PlaybackViewController: UIViewController {
    
    var player: UniPlayer?
    var playerView: UniPlayerView?
    
    // Externally set parameters
    let licenseKey: String
    var streamUrl: String?
    var playbackToken: String?
    
    private let logToggleButton = UIBarButtonItem()
    
    required init?(coder: NSCoder) {
        self.licenseKey = Preference.shared.licenseKey
        self.playbackToken = Preference.shared.playbackToken
        self.streamUrl = Preference.shared.streamingURL
        super.init(coder: coder)
    }
    
    deinit {
        print("\(self) deinit")
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        if isMovingFromParent {
            closePlayer()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = .black
        registerNotification()
        
        // Define needed resources
        guard let streamUrl = URL(string: streamUrl ?? "") else {
            return
        }
        
        // Create player configuration
        let playerConfig = UniPlayerConfig()
        playerConfig.serviceConfig.version = .v2
        playerConfig.licenseKey = licenseKey
        
        // BV Session
        BVSessionManager.shared.updatePlaybackToken(playbackToken)
        BVSessionManager.shared.add(listener: self)
        
        Task {
            // Create player based on player config
            let info = try await BVSessionManager.shared.getResourceInfo()
            let config: [String: String] = [
                "analytics.resource_id": info.resourceID,
                "analytics.resource_type": info.resourceType
            ]
            player = UniPlayerFactory.create(player: playerConfig, moduleConfig: config)
            
            // Create player view and pass the player instance to it
            playerView = UniPlayerView(player: player!, frame: .zero)
            
            // Listen to player events
            player?.add(listener: self)
            
            playerView?.autoresizingMask = [.flexibleHeight, .flexibleWidth]
            playerView?.frame = view.bounds
            playerView?.add(listener: self)
            
            // Create source config
            let sourceConfig = UniSourceConfig(url: streamUrl, type: .hls)
            
            player?.load(sourceConfig: sourceConfig)
        }
    }
    
    private func closePlayer() {
        Task {
            player?.destroy()
            playerView?.remove(listener: self)
            endSession()
            BVSessionManager.shared.release()
        }
    }
    
    private func startSession() {
        Task {
            do {
                try await BVSessionManager.shared.startPlaybackSession()
            } catch {
                // error
            }
        }
    }
    
    private func endSession() {
        Task {
            do {
                try await BVSessionManager.shared.endPlaybackSession()
            } catch {
                // error
            }
        }
    }
}

//MARK: App life cycle
extension PlaybackViewController {
    
    private func registerNotification() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(appDidEnterBackground),
                                               name: UIApplication.didEnterBackgroundNotification,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(appWillEnterForeground),
                                               name: UIApplication.willEnterForegroundNotification,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(appWillTerminate),
                                               name: UIApplication.willTerminateNotification,
                                               object: nil)
    }
    
    @objc func appDidEnterBackground() {
        endSession()
    }
    
    @objc func appWillEnterForeground() {
        startSession()
    }
    
    @objc func appWillTerminate() {
        endSession()
    }
}

//MARK: Player event
extension PlaybackViewController: UniPlayerListener {
    
    func player(_ player: UniPlayer, didReceiveOnEvent event: UniEvent) {
        // Uncomment the following line to observe the event of player
        // debugPrint("event=\(event)")
    }
    
    // Player Life Cycle
    func player(_ player: UniPlayer, didReceiveOnReadyEvent event: any UniEvent) {
        startSession()
    }
    
    func player(_ player: UniPlayer, didReceiveErrorEvent event: UniPlayerErrorEvent) {
        endSession()
    }
    
    func player(_ player: UniPlayer, didReceiveOnPlaybackFinishedEvent event: any UniEvent) {
        endSession()
    }
}

//MARK: BV Session event
extension PlaybackViewController: BVSessionListener {
    
    func sessionManager(_ manager: BVPlaybackLink.BVSessionManager,
                        statusEvent event: BVPlaybackLink.BVSessionStatusEvent) {
        print("Status=\(event.status)")
    }
    
    func sessionManager(_ manager: BVPlaybackLink.BVSessionManager,
                        didReceiveErrorEvent event: BVPlaybackLink.BVSessionErrorEvent) {
        print("Error=\(event.message)")
    }
}

//MARK: Player view event
extension PlaybackViewController: UniUserInterfaceListener {
    
    func playerView(_ view: UniPlayerView, didReceiveSettingPressed event: UniUIEvent) {
        guard let player = player else { return }
        if #available(iOS 15.0, *) {
            let navController = UniSheetPresentationController(
                rootViewController: UniSettingViewController(player: player)
            )
            present(navController, animated: true)
        } else {
            // Fallback on earlier versions
            let navController = UINavigationController(
                rootViewController: UniSettingViewController(player: player)
            )
            present(navController, animated: true)
        }
    }
}


