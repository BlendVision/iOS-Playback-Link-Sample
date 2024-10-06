import UIKit

struct Preference {
    static var shared = Preference()

    var streamingURL: String? = ""
    
    var playbackToken: String? = "Your-playback-token"

    var licenseKey: String = "Your-license-key"
}
