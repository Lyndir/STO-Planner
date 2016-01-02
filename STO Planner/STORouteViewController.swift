//
// Created by Maarten Billemont on 2015-09-28.
// Copyright (c) 2015 Maarten Billemont. All rights reserved.
//

import UIKit

class STORouteViewController: UITableViewController {
    var routeLookup: STORouteLookup? {
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
            let vc = segue.destinationViewController as! STORouteStepViewController
            vc.routeStep = (sender as! STORouteStepCell).routeStep
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
            let cell = tableView.dequeueReusableCellWithIdentifier( STORouteLookupCell.name(), forIndexPath: indexPath ) as! STORouteLookupCell
            cell.routeLookup = routeLookup!

            return cell
        }

        let cell = tableView.dequeueReusableCellWithIdentifier( STORouteStepCell.name(), forIndexPath: indexPath ) as! STORouteStepCell
        cell.routeStep = routeLookup!.routes[indexPath.section - 1].steps[indexPath.row]

        return cell
    }
}

class STORouteLookupCell: UITableViewCell {
    class func name() -> String {
        return "STORouteLookupCell"
    }

    let timeFormatter     = NSDateFormatter()
    let dateTimeFormatter = NSDateFormatter()

    @IBOutlet var titleLabel:    UILabel!
    @IBOutlet var subtitleLabel: UILabel!
    @IBOutlet var arrivingLabel: UILabel!
    @IBOutlet var leavingLabel:  UILabel!

    var routeLookup: STORouteLookup! {
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

class STORouteStepCell: UITableViewCell {
    class func name() -> String {
        return "STORouteStepCell"
    }

    @IBOutlet var modeLabel:     UILabel!
    @IBOutlet var routeLabel:    UILabel!
    @IBOutlet var modeImageView: UIImageView!

    var routeStep: STORouteStep! {
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

class STORouteStepViewController: UIViewController {

    @IBOutlet var backgroundImage:  UIImageView!
    @IBOutlet var descriptionField: UITextView!

    var routeStep: STORouteStep!

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
