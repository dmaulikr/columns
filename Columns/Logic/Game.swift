

//
//  Game.swift
//  Columns
//
//  Created by Greg Sutton on 27/03/2016.
//  Copyright © 2016 Darksheep. All rights reserved.
//

import Foundation

enum GameState {
    case start
    case play
    case pause
    case resume
    case move
    case endMove
}

enum MoveState {
    case new
    case left
    case right
    case rotate
    case drop
}

enum Value : String {
    case None = "-"
    case A = "A"
    case B = "B"
    case C = "C"
}

struct Location {
    let x: Int
    let y: Int
}

// This needs to be an object to get passed in a notification
class Piece {
    let location: Location  // Bottom x, y
    let values: [Value]
    
    init( location: Location, values: [Value] ) {
        self.location = location
        self.values = values
    }
}

class Tile {
    let location: Location
    let value: Value
    
    init( location: Location, value: Value ) {
        self.location = location
        self.value = value
    }
}

let cGridWidth = 8
let cGridHeight = 12

let cNotificationGamePlaying = Notification.Name( rawValue: "cNotificationGamePlaying" )
let cNotificationGamePaused = Notification.Name( rawValue: "cNotificationGamePaused" )
let cNotificationGameResumed = Notification.Name( rawValue: "cNotificationGamedResumed" )
let cNotificationGameEnd = Notification.Name( rawValue: "cNotificationGameEnd" )

let cNotificationKeyPiece = "cNotificationKeyPiece"
let cNotificationKeyTime = "cNotificationKeyTime"
let cNotificationKeyTiles = "cNotificationKeyTiles"
let cNotificationKeyDelta = "cNotificationKeyDelta"
let cNotificationKeyScore = "cNotificationKeyScore"

let cNotificationUpdateScore = Notification.Name( rawValue: "cNotificationUpdateScore" )

let cNotificationAddTiles = Notification.Name( rawValue: "cNotificationAddTiles" )
let cNotificationRemoveTiles = Notification.Name( rawValue: "cNotificationRemoveTiles" )
let cNotificationMoveTilesDown = Notification.Name( rawValue: "cNotificationMoveTilesDown" )   // cNotificationKeyTiles, and cNotificationKeyDelta

let cNotificationPieceRemove = Notification.Name( rawValue: "cNotificationPieceRemove" )

let cNotificationPieceNew = Notification.Name( rawValue: "cNotificationPieceNew" )
let cNotificationPieceDown = Notification.Name( rawValue: "cNotificationPieceDown" )           // cNotificationKeyPiece and cNotificationKeyTime
let cNotificationPieceRotate = Notification.Name( rawValue: "cNotificationPieceRotate" )
let cNotificationPieceDrop = Notification.Name( rawValue: "cNotificationPieceDrop" )
let cNotificationPieceLeft = Notification.Name( rawValue: "cNotificationPieceLeft" )
let cNotificationPieceRight = Notification.Name( rawValue: "cNotificationPieceRight" )

class Game {
    var grid: [[Value]] = []    // Empty array placeholder
    
    var gameState = GameState.start
    var moveState = MoveState.new
    
    var gameRound = 0
    var gameScore = 0
    
    var baseDescentTime = 0.7
    var descentTime: Double {
        let roundModifier = 1.0 - pow( 0.9, Double( gameRound ) )
        return self.baseDescentTime - roundModifier
    }
    
    var currentPiece: Piece?
    
    func columnHeight( x: Int ) -> Int {
        for y in 0..<cGridHeight {
            if .None == grid[x][y] {
                return y
            }
        }
        
        return cGridHeight
    }
}

// MARK: GameState UI Interaction
extension Game {
    func playPause() {
        // Play
        switch gameState {
        case .start:
            gameState = .play
        case .play, .move:
            gameState = .pause
        case .pause:
            gameState = .resume
        default:
            break
        }
        gameProceed()
    }
    
    func restart() {
        gameState = .start
        playPause()
    }
}

// MARK: GameState
extension Game {
    func gameProceed() {
        switch gameState {
        case .play:
            play()
        case .endMove:
            endMove()
        case .pause:
            pause()
        case .resume:
            resume()
        default:
            print( "GAME STATE DEFAULT" )
        }
    }
    
    func play() {
        currentPiece = nil
        grid = Array( repeating: Array( repeating: .None, count: cGridHeight ), count: cGridWidth )
        NotificationCenter.default.post( name: cNotificationGamePlaying, object: self )
        moveState = .new
        moveProceed()
        gameState = .move
        
        gameScore = 0
        NotificationCenter.default.post( name: cNotificationUpdateScore, object: self, userInfo: [cNotificationKeyScore: gameScore] )
    }
    
