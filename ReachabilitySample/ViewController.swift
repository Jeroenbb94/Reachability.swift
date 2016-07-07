//
//  ViewController.swift
//  Reachability Sample
//
//  Created by Ashley Mills on 22/09/2014.
//  Copyright (c) 2014 Joylord Systems. All rights reserved.
//

import UIKit
import Reachability

class ViewController: UIViewController {

    @IBOutlet weak var networkStatus: UILabel!
    @IBOutlet weak var hostNameLabel: UILabel!
    
    var reachability: Reachability?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Start reachability without a hostname intially
        setupReachability(hostName: nil, useClosures: true)
        startNotifier()

        // After 5 seconds, stop and re-start reachability, this time using a hostname
        let delayTime = DispatchTime.now() + .seconds(5)
        DispatchQueue.main.after(when: delayTime) {
            self.stopNotifier()
            self.setupReachability(hostName: "google.com", useClosures: true)
            self.startNotifier()

            // After another 5 seconds, stop and restart reachability, this time using an invalid hostname
            let invalidHostDelayTime = DispatchTime.now() + .seconds(5)
            DispatchQueue.main.after(when: invalidHostDelayTime) {
                self.stopNotifier()
                self.setupReachability(hostName: "invalidhost", useClosures: true)
                self.startNotifier()
            }
        }
    }
    
    func setupReachability(hostName: String?, useClosures: Bool) {
        hostNameLabel.text = hostName != nil ? hostName : "No host name"
        
        print("--- set up with host name: \(hostNameLabel.text!)")

        do {
            let reachability = try hostName == nil ? Reachability.reachabilityForInternetConnection() : Reachability(hostname: hostName!)
            self.reachability = reachability
        } catch ReachabilityError.FailedToCreateWithAddress(let address) {
            networkStatus.textColor = UIColor.red()
            networkStatus.text = "Unable to create\nReachability with address:\n\(address)"
            return
        } catch {}
        
        if (useClosures) {
            reachability?.whenReachable = { reachability in
                DispatchQueue.main.async() {
                    self.updateLabelColourWhenReachable(reachability: reachability)
                }
            }

            reachability?.whenUnreachable = { reachability in
                DispatchQueue.main.async() {
                    self.updateLabelColourWhenNotReachable(reachability: reachability)
                }
            }
        } else {
            NotificationCenter.default.addObserver(self, selector: Selector(("reachabilityChanged:")), name: NSNotification.Name(rawValue: ReachabilityChangedNotification), object: reachability)
        }
    }
    
    func startNotifier() {
        print("--- start notifier")
        do {
            try reachability?.startNotifier()
        } catch {
            networkStatus.textColor = UIColor.red()
            networkStatus.text = "Unable to start\nnotifier"
            return
        }
    }
    
    func stopNotifier() {
        print("--- stop notifier")
        reachability?.stopNotifier()
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: ReachabilityChangedNotification), object: nil)
        reachability = nil
    }
    
    func updateLabelColourWhenReachable(reachability: Reachability) {
        print("\(reachability.description) - \(reachability.currentReachabilityString)")
        if reachability.isReachableViaWiFi() {
            self.networkStatus.textColor = UIColor.green()
        } else {
            self.networkStatus.textColor = UIColor.blue()
        }
        
        self.networkStatus.text = reachability.currentReachabilityString
    }

    func updateLabelColourWhenNotReachable(reachability: Reachability) {
        print("\(reachability.description) - \(reachability.currentReachabilityString)")

        self.networkStatus.textColor = UIColor.red()
        
        self.networkStatus.text = reachability.currentReachabilityString
    }

    
    func reachabilityChanged(note: NSNotification) {
        let reachability = note.object as! Reachability
        
        if reachability.isReachable() {
            updateLabelColourWhenReachable(reachability: reachability)
        } else {
            updateLabelColourWhenNotReachable(reachability: reachability)
        }
    }
    
    deinit {
        stopNotifier()
    }

}


