//
//  TweetTableViewCell.swift
//  CriticalMaps
//
//  Created by Leonard Thomas on 1/28/19.
//

import UIKit

class TweetTableViewCell: UITableViewCell, MessageConfigurable, IBConstructable {
    @objc
    dynamic var userameTextColor: UIColor? {
        willSet {
            userNameLabel.textColor = newValue
        }
    }

    @objc
    dynamic var handleLabelTextColor: UIColor? {
        willSet {
            handleLabel.textColor = newValue
        }
    }

    @objc
    dynamic var dateLabelTextColor: UIColor? {
        willSet {
            dateLabel.textColor = newValue
        }
    }

    @objc
    dynamic var linkTintColor: UIColor? {
        willSet {
            tweetTextView.tintColor = newValue
        }
    }

    @IBOutlet private var userNameLabel: UILabel! {
        didSet {
            userNameLabel.font = UIFont.scalableSystemFont(fontSize: 15, weight: .bold)
        }
    }

    @IBOutlet private var dateLabel: UILabel! {
        didSet {
            dateLabel.font = UIFont.scalableSystemFont(fontSize: 13, weight: .medium)
        }
    }

    @IBOutlet private var tweetTextView: UITextView! {
        didSet {
            tweetTextView.textContainerInset = UIEdgeInsets(top: 0.0, left: -5.0, bottom: 0.0, right: 0.0)
        }
    }

    @IBOutlet private var handleLabel: UILabel!

    @IBOutlet var tweetTextViewTopConstraint: NSLayoutConstraint!
    @IBOutlet var userImageViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet private var userImageView: UIImageView!
    @IBOutlet private var nameAndHandleAndTimeStackView: UIStackView!
    @IBOutlet private var nameAndHandleStackView: UIStackView!

    func setup(for tweet: Tweet) {
        dateLabel.text = FormatDisplay.dateString(for: tweet)
        tweetTextView.text = tweet.text
        handleLabel.text = "@\(tweet.user.screen_name)"
        userNameLabel.text = tweet.user.name
        userImageView.sd_setImage(with: URL(string: tweet.user.profile_image_url_https), placeholderImage: UIImage(named: "Avatar"))
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        let isAccessabilityCategory = traitCollection.preferredContentSizeCategory.isAccessabilitySizeCategory
        let wasAccessabilityCategory = previousTraitCollection?.preferredContentSizeCategory.isAccessabilitySizeCategory
        if wasAccessabilityCategory != isAccessabilityCategory {
            nameAndHandleStackView.axis = isAccessabilityCategory ? .vertical : .horizontal
            nameAndHandleStackView.alignment = isAccessabilityCategory ? .top : .center

            nameAndHandleAndTimeStackView.axis = isAccessabilityCategory ? .vertical : .horizontal
            nameAndHandleAndTimeStackView.alignment = isAccessabilityCategory ? .top : .center
            nameAndHandleAndTimeStackView.spacing = isAccessabilityCategory ? 8.0 : 2.0
            userImageView.isHidden = isAccessabilityCategory ? true : false
            userImageViewHeightConstraint.isActive = isAccessabilityCategory ? false : true
            tweetTextViewTopConstraint.constant = isAccessabilityCategory ? 16.0 : 0.0
        }
    }
}

extension TweetTableViewCell: UITextViewDelegate {
    // Opens a link in Safari
    func textView(_: UITextView, shouldInteractWith _: URL, in _: NSRange) -> Bool {
        return true
    }
}

extension UIContentSizeCategory {
    /// Returns if the UIContentSizeCategory is an accessabilitCategory
    var isAccessabilitySizeCategory: Bool {
        if #available(iOS 11.0, *) {
            return isAccessibilityCategory
        } else {
            if self == .accessibilityMedium
                || self == .accessibilityLarge
                || self == .accessibilityExtraLarge
                || self == .accessibilityExtraExtraLarge
                || self == .accessibilityExtraExtraExtraLarge {
                return true
            } else {
                return false
            }
        }
    }
}
