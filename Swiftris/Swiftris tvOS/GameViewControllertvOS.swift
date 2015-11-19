//
//  GameViewControllertvOS.swift
//  Swiftris tvOS
//
//  Created by Ryan Walker on 11/18/15.
//  Copyright (c) 2015 Ryan Walker. All rights reserved.
//

import UIKit
import AVFoundation
import SpriteKit

class GameViewControllertvOS: UIViewController, SwiftrisDelegate, UIGestureRecognizerDelegate {
    
    var skView: SKView!
    var scene: GameScenetvOS!
    var swiftris:Swiftris!
    var panPointReference:CGPoint?
    var avGameBackgroundMusicPlayer:AVAudioPlayer?
    
    var tapGestureRecognizer: UITapGestureRecognizer!
    var panGestureRecognizer: UIPanGestureRecognizer!
    var swipeGestureRecognizer: UISwipeGestureRecognizer!

    @IBOutlet weak var scoreLabel: UILabel!
    @IBOutlet weak var levelLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        skView = view as! SKView
        
        scene = GameScenetvOS(size: skView.bounds.size)
        scene.scaleMode = .AspectFill
        
        scene.tick = didTick
        
        swiftris = Swiftris()
        swiftris.delegate = self
        PreviewRow = 9
        PreviewColumn = 14
        swiftris.beginGame()
        
        tapGestureRecognizer = UITapGestureRecognizer()
        tapGestureRecognizer.addTarget(self, action: Selector("handleTap"))
        
        panGestureRecognizer = UIPanGestureRecognizer()
        panGestureRecognizer.addTarget(self, action: Selector("handlePan:"))
        
        swipeGestureRecognizer = UISwipeGestureRecognizer()
        swipeGestureRecognizer.direction = .Down
        swipeGestureRecognizer.addTarget(self, action: Selector("handleSwipe"))
        
        let gestureRecognizers = [tapGestureRecognizer, panGestureRecognizer, swipeGestureRecognizer]
        
        for gestureRecognizer in gestureRecognizers {
            self.view.addGestureRecognizer(gestureRecognizer)
        }
        
        skView.presentScene(scene)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
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
        scene.stopTicking()
        scene.playSound("gameover.mp3")
        
        scene.animateCollapsingLines(swiftris.removeAllBlocks(), fallenBlocks: Array<Array<Block>>()) {}
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
        return
    }

    
    func repeatGame() {
        swiftris.beginGame()
    }
    
    //MARK: Buttons & Gestures
    
    func handleTap() {
        swiftris.rotateShape()
    }

    func handlePan(sender: UIPanGestureRecognizer) {
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
    
    func handleSwipe(gestureRecognizer: UISwipeGestureRecognizer) {
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

}
