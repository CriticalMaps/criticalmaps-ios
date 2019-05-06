//
//  RulesDetailViewController.swift
//  CriticalMaps
//
//  Created by Leonard Thomas on 12/17/18.
//

import UIKit

class RuleDetailTextView: UITextView {
    @objc
    dynamic var ruleDetailTextColor: UIColor? {
        willSet {
            textColor = newValue
        }
    }
}

class RulesDetailViewController: UIViewController {
    private var rule: Rule

    init(rule: Rule) {
        self.rule = rule
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = rule.title
        navigationController?.navigationBar.tintColor = .black
        configureTextView()
    }

    private func configureTextView() {
        let textView = RuleDetailTextView(frame: view.bounds)
        textView.contentInset = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)

        let artworkAttachment = NSTextAttachment()
        let artWork = rule.artwork
        artworkAttachment.image = artWork
        let ratio = (artWork?.size.height ?? 1) / (artWork?.size.width ?? 1)
        let artworkPadding = textView.contentInset.left + textView.contentInset.right + textView.textContainer.lineFragmentPadding
        let artworkWidth = view.bounds.width - artworkPadding
        artworkAttachment.bounds.size = CGSize(width: artworkWidth, height: artworkWidth * ratio)

        let attributedString = NSMutableAttributedString()
        attributedString.append(NSAttributedString(attachment: artworkAttachment))
        attributedString.append(NSAttributedString(string: rule.text))

        textView.attributedText = attributedString
        textView.isEditable = false
        textView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        textView.font = UIFont.preferredFont(forTextStyle: .body)
        textView.textColor = .gray300
        textView.adjustsFontForContentSizeCategory = true
        view.addSubview(textView)
    }
}
