/*
 * Copyright (c) 2016 Razeware LLC
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

class CategoriesViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

  @IBOutlet var tableView: UITableView!

    let categories = BehaviorRelay<[EOCategory]>(value: [])
    let bag = DisposeBag()
    let activityIndicator = UIActivityIndicatorView(style: .gray)
    
  override func viewDidLoad() {
    super.viewDidLoad()

    
    activityIndicator.hidesWhenStopped = true
    activityIndicator.color = .blue
    activityIndicator.startAnimating()
    navigationItem.rightBarButtonItem = UIBarButtonItem(customView: activityIndicator)
    
    categories
        .subscribe(onNext: { [weak self] _ in
            DispatchQueue.main.async {
                self?.tableView.reloadData()
            }
        })
        .disposed(by: bag)
    
    startDownload()
  }

  func startDownload() {
    let eoCategories = EONET.categories
    let downloadedEvents = eoCategories
        .flatMap { categories in
            return Observable.from(categories.map { category in
                EONET.events(forLast: 360, category: category)
            })
        }
        .merge(maxConcurrent: 2)
    
    let updatedCategories = eoCategories
        .flatMap { categories in
            downloadedEvents.scan(categories) { updated, events in
                return updated.map { category in
                    let eventsForCategory = EONET.filteredEvents(events: events, forCategory: category)
                    if !eventsForCategory.isEmpty {
                        var cat = category
                        cat.events = cat.events + eventsForCategory
                        return cat
                    }
                    return category
                }
            }
        }
        .do(onCompleted: {
            DispatchQueue.main.async {
                self.activityIndicator.stopAnimating()
            }
        })
    
    eoCategories
        .concat(updatedCategories) // the reason to use concat(_:) is to bind to categories (which in turns emit to tableView for update), tableView is reloaded 3 times, one for /category, twice for /events&status=open /events&status=closed
        .bind(to: categories) // bind(to:) connects a source observable (EONet.categories) to an observer (categories BR)
        .disposed(by: bag)
    
//    updatedCategories
//        .bind(to: categories)
//        .disposed(by: bag)
  }
  
  // MARK: UITableViewDataSource
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return categories.value.count
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "categoryCell")!
    let category = categories.value[indexPath.row]
    cell.textLabel?.text = "\(category.name) (\(category.events.count))"
    cell.accessoryType = (category.events.count > 0) ? .disclosureIndicator : .none
    cell.detailTextLabel?.text = category.description
    return cell
  }
  
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let category = categories.value[indexPath.row]
        if !category.events.isEmpty {
            guard let controller = storyboard?.instantiateViewController(withIdentifier: "events") as? EventsViewController else {
                fatalError()
            }
            controller.title = category.name
            controller.events.accept(category.events)
            navigationController?.pushViewController(controller, animated: true)
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

