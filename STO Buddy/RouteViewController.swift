//
// Created by Maarten Billemont on 2015-09-28.
// Copyright (c) 2015 Maarten Billemont. All rights reserved.
//

import UIKit

class RouteViewController: UITableViewController {
    var routes = [Route]() {
        didSet {
            tableView.reloadData()
        }
    }

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return routes.count
    }

    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return routes[section].title
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return routes[section].steps.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell      = tableView.dequeueReusableCellWithIdentifier( "RouteStepCell", forIndexPath: indexPath )
        let routeStep = routes[indexPath.section].steps[indexPath.row]

        cell.textLabel!.text = routeStep.shortExplanation
        cell.detailTextLabel!.text = routeStep.explanation

        return cell
    }
}
