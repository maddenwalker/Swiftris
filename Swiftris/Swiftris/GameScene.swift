//
//  GameScene.swift
//  Swiftris
//
//  Created by Ryan Walker on 10/30/15.
//  Copyright (c) 2015 Ryan Walker. All rights reserved.
//

import SpriteKit

var BlockSize:CGFloat = 20

let TickLengthLevelOne = NSTimeInterval(600)

class GameScene: SKScene {
    
    let gameLayer = SKNode()
    let shapeLayer = SKNode()
    var layerPosition:CGPoint!
    
    var tick:(() -> ())?
    var tickLengthMillis = TickLengthLevelOne
    var lastTick:NSDate?
    
    var textureCache = Dictionary<String, SKTexture>()
    
    
    required init?(coder aDecoder: NSCoder) {
        fatalError(NSLocalizedString("NSCoder Not Support", comment: "NSCoder not supported message"))
    }
    
    override init(size: CGSize) {
        super.init(size: size)
        
        anchorPoint = CGPoint(x: 0, y: 1.0)
        
        calculateLayerPosition()
        BlockSize = calculateBlockSize(size)
        
        let background = SKSpriteNode(imageNamed: "background")
        background.position = CGPoint(x: 0, y: 0)
        background.anchorPoint = CGPoint(x: 0, y: 1.0)
        background.size = size
        addChild(background)
        
        addChild(gameLayer)
        
        let gameBoardTexture = SKTexture(imageNamed: "gameboard")
        let gameBoardWidth = ( BlockSize * CGFloat(NumColumns) )
        let gameBoardHeight = ( BlockSize * CGFloat(NumRows) )
        let gameBoard = SKSpriteNode(texture: gameBoardTexture, size: CGSizeMake(gameBoardWidth, gameBoardHeight))
        
        gameBoard.anchorPoint = CGPoint(x: 0, y: 1.0)
        gameBoard.position = layerPosition
        
        shapeLayer.position = layerPosition
        shapeLayer.addChild(gameBoard)
        gameLayer.addChild(shapeLayer)
        
    }

    
    override func update(currentTime: CFTimeInterval) {
        /* Called before each frame is rendered */
        guard let lastTick = lastTick else {
            return
        }
        
        let timePassed = lastTick.timeIntervalSinceNow * -1000.0
        if timePassed > tickLengthMillis {
            self.lastTick = NSDate()
            tick?()
        }
    }
    
    func calculateBlockSize(size: CGSize) -> CGFloat {
        return ( size.width - 16 ) * ( 1 / 15 )
    }
    
    func calculateLayerPosition() {
        layerPosition = CGPoint(x: 8, y: -44)
    }
    
    func startTicking() {
        lastTick = NSDate()
    }
    
    func stopTicking() {
        lastTick = nil
    }
    
    func playSound(sound:String) {
        runAction(SKAction.playSoundFileNamed(sound, waitForCompletion: false))
    }
    
    
    func pointForColumn(column: Int, row: Int) -> CGPoint {
        let x = layerPosition.x + ( CGFloat(column) * BlockSize ) + ( BlockSize / 2 )
        let y = layerPosition.y - (( CGFloat(row) * BlockSize ) + ( BlockSize / 2 ))
        return CGPointMake(x, y)
    }
    
    func addPreviewShapeToScene(shape:Shape, completion:() -> ()) {
        for block in shape.blocks {
            var texture = textureCache[block.spriteName]
            if texture == nil {
                texture = SKTexture(imageNamed: block.spriteName)
                textureCache[block.spriteName] = texture
            }
            
            let sprite = SKSpriteNode(texture: texture, size: CGSizeMake(BlockSize, BlockSize))
            
            sprite.position = pointForColumn(block.column, row: block.row - 2)
            
            shapeLayer.addChild(sprite)
            block.sprite = sprite
            
            sprite.alpha = 0
            
            let moveAction = SKAction.moveTo(pointForColumn(block.column, row: block.row), duration: NSTimeInterval(0.2))
            moveAction.timingMode = .EaseOut
            let fadeInAction = SKAction.fadeAlphaTo(0.7, duration: 0.4)
            fadeInAction.timingMode = .EaseOut
            sprite.runAction(SKAction.group([moveAction, fadeInAction]))
            
        }
        
        runAction(SKAction.waitForDuration(0.4), completion: completion)
    }
    
