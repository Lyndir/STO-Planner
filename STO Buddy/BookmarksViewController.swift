//
// Created by Maarten Billemont on 2015-09-28.
// Copyright (c) 2015 Maarten Billemont. All rights reserved.
//

import UIKit

class BookmarksViewController: LocationResultsViewController {
    override func initLocations() -> Locations {
        return Locations.starred()
    }
}
