/*
 * Copyright (c) 2014-2016 Razeware LLC
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

import UIKit
import RxSwift
import RxCocoa
import CoreLocation

class ViewController: UIViewController {

  @IBOutlet weak var searchCityName: UITextField!
  @IBOutlet weak var tempLabel: UILabel!
  @IBOutlet weak var humidityLabel: UILabel!
  @IBOutlet weak var iconLabel: UILabel!
  @IBOutlet weak var cityNameLabel: UILabel!
    @IBOutlet weak var tempSwitch: UISwitch!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var geoLocationButton: UIButton!
    
    let bag = DisposeBag()
    let locationManager = CLLocationManager()
    
    
  override func viewDidLoad() {
    super.viewDidLoad()
    // Do any additional setup after loading the view, typically from a nib.

    style()

//    ApiController.shared.currentWeather(city: "RxCity")
//        .observeOn(MainScheduler.instance)
//        .subscribe(onNext: { data in
//            self.tempLabel.text = "\(data.temperature)° C"
//            self.iconLabel.text = data.icon
//            self.humidityLabel.text = "\(data.humidity)%"
//            self.cityNameLabel.text = data.cityName
//        })
//        .disposed(by: bag)
    
    //  Observable<String?> from UITextField after press Search
    let searchInput = searchCityName.rx
        .controlEvent(.editingDidEndOnExit)
        .asObservable()
        .map { self.searchCityName.text }
        .filter { ($0 ?? "").count > 0 }
    
    //  Observable<Weather> from API server with the search text above
    let textSearch = searchInput
        .flatMap { text in
            return ApiController.shared.currentWeather(city: text ?? "Error")
                .catchErrorJustReturn(ApiController.Weather.dummy)
        }
    
    // Observable<Void> from button tap, which starts asking locations
    let geoInput = geoLocationButton.rx.tap
        .asObservable()
        .do(onNext: {
            self.locationManager.requestWhenInUseAuthorization()
            self.locationManager.startUpdatingLocation()
        })
    
    // Observable<CLLocation> from didUpdateLocations
    let currentLocation = locationManager.rx.didUpdateLocations
        .map { locations in
            return locations[0]
        }
        .filter { location in
            return location.horizontalAccuracy < kCLLocationAccuracyHundredMeters
    }
    
    // Observable<CLLocation> from above, taking 1 result only
    let geoLocation = geoInput.flatMap {
        return currentLocation.take(1)
    }
    
    // Observable<Weather> from API server, input coordinates from above
    let geoSearch = geoLocation.flatMap { location in
        return ApiController.shared.currentWeather(lat: location.coordinate.latitude,
                                                   lon: location.coordinate.longitude)
            .catchErrorJustReturn(ApiController.Weather.dummy)
    }
    
    // merge two observables, one from UITextField, one from UIButton
    let search = Observable.from([geoSearch, textSearch])
        .merge()
        .asDriver(onErrorJustReturn: ApiController.Weather.dummy)
    
    let running = Observable.from([searchInput.map { _ in true },
                                   geoInput.map { _ in true },
                                   search.map { _ in false }.asObservable()])
        .merge()
        .startWith(true)
        .asDriver(onErrorJustReturn: false)
    
    running
        .skip(1)
        .drive(activityIndicator.rx.isAnimating)
        .disposed(by: bag)
    
    running
        .drive(tempLabel.rx.isHidden)
        .disposed(by: bag)

    running
        .drive(iconLabel.rx.isHidden)
        .disposed(by: bag)

    running
        .drive(humidityLabel.rx.isHidden)
        .disposed(by: bag)

    running
        .drive(cityNameLabel.rx.isHidden)
        .disposed(by: bag)

    running
        .drive(tempSwitch.rx.isHidden)
        .disposed(by: bag)
    
    search.map { "\($0.temperature)° C" }
        .drive(tempLabel.rx.text)
        .disposed(by: bag)
    
    search.map { $0.icon }
        .drive(iconLabel.rx.text)
        .disposed(by:bag)
    
    search.map { "\($0.humidity)%" }
        .drive(humidityLabel.rx.text)
        .disposed(by:bag)
    
    search.map { $0.cityName }
        .drive(cityNameLabel.rx.text)
        .disposed(by:bag)
    
    
    locationManager.rx.didUpdateLocations
        .subscribe(onNext: { locations in
            print(locations)
        })
        .disposed(by:bag)
    
    Driver.combineLatest(search, tempSwitch.rx.isOn.asDriver()) { data, temp -> String in
            if temp {
                return "\(data.temperature)° C"
            } else {
                return "\(Double(data.temperature) * 1.8 + Double(32))° F"
            }
        }
        .drive(tempLabel.rx.text)
        .disposed(by:bag)
    
 
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()

    Appearance.applyBottomLine(to: searchCityName)
  }

  override var preferredStatusBarStyle: UIStatusBarStyle {
    return .lightContent
  }

  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }

  // MARK: - Style

  private func style() {
    view.backgroundColor = UIColor.aztec
    searchCityName.textColor = UIColor.ufoGreen
    tempLabel.textColor = UIColor.cream
    humidityLabel.textColor = UIColor.cream
    iconLabel.textColor = UIColor.cream
    cityNameLabel.textColor = UIColor.cream
  }
}

