import Foundation
import TKUIKit

protocol HistoryEmptyModuleOutput: AnyObject {
  
}

protocol HistoryEmptyViewModel: AnyObject {
  var didUpdateModel: ((HistoryEmptyView.Model) -> Void)? { get set }
  
  func viewDidLoad()
}

final class HistoryEmptyViewModelImplementation: HistoryEmptyViewModel, HistoryEmptyModuleOutput {
  
  // MARK: - HistoryEmptyModuleOutput
  
  // MARK: - HistoryEmptyViewModel
  
  var didUpdateModel: ((HistoryEmptyView.Model) -> Void)?
  
  func viewDidLoad() {
    didUpdateModel?(createModel())
  }
}

private extension HistoryEmptyViewModelImplementation {
  func createModel() -> HistoryEmptyView.Model {
    let title = "Your history\nwill be shown here".withTextStyle(
      .h2,
      color: .Text.primary,
      alignment: .center,
      lineBreakMode: .byWordWrapping
    )
    let description = "Make your first transaction!".withTextStyle(
      .body1,
      color: .Text.secondary,
      alignment: .center,
      lineBreakMode: .byWordWrapping
    )
    
    let buyButtonModel = TKUIActionButton.Model(title: "Buy Toncoin")
    let buyButtonAction = {
      
    }
    
    let receiveButtonModel = TKUIActionButton.Model(title: "Receive")
    let receiveButtonAction = {
      
    }
    
    return HistoryEmptyView.Model(
      title: title,
      description: description,
      buyButtonModel: buyButtonModel,
      buyButtonAction: buyButtonAction,
      receiveButtonModel: receiveButtonModel,
      receiveButtonAction: receiveButtonAction
    )
  }
}
