//
// Created by Maarten Billemont on 2015-09-28.
// Copyright (c) 2015 Maarten Billemont. All rights reserved.
//

import UIKit

class LocationResultsViewController: UITableViewController, LocationsObserver {
    var locationItems = [ [ Location ] ]()

    override func viewDidLoad() {
        super.viewDidLoad()

        locationItems = [ [ Location ]( Locations.starred ), [ Location ]( Locations.recent ) ]
        Locations.observers.add( self )
    }

    /* Actions */

    @IBAction func didTapDismiss(sender: UIBarButtonItem) {
        navigationController?.dismissViewControllerAnimated( true, completion: nil )
    }

    @IBAction func didTapClear(sender: UIBarButtonItem) {
        Locations.recent.clear()
    }

    /* LocationsObserver */

    func locationsChanged(locations: Locations, byLocation location: Location) {
        let oldLocationItems = locationItems
        locationItems = [ [ Location ]( Locations.starred ), [ Location ]( Locations.recent ) ]
        tableView?.reloadSectionsFromArray( oldLocationItems, toArray: locationItems )
    }

    func locationsCleared(locations: Locations) {
        let oldLocationItems = locationItems
        locationItems = [ [ Location ]( Locations.starred ), [ Location ]( Locations.recent ) ]
        tableView?.reloadSectionsFromArray( oldLocationItems, toArray: locationItems )
    }

    /* UITableViewDataSource */

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return locationItems.count
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
        return locationItems[section].count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell         = tableView.dequeueReusableCellWithIdentifier( LocationCell.name(), forIndexPath: indexPath ) as! LocationCell
        let locationItem = locationItems[indexPath.section][indexPath.row]
        if let navigationController_ = self.navigationController as? STONavigationController {
            cell.navigationController = navigationController_
            cell.location = locationItem
        }

        return cell
    }

    /* UITableViewDelegate */

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let locationItem = locationItems[indexPath.section][indexPath.row]
        if let navigationController_ = self.navigationController as? STONavigationController {
            navigationController_.mapViewController.setAndTriggerSearchPlacemark( locationItem.placemark )
            navigationController_.dismissViewControllerAnimated( true, completion: nil )
        }

        tableView.deselectRowAtIndexPath( indexPath, animated: true )
    }
}

class LocationCell: UITableViewCell, LocationsObserver, LocationMarkObserver {
    class func name() -> String {
        return "LocationCell"
    }

    @IBOutlet var titleLabel:                 UILabel!
    @IBOutlet var subtitleLabel:              UILabel!
    @IBOutlet var extrasMenuControl:          UISegmentedControl!
    @IBOutlet var extrasMenuHiddenConstraint: NSLayoutConstraint!
    @IBOutlet var sourceDestinationControl:   UISegmentedControl!

    var mark:                 LocationMark?
    var extraMenuShowing = false {
        didSet {
            updateExtrasMenu()
        }
    }
    var navigationController: STONavigationController!
    var location:             Location! {
        didSet {
            titleLabel.text = "\(location.placemark.name ?? ""), \(location.placemark.locality ?? "")"
            subtitleLabel.text = location.placemark.postalCode
            updateExtrasMenu()
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()

        Locations.observers.add( self )
        LocationMark.observers.add( self )

        extrasMenuControl.clipsToBounds = true
        extrasMenuControl.layer.cornerRadius = 4
        extrasMenuControl.on( .ValueChanged, {
            if self.extrasMenuControl.selectedSegmentIndex == 0 {
                // Toggle button
                self.extraMenuShowing = !self.extraMenuShowing
            }
            else if self.extrasMenuControl.selectedSegmentIndex == 1 {
                // Trash
                Locations.starred.remove( self.location )
                Locations.recent.remove( self.location )
            }
            else if self.extrasMenuControl.selectedSegmentIndex == 2 {
                // Favorite button
                Locations.starred.toggle( self.location )
            }
            else {
                LocationMark( rawValue: self.extrasMenuControl.selectedSegmentIndex - 3 )?.setLocation( self.location )
            }
        } )
        sourceDestinationControl.layer.cornerRadius = 4
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

    override func prepareForReuse() {
        super.prepareForReuse()

        mark = nil
        extraMenuShowing = false
    }

    /* LocationsObserver */

    func locationsChanged(locations: Locations, byLocation location: Location) {
        if (location == self.location) {
            updateExtrasMenu()
        }
    }

    func locationsCleared(locations: Locations) {
        updateExtrasMenu()
    }

    /* LocationMarkObserver */

    func locationChangedForMark(mark: LocationMark, toLocation location: Location?) {
        if mark == self.mark || location == self.location {
            updateExtrasMenu()
        }
    }

    /* Private */

    func updateExtrasMenu() {
        layoutIfNeeded()
        UIView.animateWithDuration( 0.3, animations: {
            self.extrasMenuHiddenConstraint.active = !self.extraMenuShowing
            self.layoutIfNeeded()
        } )

        mark = markForLocation()
        let starred        = Locations.starred.contains( self.location )
        let firstItemTitle = extraMenuShowing ? "➡︎": mark?.title ?? (starred ? "★": "⬅︎")
        extrasMenuControl.setTitle( firstItemTitle, forSegmentAtIndex: 0 )
        extrasMenuControl.setTitle( starred ? "★": "☆︎", forSegmentAtIndex: 2 )
        extrasMenuControl.selectedSegmentIndex = mark == nil ? UISegmentedControlNoSegment: mark!.rawValue + 3
    }

    func markForLocation() -> LocationMark? {
        for mark in iterateEnum( LocationMark ) {
            if mark.matchesLocation( location ) {
                return mark
            }
        }

        return nil
    }
}
