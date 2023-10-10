//
//  Sounds.swift
//  Budget Prototype
//
//  Created by Johnny Wu on 19/4/2022.
//

// These libraries are needed to play the soundPlayer class and to set up the AVAudioPlayer
import Foundation
import AVFoundation

// Custom class used to play sounds. Since classes share data, it is useful to store the data (or create functions) used in all parts of the app, which is what the sounds is used for
class SoundPlayer {
    
    // From https://www.youtube.com/watch?v=iBLZ1C4L5Mw, this allows me to play the sounds in any part of the app without needing to reinitialise the class everywhere
    static let instance = SoundPlayer()
    
    // This is what is actually used to play the sound, and is part of the AVFoundation library (audio video library)
    var player: AVAudioPlayer?
    
    // This function plays a sound depending on the sound name
    func playSound(soundName : String) {
        
        // Handle optionals and errors. Bundle.main.path essentially finds whatever filename you wish to find
        guard let path = Bundle.main.path(forResource: soundName, ofType: "mp3")
        else { return }
        
        // Create the url which is used internally to find different assets
        let url = URL(fileURLWithPath: path)

        do {
            // This actually tries plays the sound, AVAudoiplayer is used to play the sound
            player = try AVAudioPlayer(contentsOf: url)
            player?.play()
            
            // if nothing is found then an error is printed and nothing happend
        } catch let error {
            print(error.localizedDescription)
        }
    }
}
