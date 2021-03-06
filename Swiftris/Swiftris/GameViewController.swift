//
//  GameViewController.swift
//  Swiftris
//
//  Created by Ryan Walker on 10/30/15.
//  Copyright (c) 2015 Ryan Walker. All rights reserved.
//

import UIKit
import SpriteKit
import AVFoundation
import GameKit

class GameViewController: UIViewController, SwiftrisDelegate, UIGestureRecognizerDelegate {
    
    var skView: SKView!
    var scene: GameScene!
    var swiftris:Swiftris!
    var timerDisplay: TimerDisplay!
    var gameTimer: NSTimer!
    var panPointReference:CGPoint?
    var avGameBackgroundMusicPlayer:AVAudioPlayer?
    var achievements: [GKAchievement] = []
    
    var defaultTimer: Int = 5
    var rowsBrokenInGame: Int = 0
    
    @IBOutlet weak var scoreLabel: UILabel!
    @IBOutlet weak var levelLabel: UILabel!
    @IBOutlet weak var gameTypeLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        skView = view as! SKView
        skView.multipleTouchEnabled = false;
        
        scene = GameScene(size: skView.bounds.size)
        scene.scaleMode = .AspectFill
        
        scene.tick = didTick
    
        setupTimer()
    
        swiftris = Swiftris()
        swiftris.delegate = self
        swiftris.beginGame()
        
