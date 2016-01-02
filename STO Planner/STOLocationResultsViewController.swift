//
// Created by Maarten Billemont on 2015-09-28.
// Copyright (c) 2015 Maarten Billemont. All rights reserved.
//

import UIKit

class STOLocationResultsViewController: UITableViewController, STOLocationsObserver {
    var locationItems = [ [ STOLocation ] ]()

    override func viewDidLoad() {
        super.viewDidLoad()

        locationItems = [ [ STOLocation ]( STOLocations.starred ), [ STOLocation ]( STOLocations.recent ) ]
        STOLocations.observers.add( self )
    }

    /* Actions */

    @IBAction func didTapDismiss(sender: UIBarButtonItem) {
        navigationController?.dismissViewControllerAnimated( true, completion: nil )
    }

    @IBAction func didTapClear(sender: UIBarButtonItem) {
        STOLocations.recent.clear()
    }

    /* LocationsObserver */

    func locationsChanged(locations: STOLocations, byLocation location: STOLocation) {
        let oldLocationItems = locationItems
        locationItems = [ [ STOLocation ]( STOLocations.starred ), [ STOLocation ]( STOLocations.recent ) ]
        tableView?.reloadSectionsFromArray( oldLocationItems, toArray: locationItems )
    }

    func locationsCleared(locations: STOLocations) {
        let oldLocationItems = locationItems
        locationItems = [ [ STOLocation ]( STOLocations.starred ), [ STOLocation ]( STOLocations.recent ) ]
        tableView?.reloadSectionsFromArray( oldLocationItems, toArray: locationItems )
    }

    /* UITableViewDataSource */

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return locationItems.count
    }

    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
            case 0:
                return strl( "Favorite Locations" )
            case 1:
                return strl( "Recent Locations" )
            default:
                preconditionFailure( "Unexpected section: \(section)" )
        }
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return locationItems[section].count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell         = tableView.dequeueReusableCellWithIdentifier( STOLocationCell.name(), forIndexPath: indexPath ) as! STOLocationCell
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

class STOLocationCell: UITableViewCell, STOLocationsObserver, STOLocationMarkObserver {
    class func name() -> String {
        return "STOLocationCell"
    }

    @IBOutlet var titleLabel:                 UILabel!
    @IBOutlet var subtitleLabel:              UILabel!
    @IBOutlet var extrasMenuControl:          UISegmentedControl!
    @IBOutlet var extrasMenuHiddenConstraint: NSLayoutConstraint!
    @IBOutlet var sourceDestinationControl:   UISegmentedControl!

    var mark:                 STOLocationMark?
    var extraMenuShowing = false {
        didSet {
            updateExtrasMenu()
        }
    }
    var navigationController: STONavigationController!
    var location:             STOLocation! {
        didSet {
            titleLabel.text = strl( "%@, %@", location.placemark.name ?? "", location.placemark.locality ?? "" )
            subtitleLabel.text = location.placemark.postalCode
            updateExtrasMenu()
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()

        STOLocations.observers.add( self )
        STOLocationMark.observers.add( self )

        extrasMenuControl.clipsToBounds = true
        extrasMenuControl.layer.cornerRadius = 4
        extrasMenuControl.on( .ValueChanged, {
            if self.extrasMenuControl.selectedSegmentIndex == 0 {
                // Toggle button
                self.extraMenuShowing = !self.extraMenuShowing
            }
            else if self.extrasMenuControl.selectedSegmentIndex == 1 {
                // Trash
                STOLocations.starred.remove( self.location )
                STOLocations.recent.remove( self.location )
            }
            else if self.extrasMenuControl.selectedSegmentIndex == 2 {
                // Favorite button
                STOLocations.starred.toggle( self.location )
            }
            else {
                // Mark button
                STOLocations.starred.insert( self.location )
                STOLocationMark( rawValue: self.extrasMenuControl.selectedSegmentIndex - 3 )?.setLocation( self.location )
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

    func locationsChanged(locations: STOLocations, byLocation location: STOLocation) {
        if (location == self.location) {
            updateExtrasMenu()
        }
    }

    func locationsCleared(locations: STOLocations) {
        updateExtrasMenu()
    }

    /* LocationMarkObserver */

    func locationChangedForMark(mark: STOLocationMark, toLocation location: STOLocation?) {
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
        let starred        = STOLocations.starred.contains( self.location )
        let firstItemTitle = extraMenuShowing ? "➡︎": mark?.title ?? (starred ? "★": "⬅︎")
        extrasMenuControl.setTitle( firstItemTitle, forSegmentAtIndex: 0 )
        extrasMenuControl.setTitle( starred ? "★": "☆︎", forSegmentAtIndex: 2 )
        extrasMenuControl.selectedSegmentIndex = mark == nil ? UISegmentedControlNoSegment: mark!.rawValue + 3
    }

    func markForLocation() -> STOLocationMark? {
        for mark in STOLocationMark.allValues {
            if mark.matchesLocation( location ) {
                return mark
            }
        }

        return nil
    }
}