    func movePreviewShape(shape: Shape, completion:() -> ()) {
        for block in shape.blocks {
            let sprite = block.sprite!
            let moveTo = pointForColumn(block.column, row: block.row)
            let moveToAction:SKAction = SKAction.moveTo(moveTo, duration: 0.2)
            moveToAction.timingMode = .EaseOut
            sprite.runAction(
                SKAction.group([moveToAction, SKAction.fadeAlphaTo(1.0, duration: 0.2)])
            )
        }
        
        runAction(SKAction.waitForDuration(0.2), completion:completion)
    }
    
    
    func redrawShape(shape:Shape, completion:() -> ()) {
        for block in shape.blocks {
            let sprite = block.sprite!
            let moveTo = pointForColumn(block.column, row: block.row)
            let moveToAction:SKAction = SKAction.moveTo(moveTo, duration: 0.05)
            moveToAction.timingMode = .EaseOut
            if block == shape.blocks.last {
                sprite.runAction(moveToAction, completion: completion)
            } else {
                sprite.runAction(moveToAction)
            }
        }
    }
    
    func removeShapes(shapes:Array<Shape>, completion: () -> ()) {
        var longestDuration: NSTimeInterval = 0
        var animationDuration: NSTimeInterval = 0
        
        for shape in shapes {
            for block in shape.blocks {
                let sprite = block.sprite!
                let randomDuration = NSTimeInterval(arc4random_uniform(2)) + 0.01
                animationDuration += randomDuration
                let dissolveAction = SKAction.fadeOutWithDuration(randomDuration)
                sprite.runAction(dissolveAction)
            }
        }
        
        longestDuration = max(longestDuration, 1)
        
        runAction(SKAction.waitForDuration(longestDuration), completion: completion)
    }
    
    func animateCollapsingLines(linesToRemove: Array<Array<Block>>, fallenBlocks: Array<Array<Block>>, completion: () -> ()) {
        var longestDuration: NSTimeInterval = 0
        
        for (columnIdx, column) in fallenBlocks.enumerate() {
            for (blockIdx, block) in column.enumerate() {
                let newPosition = pointForColumn(block.column, row: block.row)
                let sprite = block.sprite!
                
                let delay = (NSTimeInterval(columnIdx) * 0.05 ) + (NSTimeInterval(blockIdx) * 0.05 )
                let duration = NSTimeInterval( ( ( sprite.position.y - newPosition.y) / BlockSize ) * 0.1 )
                let moveAction = SKAction.moveTo(newPosition, duration: duration)
                moveAction.timingMode = .EaseOut
                sprite.runAction(
                    SKAction.sequence([
                        SKAction.waitForDuration(delay),
                        moveAction]))
                longestDuration = max(longestDuration, duration + delay)
            }
        }
        
        for (_ , row) in linesToRemove.enumerate() {
            for (_ , block) in row.enumerate() {
                
                let randomRadius = CGFloat(UInt(arc4random_uniform(400) + 100))
                let goLeft = arc4random_uniform(100) % 2 == 0
                
                var point = pointForColumn(block.column, row: block.row)
                point = CGPointMake(point.x + (goLeft ? -randomRadius : randomRadius), point.y)
                
                let randomDuration = NSTimeInterval(arc4random_uniform(2)) + 0.5
                
                var startAngle = CGFloat(M_PI)
                var endAngle = startAngle * 2
                
                if goLeft {
                    endAngle = startAngle
                    startAngle = 0
                }
                
                let archPath = UIBezierPath(arcCenter: point, radius: randomRadius, startAngle: startAngle, endAngle: endAngle, clockwise: goLeft)
                let archAction = SKAction.followPath(archPath.CGPath, asOffset: false, orientToPath: true, duration: randomDuration)
                archAction.timingMode = .EaseIn
                let sprite = block.sprite!
                
                sprite.zPosition = 100
                sprite.runAction(
                    SKAction.sequence(
                        [SKAction.group([archAction, SKAction.fadeOutWithDuration(NSTimeInterval(randomDuration))]),
                        SKAction.removeFromParent()]
                    )
                )
                
            }
        }
        
        runAction(SKAction.waitForDuration(longestDuration), completion: completion)
    }
    
}
