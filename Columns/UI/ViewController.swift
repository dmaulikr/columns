//
//  ViewController.swift
//  Columns
//
//  Created by Greg Sutton on 27/03/2016.
//  Copyright © 2016 Darksheep. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    @IBOutlet weak var gridView: UIView!
    @IBOutlet weak var playPauseButton: UIButton!
    @IBOutlet weak var scoreLabel: UILabel! {
        didSet {
            scoreLabel.font = scoreLabel.font.monospacedDigitFont
        }
    }

    let game = AppDelegate.game()
    
    override var prefersStatusBarHidden: Bool {
        return true
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        gridView.setNeedsDisplay()
        
        NotificationCenter.default.addObserver( self, selector: #selector( ViewController.gamePlaying(_:) ), name: cNotificationGamePlaying, object: nil )
        NotificationCenter.default.addObserver( self, selector: #selector( ViewController.gamePaused(_:) ), name: cNotificationGamePaused, object: nil )
        NotificationCenter.default.addObserver( self, selector: #selector( ViewController.gamePlaying(_:) ), name: cNotificationGameResumed, object: nil )
        NotificationCenter.default.addObserver( self, selector: #selector( ViewController.gameEnd(_:) ), name: cNotificationGameEnd, object: nil )
        
        NotificationCenter.default.addObserver( self, selector: #selector( ViewController.updateScore(_:) ), name: cNotificationUpdateScore, object: nil )

    }

    @IBAction func playPausedPressed(_ sender: UIButton) {
        print( "playPausedPressed" )
        game.playPause()
    }

    @IBAction func restartPressed(_ sender: UIButton) {
        print( "restartPressed" )
        game.restart()
    }

    @IBAction func rotatePressed(_ sender: UIButton) {
        print( "rotatePressed" )
        game.rotate()
    }
    
    @IBAction func dropPressed(_ sender: UIButton) {
        print( "dropPressed" )
        game.drop()
    }
    
    @IBAction func leftPressed(_ sender: UIButton) {
        print( "leftPressed" )
        game.left()
    }
    
    @IBAction func rightPressed(_ sender: UIButton) {
        print( "rightPressed" )
        game.right()
    }
}

// MARK: Notifications
extension ViewController {
    @objc func gamePlaying( _ notification: Notification ) {
        playPauseButton.setTitle( "Pause", for: .normal )
    }

    @objc func gamePaused( _ notification: Notification ) {
        playPauseButton.setTitle( "Resume", for: .normal )
    }
    
    @objc func updateScore( _ notification: Notification ) {
        guard let score = notification.userInfo?[cNotificationKeyScore] as? Int else { return }
        scoreLabel.text = String( score )
    }
    
    @objc func gameEnd( _ notification: Notification ) {
        playPauseButton.setTitle( "Play", for: .normal )
    }
}
