//
// Created by Maarten Billemont on 2015-09-28.
// Copyright (c) 2015 Maarten Billemont. All rights reserved.
//

import UIKit

class LocationResultsViewController: UITableViewController {
    typealias C = LocationCell

    lazy var locations: Locations = self.initLocations()

    func initLocations() -> Locations {
        preconditionFailure( "Abstract method -initLocations not implemented" )
    }

    @IBAction func didTapDismiss(sender: UIBarButtonItem) {
        navigationController?.dismissViewControllerAnimated( true, completion: nil )
    }

    @IBAction func didTapClear(sender: UIBarButtonItem) {
        locations.clear()
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return locations.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell     = tableView.dequeueReusableCellWithIdentifier( C.name(), forIndexPath: indexPath ) as! C
        let location = locations[indexPath.row]

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
        (self.navigationController as! STONavigationController).mapViewController.searchPlacemark = locations[indexPath.row].placemark
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
