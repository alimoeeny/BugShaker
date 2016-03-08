//
//  AppDelegate.swift
//  BugShaker
//
//  Created by git on 12/18/2015.
//  Copyright (c) 2015 git. All rights reserved.
//

import UIKit

import BugShaker

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

  var window: UIWindow?

  func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
    /**
    *  Configure BugShaker with an array of email recipients (required)
    *  and an optional custom subject line to use for all bug reports.
    */

    BugShaker.configure(to: ["example@email.com"], subject: "Bug Report", body: "Hi Developers, I am reporting a bug where ... ")
    
    return true
  }

}
