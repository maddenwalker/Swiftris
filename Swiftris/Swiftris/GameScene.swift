//
//  GameScene.swift
//  Swiftris
//
//  Created by Ryan Walker on 10/30/15.
//  Copyright (c) 2015 Ryan Walker. All rights reserved.
//

import SpriteKit

class GameScene: SKScene {
    required init?(coder aDecoder: NSCoder) {
        fatalError(NSLocalizedString("NSCoder Not Support", comment: "NSCoder not supported message"))
    }
    
    override init(size: CGSize) {
        super.init(size: size)
        
        anchorPoint = CGPoint(x: 0, y: 0)
        
        let background = SKSpriteNode(imageNamed: "Images/background")
        background.position = CGPoint(x: 0, y: 0)
        background.anchorPoint = CGPoint(x: 0, y: 1.0)
        addChild(background)
    }
    
    override func update(currentTime: CFTimeInterval) {
        /* Called before each frame is rendered */
    }
}
