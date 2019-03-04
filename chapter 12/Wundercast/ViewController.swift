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
import MapKit

class ViewController: UIViewController {

  @IBOutlet weak var searchCityName: UITextField!
  @IBOutlet weak var tempLabel: UILabel!
  @IBOutlet weak var humidityLabel: UILabel!
  @IBOutlet weak var iconLabel: UILabel!
  @IBOutlet weak var cityNameLabel: UILabel!
    @IBOutlet weak var tempSwitch: UISwitch!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var geoLocationButton: UIButton!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var mapButton: UIButton!
    @IBOutlet weak var keyButton: UIButton!
    
    let bag = DisposeBag()
    let locationManager = CLLocationManager()
    var cache = [String: Weather]()
    var keyTextField: UITextField?
    
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
    
    keyButton.rx.tap.subscribe(onNext: {
        self.requestKey()
    }).disposed(by:bag)
    
    // error handling
    let maxAttempts = 4
    
    let retryHandler: (Observable<Error>) -> Observable<Int> = { e in
        return e.enumerated().flatMap { attempt, error -> Observable<Int> in
            if attempt >= maxAttempts - 1 {
                return Observable.error(error)
            } else if let casted = error as? ApiError, casted == .invalidKey {
                return ApiController.shared.apiKey
                    .filter { $0 != "" }
                    .map { _ in return 1 }
            }
            print("== retrying after \(attempt + 1) seconds ==")
            return Observable<Int>.timer(Double(attempt + 1), scheduler: MainScheduler.instance).take(1)
        }
    }
    
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
                .do(onNext: { data in
                    if let text = text {
                        self.cache[text] = data
                    }
                }, onError: { [weak self] e in
                    guard let strongSelf = self else { return }
                    DispatchQueue.main.async {
                        strongSelf.showError(error: e)
                    }
                })
                .retryWhen(retryHandler)
                .catchError { error in
                    if let text = text, let cacheData = self.cache[text] {
                        return Observable.just(cacheData)
                    } else {
                        return Observable.just(Weather.empty)
                    }
                }
        }
        .share(replay: 1, scope: .forever) // must include this otherwise API will sent twice (being subscribe twice)
    
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
    let geoSearch = geoLocation
        .flatMap { location in
            return ApiController.shared.currentWeather(lat: location.coordinate.latitude,
                                                       lon: location.coordinate.longitude)
                .catchErrorJustReturn(Weather.dummy)
        }
    
    // map
    let mapInput = mapView.rx.regionDidChangeAnimated
        .skip(1)
        .map { _ in self.mapView.centerCoordinate }
    
    let mapSearch = mapInput
        .flatMap { coordinate in
            return ApiController.shared.currentWeather(lat: coordinate.latitude,
                                                       lon: coordinate.longitude)
                .catchErrorJustReturn(Weather.dummy)
        }
    
    mapButton.rx.tap
        .subscribe(onNext: {
            self.mapView.isHidden = !self.mapView.isHidden
        })
        .disposed(by: bag)
    
    // merge two observables, one from UITextField, one from UIButton
    let search = Observable.from([geoSearch, textSearch, mapSearch])
        .merge()
        .asDriver(onErrorJustReturn: Weather.dummy)
    
    let running = Observable.from([searchInput.map { _ in true },
                                   geoInput.map { _ in true },
                                   mapInput.map { _ in true },
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
    
    mapView.rx.setDelegate(self)
        .disposed(by: bag)
    
    search.map { [$0.overlay()] }
        .drive(mapView.rx.overlays)
        .disposed(by: bag)
    
    Observable.from([geoSearch, textSearch])
        .merge()
        .map { $0.coordinate }
        .bind(to: mapView.rx.location)
        .disposed(by: bag)
  }

    func showError(error e: Error) {
        if let e = e as? ApiError {
            switch e {
            case .cityNotFound:
                InfoView.showIn(viewController: self, message: "City name is invalid")
            case .serverFailure:
                InfoView.showIn(viewController: self, message: "Server error")
            case .invalidKey:
                InfoView.showIn(viewController: self, message: "Key is invalid")
            }
        } else {
            InfoView.showIn(viewController: self, message: "An error has occured")
        }
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
    
    func requestKey() {
        func configurationTextField(textField: UITextField!) {
            self.keyTextField = textField
        }
        
        let alert = UIAlertController(title: "Api Key",
                                      message: "Add the api key:",
                                      preferredStyle: .alert)
        
        alert.addTextField(configurationHandler: configurationTextField)
        
        alert.addAction(UIAlertAction(title: "Ok", style: .default) { _ in
            ApiController.shared.apiKey.onNext(self.keyTextField?.text ?? "")
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .destructive))
        
        self.present(alert, animated: true)
    }
}

extension ViewController: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if let overlay = overlay as? Weather.Overlay {
            let overlayView = Weather.OverlayView(overlay: overlay, overlayIcon: overlay.icon)
            return overlayView
        }
        return MKOverlayRenderer()
    }
}
