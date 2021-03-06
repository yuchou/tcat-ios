//
//  AppDelegate.swift
//  TCAT
//
//  Created by Kevin Greer on 9/7/16.
//  Copyright © 2016 cuappdev. All rights reserved.
//

import UIKit
import Firebase
import GoogleMaps
import GooglePlaces
import SwiftyJSON
import Fabric
import Crashlytics
import SafariServices
import SwiftRegister

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    let userDefaults = UserDefaults.standard
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        JSONFileManager.shared.deleteAllJSONs()
        
        // Set Up Google Services
        FirebaseApp.configure()
        GMSServices.provideAPIKey(Keys.googleMaps.value)
        GMSPlacesClient.provideAPIKey(Keys.googlePlaces.value)
        
        // Set Up Register, Fabric / Crashlytics (RELEASE)
        #if !DEBUG
            Crashlytics.start(withAPIKey: Keys.fabricAPIKey.value)
            RegisterSession.startLogging()
        #endif
        
        // Log basic information
        let payload = AppLaunchedPayload()
        RegisterSession.shared?.log(payload)
        
        // Check app version
        if let version = userDefaults.value(forKey: Constants.UserDefaults.version) as? String {
            if version != Constants.App.version {
                // TODO: User has just updated the app.
            }
        }
        
        // Set version to be current version
        userDefaults.set(Constants.App.version, forKey: Constants.UserDefaults.version)
        
        // Initalize User Defaults
        if userDefaults.value(forKey: Constants.UserDefaults.onboardingShown) == nil {
            userDefaults.set(false, forKey: Constants.UserDefaults.onboardingShown)
        }
        if userDefaults.value(forKey: Constants.UserDefaults.recentSearch) == nil {
            userDefaults.set([Any](), forKey: Constants.UserDefaults.recentSearch)
        }
        if userDefaults.value(forKey: Constants.UserDefaults.favorites) == nil {
            userDefaults.set([Any](), forKey: Constants.UserDefaults.favorites)
        }
        
        // Track number of app opens for Store Review prompt
        StoreReviewHelper.incrementAppOpenedCount()
        
        // Debug - Always Show Onboarding
        // userDefaults.set(false, forKey: Constants.UserDefaults.onboardingShown)
        
        getBusStops()
        
        // Initalize first view based on context
        let showOnboarding = !userDefaults.bool(forKey: Constants.UserDefaults.onboardingShown)
        let rootVC = showOnboarding ? OnboardingViewController(initialViewing: true) : HomeViewController()
        let navigationController = showOnboarding ? OnboardingNavigationController(rootViewController: rootVC) :
            CustomNavigationController(rootViewController: rootVC)
        UIApplication.shared.statusBarStyle = showOnboarding ? .lightContent : .default
        
        // Initalize window without storyboard
        self.window = UIWindow(frame: UIScreen.main.bounds)
        self.window!.rootViewController = navigationController
        self.window?.makeKeyAndVisible()
        
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here y/Users/mattbarker016ou can undo many of the changes made on entering the background.
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }

    /* Get all bus stops and store in userDefaults */
    func getBusStops() {
        Network.getAllStops().perform(withSuccess: { stops in
            let allBusStops = stops.allStops
            if allBusStops.isEmpty {
                let title = "Couldn't Fetch Bus Stops"
                let message = "The app will continue trying on launch. You can continue to use the app as normal."
                let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
                alertController.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
                UIApplication.shared.keyWindow?.presentInApp(alertController)
            } else {
                let data = NSKeyedArchiver.archivedData(withRootObject: allBusStops)
                self.userDefaults.set(data, forKey: Constants.UserDefaults.allBusStops)
            }
        }, failure: { error in
            print("getBusStops error:", error)
        })
    }
    
}

extension UIWindow {
    
    /// Find the visible view controller in the root navigation controller and present passed in view controlelr.
    func presentInApp(_ viewController: UIViewController) {
        (rootViewController as? UINavigationController)?.visibleViewController?.present(viewController, animated: true)
    }

}

