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

    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return section == 0 ? 0: 30
    }

    override func tableView(tableView: UITableView, viewForHeaderInSection section: NSInteger) -> UIView? {
        let sectionView = UILabel()
        sectionView.text = "\u{2003}" + (self.tableView( tableView, titleForHeaderInSection: section ) ?? "")
        sectionView.backgroundColor = UIColor( red: 0.392156862745, green: 0.482352941176, blue: 0.419607843137, alpha: 1 )
        sectionView.textColor = UIColor( red: 0.933333333333, green: 0.858823529412, blue: 0.737254901961, alpha: 1 )
        sectionView.font = UIFont.preferredFontForTextStyle( UIFontTextStyleHeadline )

        return sectionView
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

    let timeFormatter     = NSDateFormatter()
    let dateTimeFormatter = NSDateFormatter()

    @IBOutlet var titleLabel:    UILabel!
    @IBOutlet var subtitleLabel: UILabel!
    @IBOutlet var arrivingLabel: UILabel!
    @IBOutlet var leavingLabel:  UILabel!

    var routeLookup: RouteLookup! {
        didSet {
            let source = routeLookup.sourcePlacemark, destination = routeLookup.destinationPlacemark
            titleLabel.text = destination.thoroughfare ?? destination.name ?? ""
            subtitleLabel.text = strl( "From: %@", source.thoroughfare ?? source.name ?? "" )
            leavingLabel.hidden = true
            arrivingLabel.hidden = true

            if routeLookup.travelTime is STOTravelTimeLeavingNow {
                leavingLabel.hidden = false
                leavingLabel.text = strl( "Leaving Now" )
            }
            else if let futureTime = routeLookup.travelTime as? STOFutureTravelTime {
                let timeFormat: String
                if NSCalendar.currentCalendar().isDateInToday( futureTime.time ) {
                    timeFormat = timeFormatter.stringFromDate( futureTime.time )
                }
                else {
                    timeFormat = dateTimeFormatter.stringFromDate( futureTime.time )
                }

                if futureTime is STOTravelTimeArriving {
                    arrivingLabel.hidden = false
                    arrivingLabel.text = strl( "Arriving:\n%@", timeFormat )
                }
                else if futureTime is STOTravelTimeLeaving {
                    leavingLabel.hidden = false
                    leavingLabel.text = strl( "Leaving: %@", timeFormat )
                }
            }
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()

        timeFormatter.dateStyle = .NoStyle
        timeFormatter.timeStyle = .ShortStyle
        dateTimeFormatter.dateStyle = .ShortStyle
        dateTimeFormatter.timeStyle = .ShortStyle
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
            routeLabel.attributedText = stra( routeStep.explanation, routeLabel.textAttributes() )
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
            layoutIfNeeded()
            if routeLabel.bounds.size.width < routeLabel.intrinsicContentSize().width ||
               routeLabel.bounds.size.height < routeLabel.intrinsicContentSize().height {
                accessoryType = UITableViewCellAccessoryType.DisclosureIndicator
                layoutIfNeeded()
            }
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
        descriptionField.attributedText = stra( routeStep.explanation, descriptionField.textAttributes() )
        navigationItem.title = routeStep.shortExplanation
    }

    override func viewDidLayoutSubviews() {
        descriptionField.insetOcclusion()

        super.viewDidLayoutSubviews()
    }
}
