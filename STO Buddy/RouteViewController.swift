//
// Created by Maarten Billemont on 2015-09-28.
// Copyright (c) 2015 Maarten Billemont. All rights reserved.
//

import UIKit

class RouteViewController: UITableViewController {
    var routeLookup: RouteLookup? {
        didSet {
            tableView.reloadData()
        }
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear( animated )

        self.navigationController!.setNavigationBarHidden( true, animated: animated );
        UIView.animateWithDuration( animated ? 0.3: 0, animations: {
            self.view.alpha = 1
        } )
    }

    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear( animated )

        self.navigationController!.setNavigationBarHidden( false, animated: animated );
        UIView.animateWithDuration( animated ? 0.3: 0, animations: {
            self.view.alpha = 0
        } )
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "routeStepDetail" {
            let vc = segue.destinationViewController as! RouteStepViewController
            vc.routeStep = (sender as! RouteStepCell).routeStep
        }
        else {
            super.prepareForSegue( segue, sender: sender )
        }
    }

    /* UITableViewDelegate */

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        if let routeLookup_ = routeLookup {
            return routeLookup_.routes.count + 1
        }

        return 0
    }

    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if let routeLookup_ = routeLookup {
            if section == 0 {
                return nil
            }

            return routeLookup_.routes[section - 1].title
        }

        return nil
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let routeLookup_ = routeLookup {
            if section == 0 {
                return 1
            }

            return routeLookup_.routes[section - 1].steps.count
        }

        return 0
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let cell = tableView.dequeueReusableCellWithIdentifier( RouteLookupCell.name(), forIndexPath: indexPath ) as! RouteLookupCell
            cell.routeLookup = routeLookup!

            return cell
        }

        let cell = tableView.dequeueReusableCellWithIdentifier( RouteStepCell.name(), forIndexPath: indexPath ) as! RouteStepCell
        cell.routeStep = routeLookup!.routes[indexPath.section - 1].steps[indexPath.row]

        return cell
    }
}

class RouteLookupCell: UITableViewCell {
    class func name() -> String {
        return "RouteLookupCell"
    }

    @IBOutlet var titleLabel:    UILabel!
    @IBOutlet var subtitleLabel: UILabel!

    var routeLookup: RouteLookup! {
        didSet {
            let source = routeLookup.sourcePlacemark, destination = routeLookup.destinationPlacemark
            titleLabel.text = destination.thoroughfare ?? destination.name ?? ""
            subtitleLabel.text = "From: \(source.thoroughfare ?? source.name ?? "")"
        }
    }
}

class RouteStepCell: UITableViewCell {
    class func name() -> String {
        return "RouteStepCell"
    }

    @IBOutlet var modeLabel:     UILabel!
    @IBOutlet var routeLabel:    UILabel!
    @IBOutlet var modeImageView: UIImageView!

    var routeStep: RouteStep! {
        didSet {
            modeImageView.image = routeStep.mode.thumbnailImage
            modeImageView.alpha = routeStep.modeContext?.startIndex == routeStep.modeContext?.endIndex ? 1: 0.38;
            modeLabel.text = routeStep.modeContext
            routeLabel.text = routeStep.explanation
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        if routeLabel.bounds.size.width < routeLabel.intrinsicContentSize().width ||
           routeLabel.bounds.size.height < routeLabel.intrinsicContentSize().height {
            accessoryType = UITableViewCellAccessoryType.DisclosureIndicator
        }
        else {
            accessoryType = UITableViewCellAccessoryType.None
        }
    }
}

class RouteStepViewController: UIViewController {

    @IBOutlet var backgroundImage:  UIImageView!
    @IBOutlet var descriptionField: UITextView!

    var routeStep: RouteStep!

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear( animated )

        backgroundImage.image = routeStep.mode.backgroundImage
        descriptionField.text = routeStep.explanation
        navigationItem.title = routeStep.shortExplanation
    }
}
