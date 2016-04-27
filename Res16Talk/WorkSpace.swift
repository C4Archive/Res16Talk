//
//  WorkSpace.swift
//  Res16Talk
//
//  Created by travis on 2016-04-16.
//  Copyright © 2016 C4. All rights reserved.
//

import UIKit

class WorkSpace: CanvasController {
    let origin = Point(64,154)
    let shortQuoteFont = Font(name: "Inconsolata", size: 100)!
    let longQuoteFont = Font(name: "Inconsolata", size: 70)!
    let shortQuote = "life\ndeath\nlamentation\nresurrection"
    let longQuote = "in that conversation\ni told him that there\nneeded to be an equivalent\ncreative coding framework,\nlike processing and of\nbut built in objective-c…"

    var slides = [Slide]()
    var currentIndex = 0
    var gradient: Gradient!
    var text: TextShape!
    let colors = [C4Grey, C4Blue, C4Pink, C4Pink, darkGray]

    override func setup() {
        loadData()

        gradient = Gradient(frame: canvas.bounds)
        gradient.interactionEnabled = false
        canvas.add(gradient)

        let currentSlide = slides[currentIndex]
        text = TextShape(text: currentSlide.text, font: shortQuoteFont)!
        text.interactionEnabled = false
        text.fillColor = clear
        text.lineWidth = 5.0
        text.origin = origin
        text.strokeColor = white.colorWithAlpha(0.9)
        canvas.add(text)

        let nextSlide = canvas.addSwipeGestureRecognizer { (locations, center, state, direction) in
            self.next()
        }

        let previousSlide = canvas.addSwipeGestureRecognizer { (locations, center, state, direction) in
            self.previous()
        }
        previousSlide.direction = .Left

        let pan = canvas.addPanGestureRecognizer { (locations, center, translation, velocity, state) in
            let slideIndex = Int(center.x/self.canvas.width * Double(self.slides.count))
            self.goTo(slideIndex)
        }
        pan.requireGestureRecognizerToFail(previousSlide)
        pan.requireGestureRecognizerToFail(nextSlide)
    }

    func updateGradient() {
        var newColors = [colors[random(below: colors.count)], colors[random(below: colors.count)]]
        if newColors[0] === C4Grey && newColors[1] === C4Grey {
            let newIndex = random(below: 2)
            newColors[newIndex] = colors[random(min: 1, max: colors.count-1)]
        }
        gradient.colors = newColors
    }

    func goTo(slideIndex: Int) {
        guard slideIndex >= 0 && slideIndex < slides.count else {
            print("passed index out of range")
            return
        }
        if currentIndex != slideIndex {
            currentIndex = slideIndex
            renderNewSlide(slides[currentIndex])
            print(#function, slideIndex)
        }
    }

    func next(shouldAnimate: Bool = true) {
        if currentIndex + 1 >= slides.count {
            print("\(#function) index out of range")
            return
        }

        hideCurrentSlide()
        currentIndex = currentIndex + 1
        print(#function, currentIndex)
    }

    func previous(shouldAnimate: Bool = true) {
        if currentIndex - 1 < 0 {
            print("\(#function) index out of range")
            return
        }
        currentIndex = currentIndex - 1
        hideCurrentSlide()
        print(#function, currentIndex)
    }

    func hideCurrentSlide() {
        switch slides[currentIndex].type {
        case .LongText, .ShortText:
            randomlyHideCurrentText()
        default:
            break
        }
    }

    func renderNewSlide(slide: Slide) {
        switch slide.type {
        case .LongText:
            renderLongText(slide)
        case .ShortText:
            renderShortText(slide)
        case .Movie:
            renderMovie(slide)
        default:
            break
        }
        self.updateGradient()
    }

    func randomlyHideCurrentText(shouldAnimate: Bool = true) {
        let duration = shouldAnimate ? 0.5 : 0.0
        let a = ViewAnimation(duration: duration) {
            let ends = self.randomEndPoints()
            self.text.strokeStart = ends
            self.text.strokeEnd = ends
        }
        a.addCompletionObserver {
            self.renderNewSlide(self.slides[self.currentIndex])
        }

        a.animate()
    }

    func randomlyRevealNewText(shouldAnimate: Bool = true) {
        let duration = shouldAnimate ? 0.5 : 0.0
        ViewAnimation(duration: duration) {
            self.text.strokeStart = 0.0
            self.text.strokeEnd = 1.0
        }.animate()
    }

    func randomEndPoints() -> Double {
        switch random(below: 3) {
        case 0:
            return 0.0
        case 1:
            return 0.5
        default:
            return 1.0
        }
    }

    func renderLongText(slide: Slide) {
        let str = TextShape(text: slide.text, font: longQuoteFont)
        text.path = str?.path
        text.lineWidth = 3.0
        self.randomlyRevealNewText()
    }

    func renderShortText(slide: Slide) {
        let str = TextShape(text: slide.text, font: shortQuoteFont)
        text.path = str?.path
        text.lineWidth = 5.0
        self.randomlyRevealNewText()
    }

    func renderMovie(slide: Slide) {
        let m = Movie(slide.filename)
        m?.loops = true
        m?.muted = true
        m?.constrainsProportions = true
        m?.width = canvas.width
        m?.center = canvas.center
        canvas.add(m)
        m?.play()
    }

    func loadData() {
        let path = NSBundle.mainBundle().pathForResource("slides", ofType: "plist")!
        guard let slideData = NSArray(contentsOfFile: path) as? [[String : AnyObject]] else {
            print("Could not extract array of events from file")
            return
        }

        for entry in slideData {
            let type = entry["type"] as! String
            let text = entry["text"] as! String
            let filename = entry["filename"] as! String
            let function = entry["function"] as! String

            let slide = Slide(type: SlideType(rawValue: type)!, text: text, filename: filename, function: function)
            slides.append(slide)
        }
    }
}

enum SlideType: String {
    case LongText = "LongText"
    case ShortText = "ShortText"
    case Image = "Image"
    case Movie = "Movie"
    case Demo = "Demo"
    case None = "None"
}

struct Slide {
    var type: SlideType = .None
    var text = ""
    var filename = ""
    var function = ""

    init(type: SlideType, text: String = "", filename: String = "", function: String = "") {
        self.type = type
        self.text = text
        self.filename = filename
        self.function = function
    }
}

