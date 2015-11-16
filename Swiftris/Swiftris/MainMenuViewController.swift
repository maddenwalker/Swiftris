//
//  MainMenuViewController.swift
//  Swiftris
//
//  Created by Ryan Walker on 11/12/15.
//  Copyright © 2015 Ryan Walker. All rights reserved.
//

import UIKit
import GameKit

class MainMenuViewController: UIViewController, GKGameCenterControllerDelegate {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        authenticateGameCenter()
        
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
    
    func authenticateGameCenter() {
        let localPlayer = GKLocalPlayer.localPlayer()
        localPlayer.authenticateHandler = {(viewController, error) -> Void in
            if ((viewController) != nil) {
                self.presentViewController(viewController!, animated: true, completion: nil)
            } else {
                print("(GameCenter) Player Authenticated: \(GKLocalPlayer.localPlayer().authenticated)")
            }
        }
    }

    @IBAction func leaderboardButtonPressed(sender: UIButton) {
        showLeaderBoard()
        
    }
    
    func showLeaderBoard() {
        let gameCenterVC = GKGameCenterViewController()
        gameCenterVC.gameCenterDelegate = self
        gameCenterVC.viewState = GKGameCenterViewControllerState.Leaderboards
        gameCenterVC.leaderboardTimeScope = GKLeaderboardTimeScope.AllTime
        gameCenterVC.leaderboardIdentifier = "topScores"
        self.presentViewController(gameCenterVC, animated: true, completion: nil)
        
    }
    
    func gameCenterViewControllerDidFinish(gameCenterViewController: GKGameCenterViewController) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
}
