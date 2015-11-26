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

            let source = routeLookup!.sourcePlacemark, destination = routeLookup!.destinationPlacemark
            cell.titleLabel!.text = destination.thoroughfare ?? destination.name ?? ""
            cell.subtitleLabel!.text = "From: \(source.thoroughfare ?? source.name ?? "")"

            return cell
        }

        let cell      = tableView.dequeueReusableCellWithIdentifier( RouteStepCell.name(), forIndexPath: indexPath ) as! RouteStepCell
        let routeStep = routeLookup!.routes[indexPath.section - 1].steps[indexPath.row]

        cell.modeImageView!.image = routeStep.mode.image()
        cell.modeImageView!.alpha = routeStep.modeContext?.startIndex == routeStep.modeContext?.endIndex ? 1: 0.38;
        cell.modeLabel!.text = routeStep.modeContext
        cell.routeLabel!.text = routeStep.explanation

        return cell
    }
}

class RouteLookupCell: UITableViewCell {
    class func name() -> String {
        return "RouteLookupCell"
    }

    @IBOutlet var titleLabel:    UILabel!
    @IBOutlet var subtitleLabel: UILabel!
}

class RouteStepCell: UITableViewCell {
    class func name() -> String {
        return "RouteStepCell"
    }

    @IBOutlet var modeLabel:     UILabel!
    @IBOutlet var routeLabel:    UILabel!
    @IBOutlet var modeImageView: UIImageView!
}
