//: Please build the scheme 'RxSwiftPlayground' first

import RxSwift
import PlaygroundSupport
PlaygroundPage.current.needsIndefiniteExecution = true




/*:
 Copyright (c) 2014-2017 Razeware LLC
 
 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in
 all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 THE SOFTWARE.
 */

example(of: "startWith") {
    let numbers = Observable.of(2, 3, 4)
    numbers
        .startWith(1)
        .subscribe(onNext: { print($0) })
}

example(of: "Observable.concat") {
    let first = Observable.of(1, 2, 3)
    let second = Observable.of(4, 5, 6)
    
    Observable.concat([first, second])
        .subscribe(onNext: { print($0) })
}

example(of: "concat") {
    let germanCities = Observable.of("Berlin", "Münich", "Frankfurt")
    let spanishCities = Observable.of("Madrid", "Barcelona", "Valencia")
    
    germanCities.concat(spanishCities)
        .subscribe(onNext: { print($0) })
}

example(of: "concatMap") {
    let sequences = [
         "Germany": Observable.of("Berlin", "Münich", "Frankfurt"),
         "Spain": Observable.of("Madrid", "Barcelona", "Valencia")
    ]
    
    Observable.of("Germany", "Spain")
        .concatMap { country in sequences[country] ?? .empty() }
        .subscribe(onNext: { print($0) })
}

example(of: "merge") {
    let left = PublishSubject<String>()
    let right = PublishSubject<String>()
    
    let source = Observable.of(left.asObservable(), right.asObservable())
    source.merge()
        .subscribe(onNext: { print($0) })
    
    var leftValues = ["Berlin", "Munich", "Frankfurt"]
    var rightValues = ["Madrid", "Barcelona", "Valencia"]
    
    repeat {
        if Int.random(in: 0..<2) == 0 {
            if !leftValues.isEmpty {
                left.onNext("Left: " + leftValues.removeFirst())
            }
        } else if !rightValues.isEmpty {
            right.onNext("Right " + rightValues.removeFirst())
        }
    } while !leftValues.isEmpty || !rightValues.isEmpty
}

example(of: "combineLatest") {
    let left = PublishSubject<String>()
    let right = PublishSubject<String>()
    
    Observable.combineLatest(left, right) { lastLeft, lastRight in
        "\(lastLeft) \(lastRight)"
    }
        .subscribe(onNext: { print($0) })
    
    print("> Sending a value to Left")
    left.onNext("Hello,")
    print("> Sending a value to Right")
    right.onNext("world")
    print("> Sending another value to Right")
    right.onNext("RxSwift")
    print("> Sending another value to Left")
    left.onNext("Have a good day,")
}

example(of: "combine user choice and value") {
    let choice: Observable<DateFormatter.Style> = Observable.of(.short, .long)
    let dates = Observable.of(Date())
    
    Observable.combineLatest(choice, dates) { format, when -> String in
        let formatter = DateFormatter()
        formatter.dateStyle = format
        return formatter.string(from: when)
    }
        .subscribe(onNext: { print($0) })
}

example(of: "zip") {
    enum Weather {
        case cloudy
        case sunny
    }
    
    let left: Observable<Weather> = Observable.of(.sunny, .cloudy, .cloudy, .sunny)
    let right = Observable.of("Lisbon", "Copenhagen", "London", "Madrid", "Vienna")
    
    Observable.zip(left, right) { weather, city in
        return "It's \(weather) in \(city)"
    }
        .subscribe(onNext: { print($0) })
}

example(of: "withLatestFrom") {
    let button = PublishSubject<Void>()
    let textField = PublishSubject<String>()
    
    button.withLatestFrom(textField)
        .subscribe(onNext: { print($0) })
    
    textField.onNext("Par")
    textField.onNext("Pari")
    textField.onNext("Paris")
    button.onNext(())
    button.onNext(())
}

example(of: "sample") {
    let button = PublishSubject<Void>()
    let textField = PublishSubject<String>()
    
    textField.sample(button)
        .subscribe(onNext: { print($0) })
    
    textField.onNext("Par")
    textField.onNext("Pari")
    textField.onNext("Paris")
    button.onNext(())
    button.onNext(())
}

example(of: "amb") {
    let left = PublishSubject<String>()
    let right = PublishSubject<String>()
    
    left.amb(right)
        .subscribe(onNext: { print($0) })
    
    left.onNext("Lisbon")
    right.onNext("Copenhagen")
    left.onNext("London")
    left.onNext("Madrid")
    right.onNext("Vienna")
}

example(of: "switchLatest") {
    let one = PublishSubject<String>()
    let two = PublishSubject<String>()
    let three = PublishSubject<String>()
    
    let source = PublishSubject<Observable<String>>()
    
    source.switchLatest()
        .subscribe(onNext: { print($0) })
    
    source.onNext(one)
    one.onNext("Some text from sequence one")
    two.onNext("Some text from sequence two") // nope
    source.onNext(two)
    two.onNext("More text from sequence two")
    one.onNext("and also from sequence one") // nope
    source.onNext(three)
    two.onNext("Why don't you see me?") // nope
    one.onNext("I'm alone, help me") // nope
    three.onNext("Hey it's three. I win.")
    source.onNext(one)
    one.onNext("Nope. It's me, one!")
}

example(of: "reduce") {
    let source = Observable.of(1, 3, 5, 7, 9)
    source.reduce(0, accumulator: { summary, newValue in
        return summary + newValue
    })
        .subscribe(onNext: { print($0) })
}

example(of: "scan") {
    let source = Observable.of(1, 3, 5, 7, 9)
    source.scan(0, accumulator: { (summary, newValue) -> Int in
        return summary + newValue
    })
      .subscribe(onNext: { print($0) })
}
