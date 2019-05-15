//
//  SettingsGithubTableViewCellTableViewCell.swift
//  CriticalMaps
//
//  Created by Leonard Thomas on 1/31/19.
//

import UIKit

class SettingsGithubTableViewCellTableViewCell: UITableViewCell, IBConstructable {
    @IBOutlet var backgroundImageView: UIImageView!
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var detailLabel: UILabel!
    @IBOutlet var actionLabel: UILabel!

    @IBOutlet var selectionOverlay: UIView!
    override func awakeFromNib() {
        super.awakeFromNib()

        titleLabel.adjustsFontForContentSizeCategory = true
        detailLabel.adjustsFontForContentSizeCategory = true
        actionLabel.adjustsFontForContentSizeCategory = true

        titleLabel.attributedText = attributed(string: String.settingsOpenSourceTitle, lineSpacing: 3.3)
        titleLabel.textColor = .settingsOpenSourceForeground
        detailLabel.attributedText = attributed(string: String.settingsOpenSourceDetail, lineSpacing: 4)
        detailLabel.textColor = .settingsOpenSourceForeground
        actionLabel.text = String.settingsOpenSourceAction.uppercased()
        actionLabel.textColor = .settingsOpenSourceForeground

        backgroundImageView.image = UIImage(named: "GithubBanner")?.resizableImage(withCapInsets: UIEdgeInsets(top: 20, left: 20, bottom: 200, right: 200), resizingMode: .stretch)
        selectionOverlay.backgroundColor = UIColor.gray.withAlphaComponent(0.2)
        selectionOverlay.layer.cornerRadius = 16
    }

    private func attributed(string: String, lineSpacing: Float) -> NSAttributedString {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = CGFloat(lineSpacing)
        return NSAttributedString(string: string, attributes: [.paragraphStyle: paragraphStyle])
    }

    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        let updateBlock = {
            self.selectionOverlay.alpha = highlighted ? 1 : 0
        }

        if animated {
            UIView.animate(withDuration: 0.2, animations: updateBlock)
        } else {
            updateBlock()
        }
    }
}
