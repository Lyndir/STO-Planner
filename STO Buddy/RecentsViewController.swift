//
// Created by Maarten Billemont on 2015-09-28.
// Copyright (c) 2015 Maarten Billemont. All rights reserved.
//

import UIKit

class RecentsViewController: UITableViewController {
    let locations = Locations.recent()

    @IBAction func didTapClear(sender: UIBarButtonItem) {
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return locations.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell     = tableView.dequeueReusableCellWithIdentifier( "RecentLocationCell", forIndexPath: indexPath )
        let location = locations[indexPath.row]

        cell.textLabel!.text = location.name

        return cell
    }
}
