//
// Created by Maarten Billemont on 2015-09-28.
// Copyright (c) 2015 Maarten Billemont. All rights reserved.
//

import UIKit

class BookmarksViewController: UITableViewController {
    @IBAction func cancel(sender: UIBarButtonItem) {
        navigationController?.dismissViewControllerAnimated( true, completion:nil )
    }
}