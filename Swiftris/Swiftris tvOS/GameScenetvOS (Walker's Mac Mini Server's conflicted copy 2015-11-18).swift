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

        BlockSize = ( size.height ) / 20
        super.init(size: size)
        
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
