//
//  AppDelegate.swift
//  STO Planner
//
//  Created by Maarten Billemont on 2015-09-24.
//  Copyright © 2015 Maarten Billemont. All rights reserved.
//

import UIKit
import Fabric
import Crashlytics

@UIApplicationMain
public class AppDelegate: PearlAppDelegate {
    public override func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject:AnyObject]?) -> Bool {
        Fabric.with( [ Crashlytics.self ] )

        return super.application( application, didFinishLaunchingWithOptions: launchOptions );
    }
}

