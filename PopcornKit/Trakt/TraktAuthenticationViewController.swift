
#if os(tvOS)

import UIKit

public class TraktAuthenticationViewController: UIViewController {
	@IBOutlet weak var codeLabel: UILabel!

	var intervalTimer: Timer?
    var deviceCode: String?
    var expiresIn: Date?

	public override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(true)
		getNewCode()
	}

	public override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)
		intervalTimer?.invalidate()
        intervalTimer = nil
	}

	private func getNewCode() {
        TraktManager.shared.generateCode { [weak self] (displayCode, deviceCode, expires, interval, error) in
            guard let displayCode = displayCode,
                let deviceCode = deviceCode,
                let expires = expires,
                let interval = interval,
                let `self` = self,
                error == nil else { return }
            self.codeLabel.text = displayCode
            self.expiresIn = expires
            self.deviceCode = deviceCode
            self.intervalTimer = Timer.scheduledTimer(timeInterval: interval, target: self, selector: #selector(self.poll), userInfo: nil, repeats: true)
        }
	}

    static var bundle: Bundle? {
        return Bundle(for: TraktAuthenticationViewController.self)
    }

	@objc public func poll(timer: Timer) {
        if let expiresIn = expiresIn, expiresIn < Date() {
            timer.invalidate()
            getNewCode()
        } else if let deviceCode = deviceCode {
            DispatchQueue.global(qos: .default).async {
                do {
                    try OAuthCredential(Trakt.base + Trakt.auth + Trakt.device + Trakt.token, parameters: ["code": deviceCode], clientID: Trakt.apiKey, clientSecret: Trakt.apiSecret, useBasicAuthentication: false).store(withIdentifier: "trakt")
                    DispatchQueue.main.sync {
                        TraktManager.shared.delegate?.authenticationDidSucceed?()
                    }
                } catch { }
            }
        }
	}
}

#endif
