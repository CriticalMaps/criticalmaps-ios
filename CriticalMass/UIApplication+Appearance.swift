//
//  UIApplication+Appearance.swift
//  CriticalMaps
//
//  Created by Malte Bünz on 15.04.19.
//  Copyright © 2019 Pokus Labs. All rights reserved.
//

import UIKit

extension Notification.Name {
    static let CMAppearanceWillRefreshApplication = Notification.Name(rawValue: "CMAppearanceWillRefreshApplicationNotification")
    static let CMAppearanceDidRefreshApplication = Notification.Name(rawValue: "CMAppearanceDidRefreshApplicationNotification")
}

extension UIApplication {
    @nonobjc private func _refreshAppearance(animated: Bool) {
        for window in windows {
            window.refreshAppearance(animated: animated)
        }
    }

    /// Refreshes appearance for all windows in the application
    ///
    /// - Parameter animated: if the refresh should be animated
    func refreshAppearance(animated: Bool) {
        NotificationCenter.default.post(name: .CMAppearanceWillRefreshApplication, object: self)
        UIView.animate(withDuration: animated ? 0.25 : 0, animations: {
            self._refreshAppearance(animated: animated)
        }, completion: { _ in
            NotificationCenter.default.post(name: .CMAppearanceDidRefreshApplication, object: self)
        })
    }
}