    func endMove() {
        placeTiles()
        
        let completion = {
            if self.failedGame() {
                self.gameState = .start
                if let piece = self.currentPiece {
                    NotificationCenter.default.post( name: cNotificationGameEnd, object: self, userInfo: [cNotificationKeyPiece: piece] )
                }
                else {
                    NotificationCenter.default.post( name: cNotificationGameEnd, object: self )
                }
                print( "Game End" )
            }
            else {
                self.gameState = .move
                self.moveState = .new
                self.moveProceed()
            }
        }
 
        DispatchQueue.main.asyncAfter( deadline: DispatchTime.now() + DispatchTimeInterval.milliseconds( 200 ) ) {
            self.checkForRuns( completion )
        }
    }
    
    func pause() {
        NotificationCenter.default.post( name: cNotificationGamePaused, object: self )
    }
    
    func resume() {
        self.gameState = .move
        downPiece()
        NotificationCenter.default.post( name: cNotificationGameResumed, object: self )
    }
    
    func failedGame() -> Bool {
        guard let piece = currentPiece else { return false }
        
        // Is it over the height? Remember location is zero based, cGridHeight is one based
        if columnHeight( x: piece.location.x ) >= cGridHeight {
            return true
        }
        
        return false
    }
    
    func placeTiles() {
        guard let piece = currentPiece else { return }
        let location = piece.location
        // value1 is at the bottom
        var tiles = [Tile]()
        var tileLocation: Location
        for i in 0...2 {
            tileLocation = Location( x: location.x, y: location.y + i )
            // Don't add tiles if it outside bounds
            if location.y + i < cGridHeight {
                grid[tileLocation.x][tileLocation.y] = piece.values[i]
            }
            tiles.append( Tile( location: tileLocation, value: piece.values[i] ) )
        }
        NotificationCenter.default.post( name: cNotificationAddTiles, object: self, userInfo: [cNotificationKeyTiles: tiles] )
        NotificationCenter.default.post( name: cNotificationPieceRemove, object: self )
    }
    
    func checkForRuns( _ completion: @escaping () -> Void ) {
        DispatchQueue.global( qos: .userInitiated ).async {
            let start = Date()
            let operationQueue = OperationQueue()
            let steppers: [StepperOperation] = [VerticalStepper( game: self ), HorizontalStepper( game: self ), DiagonalRightStepper( game: self ), DiagonalLeftStepper( game: self )]
            operationQueue.addOperations( steppers, waitUntilFinished: true )
            var tilesToRemove = [Tile]()
            for stepper in steppers {
                for location in stepper.locations {
                    if .None != self.grid[location.x][location.y] {
                        let value = self.grid[location.x][location.y]
                        tilesToRemove.append( Tile( location: location, value: value ) )
                        self.grid[location.x][location.y] = .None
                    }
                }
            }
            
            let timeTaken = Date().timeIntervalSince( start )
            print( "\(type( of: self )).checkForRuns \(timeTaken) secs" )

            if 0 == tilesToRemove.count {
                DispatchQueue.main.async {
                    completion()
                }
            }
            else {
                DispatchQueue.main.async {
                    // Update Score
                    self.gameScore += tilesToRemove.count + Int( pow( Double( tilesToRemove.count - 3 ), 2.0 ) )
                    NotificationCenter.default.post( name: cNotificationUpdateScore, object: self, userInfo: [cNotificationKeyScore: self.gameScore] )

                    // Remove tiles
                    NotificationCenter.default.post( name: cNotificationRemoveTiles, object: self, userInfo: [cNotificationKeyTiles: tilesToRemove] )
                    
                    // Gravity Drop
                    self.gavityDrop()
                }
                
                // Check for runs again
                DispatchQueue.main.asyncAfter( deadline: DispatchTime.now() + DispatchTimeInterval.milliseconds( 300 ) ) {
                    self.checkForRuns( completion )
                }
            }
        }
    }
    
    func gavityDrop() {
        for x in 0 ..< cGridWidth {
            var tiles = [Tile]()
            var delta = 0
            for y in 0..<cGridHeight {
                let value = grid[x][y]
                if .None == value {
                    // Move tiles so far, before delta increased (they have only been added if there is a delta)
                    if 0 != tiles.count {
                        NotificationCenter.default.post( name: cNotificationMoveTilesDown, object: self, userInfo: [cNotificationKeyTiles: tiles, cNotificationKeyDelta: delta] )
                        tiles.removeAll()
                    }
                    delta += 1
                }
                else if delta > 0 {
                    tiles.append( Tile( location: Location( x: x, y: y ), value: value ) )
                    grid[x][y] = .None
                    grid[x][y - delta] = value
                }
            }
            // Check once more for tiles to move
            if 0 != tiles.count {
                NotificationCenter.default.post( name: cNotificationMoveTilesDown, object: self, userInfo: [cNotificationKeyTiles: tiles, cNotificationKeyDelta: delta] )
                tiles.removeAll()
            }
        }
    }
}

