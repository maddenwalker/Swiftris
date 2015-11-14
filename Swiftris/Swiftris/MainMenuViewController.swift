//
//  MainMenuViewController.swift
//  Swiftris
//
//  Created by Ryan Walker on 11/12/15.
//  Copyright © 2015 Ryan Walker. All rights reserved.
//

import UIKit

class MainMenuViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if (segue.identifier == "timedGameSegue") {
            let viewController: GameViewController = (segue.destinationViewController as? GameViewController)!
            viewController.defaultTimer = 120
        } else if (segue.identifier == "endlessGameSegue") {
            let viewController: GameViewController = (segue.destinationViewController as? GameViewController)!
            viewController.defaultTimer = 0
        }
    }
    
}
