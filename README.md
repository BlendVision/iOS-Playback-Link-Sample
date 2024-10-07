# iOS-Playback-Link-Sample

This `PlaybackViewController` demonstrates how to integrate `BVPlayer`, `BVUIControls`, and `BVPlaybackLink`, with a particular focus on using `BVSessionManager` to manage playback sessions and handle player events. 
This guide will cover the usage of `BVSessionManager`.

## Concept of `BVSessionManager`
`BVSessionManager` is a core component provided by `BVPlaybackLink` that manages playback sessions, handles playback tokens, and maintains the session state throughout the player's lifecycle. It allows the app to create, maintain, and end a playback session as required.

## Steps for Using `BVSessionManager`

1. Initializing the Playback Token：
the playback token is retrieved from the configuration and updated in `BVSessionManager`
```swift
BVSessionManager.shared.updatePlaybackToken(playbackToken)
```
2. Adding a BVSessionListener：
`BVSessionManager` allows listeners to be added to receive session status or error events. 
You can register `PlaybackViewController` during initialization as a `BVSessionListener`.
```swift
BVSessionManager.shared.add(listener: self)
```
Then, implement the `BVSessionListener` protocol to handle callbacks.
```swift
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
```
- `BVSessionStatusEvent`：Receives session status updates.
- `BVSessionErrorEvent`：Triggered when an error occurs within the session.

3. Managing Playback Sessions：
Throughout the playback flow, it is essential to start or end playback sessions when the player is ready or playback finishes.

- **Starting a playback session**: When the player is ready, a playback session is started.
```swift
    func player(_ player: UniPlayer, didReceiveOnReadyEvent event: any UniEvent) {
        startSession()
    }
```

- **Ending a playback session**: When playback finishes, or the app enters the background or terminates, the session is ended.
```swift
    func player(_ player: UniPlayer, didReceiveErrorEvent event: UniPlayerErrorEvent) {
        endSession()
    }
    
    func player(_ player: UniPlayer, didReceiveOnPlaybackFinishedEvent event: any UniEvent) {
        endSession()
    }
```

4.  Handling Sessions in the App Lifecycle：
To ensure that playback sessions are properly ended when the app enters the background or is about to terminate, notifications for application state changes are registered.
```swift
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
```
Corresponding methods call `startSession()` or `endSession()` to manage the session during app state changes.

## Conclusion
`BVSessionManager` provides reliable session management for playback. In this example, `PlaybackViewController` uses `BVSessionManager` to handle playback sessions, ensuring that sessions are accurately started and ended during key stages of the playback process, such as when the player is ready, playback is finished, or the app's state changes.