// MARK: MoveState UI Interaction
extension Game {
    func rotate() {
        guard .move == gameState && nil != currentPiece else { return }
        moveState = .rotate
        moveProceed()
    }
    
    func drop() {
        guard .move == gameState && nil != currentPiece else { return }
        moveState = .drop
        moveProceed()
        // Prevent left/right/rotate coming through
        gameState = .endMove
    }
    
    func left() {
        guard .move == gameState && nil != currentPiece else { return }
        moveState = .left
        moveProceed()
    }
    
    func right() {
        guard .move == gameState && nil != currentPiece else { return }
        moveState = .right
        moveProceed()
    }
}

// MARK: MoveState
extension Game {
    func moveProceed() {
        switch moveState {
        case .new:
            newPiece()
        case .rotate:
            rotatePiece()
        case .drop:
            dropPiece()
        case .left:
            leftPiece()
        case .right:
            rightPiece()
        }
    }
    
    func randomValue() -> Value {
        switch arc4random_uniform( 3 ) {
        case 0:
            return .A
        case 1:
            return .B
        default:
            return .C
        }
    }
    
    func downTimer() {
        DispatchQueue.main.asyncAfter( deadline: DispatchTime.now() + DispatchTimeInterval.milliseconds( Int( descentTime * 999 ) ) ) {
            self.downPiece()
        }
    }
    
    func newPiece() {
        let x = Int( arc4random_uniform( UInt32( cGridWidth ) ) )
        
        let piece = Piece( location: Location( x: x, y: cGridHeight ), values: [randomValue(), randomValue(), randomValue()] )
        currentPiece = piece
        NotificationCenter.default.post( name: cNotificationPieceNew, object: self, userInfo: [cNotificationKeyPiece: piece] )
        
        // Set off timer for moving piece down
        downTimer()
    }
    
    func downPiece() {
        if .pause == gameState { return }
        
        guard let piece = currentPiece else { return }
        let location = piece.location
        if columnHeight( x: location.x )  == location.y {
            // Can't go down any further
            gameState = .endMove
            gameProceed()
        }
        else {
            // Go down another and set off timer again
            let updatedPiece = Piece( location: Location( x: location.x, y: location.y - 1 ), values: piece.values )
            currentPiece = updatedPiece
            NotificationCenter.default.post( name: cNotificationPieceDown, object: self, userInfo: [cNotificationKeyPiece: updatedPiece, cNotificationKeyTime: descentTime] )
            downTimer()
        }
    }
    
    func rotatePiece() {
        guard let piece = currentPiece else { return }
        // Bottom value to top
        let updatedPiece = Piece( location: piece.location, values: [piece.values[1], piece.values[2], piece.values[0]] )
        currentPiece = updatedPiece
        NotificationCenter.default.post( name: cNotificationPieceRotate, object: self, userInfo: [cNotificationKeyPiece: updatedPiece] )
    }
    
    func dropPiece() {
        guard let piece = currentPiece else { return }
        let location = piece.location
        let y = columnHeight( x: location.x )
        let updatedPiece = Piece( location: Location( x: location.x, y: y ), values: piece.values )
        currentPiece = updatedPiece
        NotificationCenter.default.post( name: cNotificationPieceDrop, object: self, userInfo: [cNotificationKeyPiece: updatedPiece, cNotificationKeyTime: descentTime] )
    }
    
    func leftPiece() {
        guard let piece = currentPiece else { return }
        let location = piece.location
        // Don't go off the side
        guard 0 != location.x else { return }
        // Don't go through built up column
        guard columnHeight( x: location.x - 1 ) <= location.y else { return }
        let updatedPiece = Piece( location: Location( x: location.x - 1, y: location.y ), values: piece.values )
        currentPiece = updatedPiece
        NotificationCenter.default.post( name: cNotificationPieceLeft, object: self, userInfo: [cNotificationKeyPiece: updatedPiece] )
    }
    
    func rightPiece() {
        guard let piece = currentPiece else { return }
        let location = piece.location
        // Don't go off the side
        guard cGridWidth != location.x + 1 else { return }
        // Don't go through built up column
        guard columnHeight( x: location.x + 1 ) <= location.y else { return }
        let updatedPiece = Piece( location: Location( x: location.x + 1, y: location.y ), values: piece.values )
        currentPiece = updatedPiece
        NotificationCenter.default.post( name: cNotificationPieceRight, object: self, userInfo: [cNotificationKeyPiece: updatedPiece] )
    }
}

