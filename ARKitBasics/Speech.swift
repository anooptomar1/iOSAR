//
//  Speech.swift
//  ARKitBasics
//
//  Created by Abhinav Prakash on 29/11/17.
//  Copyright © 2017 Apple. All rights reserved.
//

import Foundation
import AVFoundation

class Speech: AVSpeechSynthesizer {
    
    private var voice = AVSpeechSynthesisVoice(identifier: "com.apple.ttsbundle.siri_female_en-US_compact")
    
    let welcomeText = "Welcome, let's start!"
    private let accolades = ["Great!", "Perfect!", "Good going!", "Nice job!"]
    private let negation = ["Oops! that's not it!", "Nope, not this!", "Nope, try again with other object."]
    
    var randomAccolade: String {
        get {
            return accolades[randRange(lower: 0, upper: accolades.count-1)]
        }
    }
    
    var randomNegation: String {
        get {
            return negation[randRange(lower: 0, upper: negation.count-1)]
        }
    }
    
    func say(text: String) {
        let speechUtterance = AVSpeechUtterance(string: text)
        speechUtterance.voice = voice
        self.speak(speechUtterance)
    }
    
    func sayFind(color: String, shape: String) {
        let speechUtterance = AVSpeechUtterance(string: "Find a \(color) \(shape)")
        speechUtterance.voice = voice
        self.speak(speechUtterance)
    }
    
    private func randRange (lower: Int, upper: Int) -> Int {
        return Int(UInt32(lower) + arc4random_uniform(UInt32(upper) - UInt32(lower) + 1))
    }
}
