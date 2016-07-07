//
//  ViewController.swift
//  ReachabilityMacSample
//
//  Created by Reda Lemeden on 28/11/2015.
//  Copyright © 2015 Ashley Mills. All rights reserved.
//

import Cocoa
import Reachability

class ViewController: NSViewController {
  @IBOutlet weak var networkStatus: NSTextField!
  @IBOutlet weak var hostNameLabel: NSTextField!

  var reachability: Reachability?

  override func viewDidLoad() {
    super.viewDidLoad()
    view.wantsLayer = true
    view.layer?.backgroundColor = NSColor.white().cgColor

    // Start reachability without a hostname intially
    setupReachability(hostName: nil, useClosures: true)
    startNotifier()

    // After 5 seconds, stop and re-start reachability, this time using a hostname
    let dispatchTime = DispatchTime.now() + .seconds(5)
    DispatchQueue.main.after(when: dispatchTime) {
      self.stopNotifier()
      self.setupReachability(hostName: "www.google.com", useClosures: true)
      self.startNotifier()
        
        // After another 5 seconds, stop and re-start reachability, this time using an invalid hostname
        let invalidHostDelayTime = DispatchTime.now() + .seconds(5)
        DispatchQueue.main.after(when: invalidHostDelayTime) {
            self.stopNotifier()
            self.setupReachability(hostName: "invalidhostname", useClosures: true)
            self.startNotifier()
        }
    }
  }

  func setupReachability(hostName: String?, useClosures: Bool) {
    hostNameLabel.stringValue = hostName != nil ? hostName! : "No host name"

    print("--- set up with host name: \(hostNameLabel.stringValue)")

    do {
      let reachability = try hostName != nil ? Reachability(hostname: hostName!) : Reachability.reachabilityForInternetConnection()
      self.reachability = reachability
    } catch ReachabilityError.FailedToCreateWithAddress(let address) {
      networkStatus.textColor = NSColor.red()
      networkStatus.stringValue = "Unable to create\nReachability with address:\n\(address)"
      return
    } catch {}

    if (useClosures) {
      reachability?.whenReachable = { reachability in
        self.updateLabelColourWhenReachable(reachability: reachability)
      }
      reachability?.whenUnreachable = { reachability in
        self.updateLabelColourWhenNotReachable(reachability: reachability)
      }
    } else {
      NotificationCenter.default().addObserver(self, selector: Selector(("reachabilityChanged:")), name: ReachabilityChangedNotification, object: reachability)
    }
  }

  func startNotifier() {
    print("--- start notifier")
    do {
      try reachability?.startNotifier()
    } catch {
      networkStatus.textColor = NSColor.red()
      networkStatus.stringValue = "Unable to start\nnotifier"
      return
    }
  }

  func stopNotifier() {
    print("--- stop notifier")
    reachability?.stopNotifier()
    NotificationCenter.default().removeObserver(self, name: NSNotification.Name(rawValue: ReachabilityChangedNotification), object: nil)
    reachability = nil
  }

  func updateLabelColourWhenReachable(reachability: Reachability) {
    print("\(reachability.description) - \(reachability.currentReachabilityString)")
    if reachability.isReachableViaWiFi() {
      self.networkStatus.textColor = NSColor.green()
    } else {
      self.networkStatus.textColor = NSColor.blue()
    }

    self.networkStatus.stringValue = reachability.currentReachabilityString
  }

  func updateLabelColourWhenNotReachable(reachability: Reachability) {
    print("\(reachability.description) - \(reachability.currentReachabilityString)")

    self.networkStatus.textColor = NSColor.red()

    self.networkStatus.stringValue = reachability.currentReachabilityString
  }

  func reachabilityChanged(note: NSNotification) {
    let reachability = note.object as! Reachability

    if reachability.isReachable() {
      updateLabelColourWhenReachable(reachability: reachability)
    } else {
      updateLabelColourWhenNotReachable(reachability: reachability)
    }
  }
}