        skView.presentScene(scene)
        loadAwfulBackgroundMusic()
        playPauseAwfulBackgroundMusic()
        
    }

    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    //MARK: Buttons & Gestures
    @IBAction func didTap(sender: UITapGestureRecognizer) {
        swiftris.rotateShape()
    }
    
    @IBAction func volumeButtonPressed(sender: UIButton) {
        playPauseAwfulBackgroundMusic()
        toggleButton(sender)
    }
    
    
    @IBAction func backButtonPressed() {
        swiftris.endGame()
    }
    
    @IBAction func didPan(sender: UIPanGestureRecognizer) {
        let currentPoint = sender.translationInView(self.view)
        
        if let originalPoint = panPointReference {
            if abs( currentPoint.x - originalPoint.x ) > (BlockSize * 0.9) {
                if sender.velocityInView(self.view).x > CGFloat(0) {
                    swiftris.moveShapeRight()
                    panPointReference = currentPoint
                } else {
                    swiftris.moveShapeLeft()
                    panPointReference = currentPoint
                }
            }
        } else if sender.state == .Began {
            panPointReference = currentPoint
        }
    }
    
    @IBAction func didSwipe(sender: UISwipeGestureRecognizer) {
        swiftris.dropShape()
    }
    
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWithGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailByGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer is UISwipeGestureRecognizer {
            if otherGestureRecognizer is UIPanGestureRecognizer {
                return true
            }
        } else if gestureRecognizer is UIPanGestureRecognizer {
            if otherGestureRecognizer is UITapGestureRecognizer {
                return true
            }
        }
        
        return false
    }
    
    //MARK: Game Mechanics
    func didTick() {
        swiftris.letShapeFall()
    }
    
    func nextShape() {
        let newShapes = swiftris.newShape()
        guard let fallingShape = newShapes.fallingShape else {
            return
        }
        
        self.scene.addPreviewShapeToScene(newShapes.nextShape!) {}
        self.scene.movePreviewShape(fallingShape) {
            self.view.userInteractionEnabled = true
            self.scene.startTicking()
        }
    }
    
    //MARK: SwiftrisDelegate Methods
    func gameDidBegin(swiftris: Swiftris) {
        
        if defaultTimer > 0 {
             startTimer()
        }
        
        levelLabel.text = "\(swiftris.level)"
        scoreLabel.text = "\(swiftris.score)"
        scene.tickLengthMillis = TickLengthLevelOne
        
        if swiftris.nextShape != nil && swiftris.nextShape!.blocks[0].sprite == nil {
            scene.addPreviewShapeToScene(swiftris.nextShape!) {
                self.nextShape()
            }
        } else {
            nextShape()
        }
    }
    
    
    func gameDidEnd(swiftris: Swiftris) {
        view.userInteractionEnabled = false
        scene.stopTicking()
        scene.playSound("gameover.mp3")
        
        reportScoresToGameCenter()
        
        if defaultTimer > 0 {
            stopTimer()
        }
        
        scene.animateCollapsingLines(swiftris.removeAllBlocks(), fallenBlocks: Array<Array<Block>>()) {
            self.presentUserWithOptionsToReplayOrQuit()
        }
    }
    
    func gameDidLevelUp(swiftris: Swiftris) {
        levelLabel.text = "\(swiftris.level)"
        if scene.tickLengthMillis >= 100 {
            scene.tickLengthMillis -= 100
        } else if scene.tickLengthMillis > 50 {
            scene.tickLengthMillis -= 50
        }
        
        scene.playSound("levelup.mp3")
    }
    
    func gameShapeDidDrop(swiftris: Swiftris) {
        scene.stopTicking()
        scene.redrawShape(swiftris.fallingShape!) {
            swiftris.letShapeFall()
        }
        scene.playSound("drop.mp3")
    }
    
    func gameShapeDidLand(swiftris: Swiftris) {
        scene.stopTicking()
        self.view.userInteractionEnabled = false
        
        let removedLines = swiftris.removeCompletedLines()
        if removedLines.linesRemoved.count > 0 {
            self.scoreLabel.text = "\(swiftris.score)"
            scene.animateCollapsingLines(removedLines.linesRemoved, fallenBlocks: removedLines.fallenBlocks) {
                self.gameShapeDidLand(swiftris)
            }
            
            scene.playSound("bomb.mp3")
        } else {
            nextShape()
        }
    }
    
    func gameShapeDidMove(swiftris: Swiftris) {
        scene.redrawShape(swiftris.fallingShape!) {}
    }
    
    func gameDidBreakBlocks(rowsBroken: Int) {
        
        for achievement in achievements where achievement.completed != true {
            achievement.percentComplete += ( 100 * Double(rowsBroken) / Double(GameAchievements().allAchievements[achievement.identifier!]!) )
        }
        
        recordAchievements()
        
    }

    
    //MARK: Helper Methods
    
    func loadAwfulBackgroundMusic() {
        if let gameBackgroundMusicURL:NSURL? = NSURL(fileURLWithPath:NSBundle.mainBundle().pathForResource("theme", ofType: "mp3")!) {
            do {
                avGameBackgroundMusicPlayer = try AVAudioPlayer(contentsOfURL: gameBackgroundMusicURL!)
                avGameBackgroundMusicPlayer?.prepareToPlay()
            } catch {
                print("error occurred playing background music")
            }
        }
    }
    
    func playPauseAwfulBackgroundMusic() {
        if avGameBackgroundMusicPlayer?.playing != true {
            avGameBackgroundMusicPlayer?.play()
        } else {
            avGameBackgroundMusicPlayer?.pause()
        }

    }
    
    func toggleButton(button: UIButton) {
        if button.imageForState(.Normal) == UIImage(named: "volume-mute.png") {
            button.setImage(UIImage(named: "ios-volume-high.png"), forState: .Normal)
        } else {
            button.setImage(UIImage(named: "volume-mute.png"), forState: .Normal)
        }
    }
    
    func setupTimer() {
        if ( defaultTimer > 0 ) {
            timerDisplay = TimerDisplay(timeInSeconds: defaultTimer)
            self.gameTimer = NSTimer(timeInterval: 1.0, target: self, selector: "updateCurrentTimeLeft", userInfo: nil, repeats: true)
        } else {
            timerDisplay = TimerDisplay(endlessGame: true)
        }
        
        updateTimeLabel(timerDisplay.timeAsString())
    }
    
    func startTimer() {
        NSRunLoop.mainRunLoop().addTimer(self.gameTimer, forMode: NSRunLoopCommonModes)
    }
    
    func stopTimer() {
        self.gameTimer.invalidate()
    }
    
    func updateCurrentTimeLeft() {
        if timerDisplay.timeInSeconds >= 1 {
            timerDisplay.timeInSeconds--
            updateTimeLabel(timerDisplay.timeAsString())
        } else {
            updateTimeLabel("Game Over")
            swiftris.endGame()
        }
    }
    
    func updateTimeLabel(timeLeftString: String) {
        gameTypeLabel.text = timeLeftString
    }
    
    func presentUserWithOptionsToReplayOrQuit() {
        let alertViewController = UIAlertController(title: "Nice Job Rockstar!", message: "The game is over, or is it?", preferredStyle: .Alert)
        
        let playAgainButton = UIAlertAction(title: "Play Again", style: .Default) { (action) -> Void in
            self.resetGameBoard(self.repeatGame)
        }
        let quitButton = UIAlertAction(title: "Get me out of here", style: .Destructive) { (action) -> Void in
            self.navigationController?.popViewControllerAnimated(true)
            self.clearGameBoad()
        }
        
        alertViewController.addAction(playAgainButton)
        alertViewController.addAction(quitButton)
        
        self.presentViewController(alertViewController, animated: true, completion: nil)
        
    }
    
    func repeatGame() {
        setupTimer()
        swiftris.beginGame()
    }
    
    func resetGameBoard(completion: () -> ()) {
        updateTimeLabel("Good Luck!")
        let shapesToRemove = [swiftris.fallingShape!, swiftris.nextShape!]
        scene.removeShapes(shapesToRemove) {
                completion()
        }
    }
    
    //MARK: Tear Down Methods
    
    func clearGameBoad () {
        skView.removeFromSuperview()
        skView = nil
        avGameBackgroundMusicPlayer?.stop()
        avGameBackgroundMusicPlayer = nil
    }
    
    //MARK: GameCenter Implementation
    func reportScoresToGameCenter() {
        if GKLocalPlayer.localPlayer().authenticated {
            let gkScore = GKScore(leaderboardIdentifier: "topScores")
            gkScore.value = Int64(swiftris.score)
            GKScore.reportScores([gkScore]) { (error) -> Void in
                if (error != nil) {
                    print("Error reporting scores: \(error!.description)")
                } else {
                    print("Top Score of \(gkScore.value) reported successfully to Game Center")
                }
            }
        }
    }
    
    func recordAchievements() {
        
        print("Attempting to update achievements: \(achievements)")
        
        GKAchievement.reportAchievements(achievements) { (error) -> Void in
            if (error != nil) {
                print("Error updating achievements: \(error?.description)")
            }
        }
    }
}
