//
//  StepperOperation.swift
//  Columns
//
//  Created by Greg Sutton on 28/03/2016.
//  Copyright © 2016 Darksheep. All rights reserved.
//

import Foundation

class StepperOperation: Operation {
    let game: Game
    let maxX = cGridWidth - 1
    let maxY = cGridHeight - 1
    let stepX: Int
    let stepY: Int
    var locations = [Location]()
    var lastValueY = -1             // Used for pre-calculation of column heights - makes things a bit easier if not optimal
    
    init( game: Game, stepX: Int, stepY: Int ) {
        self.game = game
        self.stepX = stepX
        self.stepY = stepY
    }
    
    func findStripLocations( _ startX: Int, startY: Int ) {
        var x = startX
        var y = startY
        var tempLocations = [Location]()
        var lastValue = Value.None
        var first = true
        lastValueY = -1
        while ( x >= 0 && x <= maxX ) && ( y >= 0 && y <= maxY ) {
            let value = game.grid[x][y]
            if .None == value || ( !first && value != lastValue ) {
                if tempLocations.count >= 3 {
                    locations += tempLocations
                }
                tempLocations.removeAll()
            }
                
            if .None != value {
                let location = Location( x: x, y: y )
                tempLocations.append( location )
                first = false
                lastValueY = y
            }
            else {
                first = true
            }
            
            lastValue = value
            x += stepX
            y += stepY
        }
        // Check if we had a run on the edge
        if tempLocations.count >= 3 {
            locations += tempLocations
        }
    }
}

class VerticalStepper: StepperOperation {
    convenience init( game: Game ) {
        self.init( game: game, stepX: 0, stepY: 1 )
    }
    
    override func main() {
        // We could optimise here by stopping when we get a .None value going up, but won't
        for x in 0 ..< cGridWidth {
            findStripLocations( x, startY: 0 )
        }
    }
}

class HorizontalStepper: StepperOperation {
    convenience init( game: Game ) {
        self.init( game: game, stepX: 1, stepY: 0 )
    }
    
    override func main() {
        for y in 0 ..< cGridHeight {
            findStripLocations( 0, startY: y )
        }
    }
}

class DiagonalRightStepper: StepperOperation {
    convenience init( game: Game ) {
        self.init( game: game, stepX: 1, stepY: 1 )
    }
    
    override func main() {
        for x in 0 ... (cGridWidth - 3 ) {
            findStripLocations( x, startY: 0 )
        }
        for y in 1 ... (cGridHeight - 3 ) {
            findStripLocations( 0, startY: y )
        }
    }
}

class DiagonalLeftStepper: StepperOperation {
    convenience init( game: Game ) {
        self.init( game: game, stepX: -1, stepY: 1 )
    }
    
    override func main() {
        for x in 2 ..< cGridWidth {
            findStripLocations( x, startY: 0 )
        }
        for y in 1 ... (cGridHeight - 3 ) {
            findStripLocations( cGridWidth - 1, startY: y )
        }
    }
}

