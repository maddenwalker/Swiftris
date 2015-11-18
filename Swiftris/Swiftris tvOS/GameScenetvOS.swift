//
//  GameScenetvOS.swift
//  Swiftris
//
//  Created by Ryan Walker on 11/18/15.
//  Copyright © 2015 Ryan Walker. All rights reserved.
//

import SpriteKit

class GameScenetvOS: GameScene {
    
    override init(size: CGSize) {
        super.init(size: size)
        
    }
    
    override func calculateBlockSize(size: CGSize) -> CGFloat {
        return ( size.height + layerPosition.y * 4 ) / 20
    }
    
    override func calculateLayerPosition() {
        layerPosition = CGPoint(x: 25, y: -10)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
