//
// Created by Maarten Billemont on 2015-12-01.
// Copyright (c) 2015 Maarten Billemont. All rights reserved.
//

import UIKit

@IBDesignable class STOVisualEffectView: UIVisualEffectView {
    @IBInspectable var blurTint: UIColor?

    override func layoutSubviews() {
        super.layoutSubviews()

        if let blurTint_ = blurTint {
            subviews[1].layer.backgroundColor = blurTint_.CGColor
        }
    }
}

@IBDesignable class STOToolbar: UIToolbar {
    @IBInspectable var blurTint: UIColor?

    override func layoutSubviews() {
        super.layoutSubviews()

        if let blurTint_ = blurTint {
            if let tintView = subviews.first?.subviews.first?.subviews[1] {
                tintView.hidden = false
                tintView.layer.backgroundColor = blurTint_.CGColor
            }
        }
    }
}
