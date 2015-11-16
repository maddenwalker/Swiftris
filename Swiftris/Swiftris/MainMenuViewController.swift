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
    
    var achievements: [GKAchievement]?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        authenticateGameCenter()
        loadPreExistingAchievements()
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        let viewController: GameViewController = (segue.destinationViewController as? GameViewController)!
        if self.achievements != nil {
             viewController.achievements = self.achievements!   
        }
        
        if (segue.identifier == "timedGameSegue") {
            viewController.defaultTimer = 120
        } else if (segue.identifier == "endlessGameSegue") {
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
    
    //MARK: Game Center Implementation of Leaderboard

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
    
    //MARK: Game Center Implementation of Achievements
    
    @IBAction func achievementButtonPressed() {
        showAchievements()
    }
    
    func showAchievements() {
        let gameCenterVC = GKGameCenterViewController()
        gameCenterVC.gameCenterDelegate = self
        gameCenterVC.viewState = GKGameCenterViewControllerState.Achievements
        self.presentViewController(gameCenterVC, animated: true, completion: nil)
    }
    
    
    func loadPreExistingAchievements() {
        GKAchievement.loadAchievementsWithCompletionHandler({ (achievements, error) -> Void in
            if let achievements = achievements as [GKAchievement]! {
                self.achievements = achievements
                print("Successfully downloaded your past achievements")
                
                //TODO: Handle scenario where new achievement added to game and we do not receive this here
                
            } else if (achievements == nil) {
                print("This player has not made any progress towards any achievements, and we should initialize some achievements for them to do")
                self.achievements = []
                
                for (achievementID, _) in GameAchievements().allAchievements {
                    self.achievements!.append(GKAchievement.init(identifier: achievementID))
                }
                
                print("\(self.achievements)")
                
            } else {
                print("There was an error downloading previous achievements: \(error?.description)")
            }
        })
    }
    
    //MARK: GameCenterViewControllerDelegate Methods
    
    func gameCenterViewControllerDidFinish(gameCenterViewController: GKGameCenterViewController) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
}
