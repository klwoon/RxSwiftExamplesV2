//: Please build the scheme 'RxSwiftPlayground' first
import RxSwift



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
example(of: "ignoreElements") {
    let strikes = PublishSubject<String>()
    let bag = DisposeBag()
    
    strikes
        .ignoreElements()
        .subscribe { _ in
            print("you are out!")
        }
        .disposed(by: bag)
    
    strikes.onNext("X")
    strikes.onNext("X")
    strikes.onNext("X")
    strikes.onCompleted()
}

example(of: "elementAt") {
    let strikes = PublishSubject<String>()
    let bag = DisposeBag()
    
    strikes
        .elementAt(2)
        .subscribe(onNext:{ _ in
            print("you are out!")
        })
        .disposed(by: bag)
    
    strikes.onNext("X")
    strikes.onNext("X")
    strikes.onNext("X")
}

example(of: "filter") {
    let bag = DisposeBag()
    
    Observable.of(1, 2, 3, 4, 5, 6)
        .filter { integer in
            integer % 2 == 0
        }
        .subscribe(onNext: {
            print($0)
        })
        .disposed(by: bag)
}

example(of: "skip") {
    let bag = DisposeBag()
    
    Observable.of("A", "B", "C", "D", "E", "F")
        .skip(3)
        .subscribe(onNext: {
            print($0)
        })
        .disposed(by: bag)
}

example(of: "skipWhile") {
    let bag = DisposeBag()
    
    Observable.of(2, 2, 3, 4, 4)
        .skipWhile { integer in
            integer % 2 == 0
        }
        .subscribe(onNext: {
            print($0)
        })
        .disposed(by: bag)
}

example(of: "skipUntil") {
    let bag = DisposeBag()
    
    let subject = PublishSubject<String>()
    let trigger = PublishSubject<String>()
    
    subject
        .skipUntil(trigger)
        .subscribe(onNext: {
            print($0)
        })
        .disposed(by: bag)
    
    subject.onNext("A")
    subject.onNext("B")
    trigger.onNext("X")
    subject.onNext("C")
}

example(of: "take") {
    let bag = DisposeBag()
    
    Observable.of(1, 2, 3, 4, 5, 6)
        .take(3)
        .subscribe { print($0) }
        .disposed(by: bag)
}

example(of: "takeWhile") {
    let bag = DisposeBag()
    
    Observable.of(2, 2, 4, 4, 6, 6)
        .enumerated()
        .takeWhile { index, integer in
            integer % 2 == 0 && index < 3
        }
        .map { $0.element }
        .subscribe { print($0) }
        .disposed(by: bag)
}

example(of: "takeUntil") {
    let bag = DisposeBag()
    
    let subject = PublishSubject<String>()
    let trigger = PublishSubject<String>()
    
    subject
        .takeUntil(trigger)
        .subscribe { print($0) }
        .disposed(by: bag)
    
    subject.onNext("1")
    subject.onNext("2")
    trigger.onNext("X")
    subject.onNext("3")
}

example(of: "distinctUntilChanged") {
    let bag = DisposeBag()
    
    Observable.of("A", "A", "B", "B", "A")
        .distinctUntilChanged()
        .subscribe { print($0) }
        .disposed(by: bag)
}

example(of: "distinctUntilChanged(_:)") {
    let bag = DisposeBag()
    
    let formatter = NumberFormatter()
    formatter.numberStyle = .spellOut
    
    Observable<NSNumber>.of(10, 110, 20, 200, 210, 310)
        .distinctUntilChanged { a, b in
            guard let aWords = formatter.string(from: a)?.components(separatedBy: " "),
                let bWords = formatter.string(from: b)?.components(separatedBy: " ") else { return false }
            
            var containsMatch = false
            print("a=", aWords)
            print("b=", bWords)
            for aWord in aWords {
                for bWord in bWords {
                    if aWord == bWord {
                        containsMatch = true
                        break
                    }
                }
            }
            
            return containsMatch
        }
        .subscribe { print($0) }
        .disposed(by: bag)
}
