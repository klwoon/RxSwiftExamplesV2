//
//  UIViewController.swift
//  Combinestagram
//
//  Created by Woon on 01/03/2019.
//  Copyright © 2019 Underplot ltd. All rights reserved.
//

import UIKit
import RxSwift

extension UIViewController {
    
    func showAlert(title: String, message: String?) -> Completable {
        return Completable.create { [weak self] completable in
            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
            let close = UIAlertAction(title: "Close", style: .default) { _ in
                completable(.completed)
            }
            alert.addAction(close)
            self?.present(alert, animated: true)
            
            return Disposables.create {
                self?.dismiss(animated: true)
            }
        }
    }
}
