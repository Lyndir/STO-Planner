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
        cell.titleLabel.text = location.placemark.name
        cell.subtitleLabel.text = location.placemark.thoroughfare
        cell.sourceDestinationControl.on( .ValueChanged, {
            let navigationController = self.navigationController as! STONavigationController

            switch cell.sourceDestinationControl.selectedSegmentIndex {
                case 0:
                    navigationController.mapViewController.sourcePlacemark = location.placemark

                case 1:
                    navigationController.mapViewController.destinationPlacemark = location.placemark

                default:
                    preconditionFailure( "Unexpected segment for source/destination control: \(cell.sourceDestinationControl.selectedSegmentIndex)" )
            }

            navigationController.dismissViewControllerAnimated( true, completion: nil )
        } )

        return cell
    }

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let mapViewController = (self.navigationController as! STONavigationController).mapViewController
        switch indexPath.section {
            case 0:
                mapViewController.searchPlacemark = favoriteLocations[indexPath.row].placemark
            case 1:
                mapViewController.searchPlacemark = recentLocations[indexPath.row].placemark
            default:
                preconditionFailure( "Unexpected section: \(indexPath.section)" )
        }
    }
}

class LocationCell: UITableViewCell {
    class func name() -> String {
        return "LocationCell"
    }

    @IBOutlet var titleLabel:               UILabel!
    @IBOutlet var subtitleLabel:            UILabel!
    @IBOutlet var sourceDestinationControl: UISegmentedControl!
}
