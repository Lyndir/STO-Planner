//
// Created by Maarten Billemont on 2015-12-02.
// Copyright (c) 2015 Maarten Billemont. All rights reserved.
//

import UIKit

class STOLaunchViewController: UIViewController {
    @IBOutlet var startConstraint: NSLayoutConstraint!

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear( animated )

        view.layoutIfNeeded()
        UIView.animateWithDuration( 1, animations: {
            self.startConstraint.active = false
            self.view.layoutIfNeeded()
        } )
    }
}

class STOLaunchProgressView: UIView {
    var progress: CGFloat = 0 {
        didSet {
            updatePath()
        }
    }
    var path: CGPath?

    func updatePath() {
        let origin        = CGRectGetTopLeft( bounds )
        let progressWidth = bounds.width * progress
        let arrowWidth    = bounds.height * 3 / 8

        let path = CGPathCreateMutable()
        CGPathMoveToPoint( path, nil, origin.x, origin.y )
        CGPathAddLineToPoint( path, nil, origin.x + progressWidth, origin.y )
        CGPathAddLineToPoint( path, nil, origin.x + progressWidth + arrowWidth, origin.y + bounds.height / 2 )
        CGPathAddLineToPoint( path, nil, origin.x + progressWidth, origin.y + bounds.height )
        CGPathAddLineToPoint( path, nil, origin.x, origin.y + bounds.height )
        CGPathCloseSubpath( path )
        self.path = path

        setNeedsDisplay()
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        updatePath()
    }

    override func drawRect(rect: CGRect) {
        if let path_ = path {
            let context = UIGraphicsGetCurrentContext()
            CGContextAddPath( context, path_ )
            tintColor.setFill()
            CGContextFillPath( context )
        }
    }
}
