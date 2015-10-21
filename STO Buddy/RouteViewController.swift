//
// Created by Maarten Billemont on 2015-09-28.
// Copyright (c) 2015 Maarten Billemont. All rights reserved.
//

import UIKit

class RouteViewController: UITableViewController {
    var route: Route? {
        didSet {
            tableView.reloadData()
        }
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let route_ = route {
            return route_.steps.count
        }

        return 0
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell      = tableView.dequeueReusableCellWithIdentifier( "RouteStepCell", forIndexPath: indexPath )
        let routeStep = route!.steps[indexPath.row]

        cell.textLabel!.text = routeStep.shortExplanation
        cell.detailTextLabel!.text = routeStep.explanation

        return cell
    }
}
