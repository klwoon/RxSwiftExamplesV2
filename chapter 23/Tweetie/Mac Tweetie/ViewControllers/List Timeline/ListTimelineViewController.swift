/*
 * Copyright (c) 2016-2017 Razeware LLC
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

import Foundation
import Cocoa
import RxSwift
import RxCocoa
import RealmSwift
import RxRealm
import Then
import RxRealmDataSources

class ListTimelineViewController: NSViewController {
  private let bag = DisposeBag()
  fileprivate var viewModel: ListTimelineViewModel!
  fileprivate var navigator: Navigator!

  @IBOutlet var tableView: NSTableView!

  static func createWith(navigator: Navigator, storyboard: NSStoryboard, viewModel: ListTimelineViewModel) -> ListTimelineViewController {
    return storyboard.instantiateViewController(ofType: ListTimelineViewController.self).then { vc in
      vc.navigator = navigator
      vc.viewModel = viewModel
    }
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    NSApp.windows.first?.title = "@\(viewModel.list.username)/\(viewModel.list.slug)"
    bindUI()
  }

  func bindUI() {
    //show tweets in table view
    let dataSource = RxTableViewRealmDataSource<Tweet>(cellIdentifier: "TweetCellView", cellType: TweetCellView.self) { (cell, row, tweet) in
        cell.update(with: tweet)
    }
    
    let binder = tableView.rx.realmChanges(dataSource)
    viewModel.tweets
        .bind(to: binder)
        .disposed(by: bag)
  }
}
