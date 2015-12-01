//
// Created by Maarten Billemont on 2015-09-28.
// Copyright (c) 2015 Maarten Billemont. All rights reserved.
//

import UIKit

class LocationResultsViewController: UITableViewController {
    let favoriteLocations: Locations = Locations.starred()
    let recentLocations:   Locations = Locations.recent()

    @IBAction func didTapDismiss(sender: UIBarButtonItem) {
        navigationController?.dismissViewControllerAnimated( true, completion: nil )
    }

    @IBAction func didTapClear(sender: UIBarButtonItem) {
        recentLocations.clear()
    }

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 2
    }

    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
            case 0:
                return "Favorite Locations"
            case 1:
                return "Recent Locations"
            default:
                preconditionFailure( "Unexpected section: \(section)" )
        }
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
            case 0:
                return favoriteLocations.count
            case 1:
                return recentLocations.count
            default:
                preconditionFailure( "Unexpected section: \(section)" )
        }
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let location: Location
        switch indexPath.section {
            case 0:
                location = favoriteLocations[indexPath.row]
            case 1:
                location = recentLocations[indexPath.row]
            default:
                preconditionFailure( "Unexpected section: \(indexPath.section)" )
        }

        let cell = tableView.dequeueReusableCellWithIdentifier( LocationCell.name(), forIndexPath: indexPath ) as! LocationCell
        if let navigationController_ = self.navigationController as? STONavigationController {
            cell.navigationController = navigationController_
            cell.location = location
        }

        return cell
    }

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if let navigationController_ = self.navigationController as? STONavigationController {
            switch indexPath.section {
                case 0:
                    navigationController_.mapViewController.searchPlacemark = favoriteLocations[indexPath.row].placemark
                case 1:
                    navigationController_.mapViewController.searchPlacemark = recentLocations[indexPath.row].placemark
                default:
                    preconditionFailure( "Unexpected section: \(indexPath.section)" )
            }

            navigationController_.dismissViewControllerAnimated( true, completion: nil )
        }

        tableView.deselectRowAtIndexPath( indexPath, animated: true )
    }
}

class LocationCell: UITableViewCell {
    class func name() -> String {
        return "LocationCell"
    }

    @IBOutlet var titleLabel:                 UILabel!
    @IBOutlet var subtitleLabel:              UILabel!
    @IBOutlet var extrasMenuControl:          UISegmentedControl!
    @IBOutlet var extrasMenuHiddenConstraint: NSLayoutConstraint!
    @IBOutlet var sourceDestinationControl:   UISegmentedControl!

    var extraMenuShowing = false

    var navigationController: STONavigationController!
    var location: Location! {
        didSet {
            titleLabel.text = location.placemark.name
            subtitleLabel.text = location.placemark.thoroughfare
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()

        extrasMenuControl.on( .ValueChanged, {
            switch self.extrasMenuControl.selectedSegmentIndex {
                case 0: // Disclosure button
                    self.extraMenuShowing = !self.extraMenuShowing
                case 1: // Home
                    LocationMark.Home.setLocation( self.location )
                case 2: // Work
                    LocationMark.Work.setLocation( self.location )
                case 3: // Play
                    LocationMark.Play.setLocation( self.location )
                default:
                    preconditionFailure( "Unsupported extras segment index: \(self.extrasMenuControl.selectedSegmentIndex)" )
            }
            self.updateExtrasMenu()
        } )
        sourceDestinationControl.on( .ValueChanged, {
            switch self.sourceDestinationControl.selectedSegmentIndex {
                case 0:
                    self.navigationController.mapViewController.sourcePlacemark = self.location.placemark

                case 1:
                    self.navigationController.mapViewController.destinationPlacemark = self.location.placemark

                default:
                    preconditionFailure( "Unexpected segment for source/destination control: \(self.sourceDestinationControl.selectedSegmentIndex)" )
            }

            self.navigationController.dismissViewControllerAnimated( true, completion: nil )
        } )
    }

    func updateExtrasMenu() {
        layoutIfNeeded()
        UIView.animateWithDuration( 0.3, animations: {
            self.extrasMenuHiddenConstraint.active = !self.extraMenuShowing
            self.layoutIfNeeded()
        } )

        extrasMenuControl.setTitle( extraMenuShowing ? "➡︎": "⬅︎", forSegmentAtIndex: 0 )
        extrasMenuControl.selectedSegmentIndex = UISegmentedControlNoSegment
        for mark in iterateEnum( LocationMark ) {
            if mark.matchesLocation( location ) {
                extrasMenuControl.selectedSegmentIndex = mark.rawValue + 1
                break
            }
        }
    }
}
