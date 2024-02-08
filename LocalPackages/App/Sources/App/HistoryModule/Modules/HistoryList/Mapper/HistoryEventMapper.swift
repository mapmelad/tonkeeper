import UIKit
import TKUIKit
import KeeperCore

struct HistoryEventMapper {
  
  let accountEventActionContentProvider: AccountEventActionContentProvider
  
  init(accountEventActionContentProvider: AccountEventActionContentProvider) {
    self.accountEventActionContentProvider = accountEventActionContentProvider
  }
  
  func mapEvent(_ event: HistoryListEvent) -> HistoryEventCell.Model {
    let actionModels = event.actions.map { action in
      mapAction(action)
    }
    return HistoryEventCell.Model(
      identifier: event.eventId,
      cellContentModel: HistoryEventCellContentView.Model(
        actionModels: actionModels
      )
    )
  }
  
  func mapAction(_ action: HistoryListEvent.Action) -> HistoryEventActionView.Model {
    let value = action.amount?.withTextStyle(
      .label1,
      color: action.eventType.amountColor,
      alignment: .right,
      lineBreakMode: .byTruncatingTail
    )
    let subvalue = action.subamount?.withTextStyle(
      .label1,
      color: action.eventType.subamountColor,
      alignment: .right,
      lineBreakMode: .byTruncatingTail
    )
    
    let listItemModel = HistoryEventActionListItemView.Model(
      image: action.eventType.icon,
      isInProgress: false,
      title: accountEventActionContentProvider.title(actionType: action.eventType),
      subtitle: action.leftTopDescription,
      value: value,
      subvalue: subvalue,
      date: action.rightTopDescription
    )
    
    return HistoryEventActionView.Model(
      listItemModel: listItemModel
    )
  }
}

extension HistoryListEvent.Action.ActionType {
  var icon: UIImage? {
    switch self {
    case .sent:
      return .App.Icons.Size28.trayArrowUp
    case .receieved:
      return .App.Icons.Size28.trayArrowDown
    case .mint:
      return .App.Icons.Size28.trayArrowDown
    case .burn:
      return .App.Icons.Size28.trayArrowUp
    case .depositStake:
      return .App.Icons.Size28.trayArrowUp
    case .withdrawStake:
      return .App.Icons.Size28.trayArrowUp
    case .withdrawStakeRequest:
      return .App.Icons.Size28.trayArrowDown
    case .jettonSwap:
      return .App.Icons.Size28.swapHorizontalAlternative
    case .spam:
      return .App.Icons.Size28.trayArrowDown
    case .bounced:
      return .App.Icons.Size28.return
    case .subscribed:
      return .App.Icons.Size28.bell
    case .unsubscribed:
      return .App.Icons.Size28.xmark
    case .walletInitialized:
      return .App.Icons.Size28.donemark
    case .contractExec:
      return .App.Icons.Size28.gear
    case .nftCollectionCreation:
      return .App.Icons.Size28.gear
    case .nftCreation:
      return .App.Icons.Size28.gear
    case .removalFromSale:
      return .App.Icons.Size28.xmark
    case .nftPurchase:
      return .App.Icons.Size28.shoppingBag
    case .bid:
      return .App.Icons.Size28.trayArrowUp
    case .putUpForAuction:
      return .App.Icons.Size28.trayArrowUp
    case .endOfAuction:
      return .App.Icons.Size28.xmark
    case .putUpForSale:
      return .App.Icons.Size28.trayArrowUp
    case .domainRenew:
      return .App.Icons.Size28.return
    case .unknown:
      return .App.Icons.Size28.gear
    }
  }
  
  var amountColor: UIColor {
    switch self {
    case .sent,
        .depositStake,
        .subscribed,
        .unsubscribed,
        .walletInitialized,
        .nftCollectionCreation,
        .nftCreation,
        .removalFromSale,
        .nftPurchase,
        .bid,
        .putUpForAuction,
        .endOfAuction,
        .contractExec,
        .putUpForSale,
        .burn,
        .domainRenew,
        .unknown:
      return .Text.primary
    case .receieved, .bounced, .mint, .withdrawStake, .jettonSwap:
      return .Accent.green
    case .spam, .withdrawStakeRequest:
      return .Text.tertiary
    }
  }
  
  var subamountColor: UIColor {
    switch self {
    case .jettonSwap:
      return .Text.primary
    default:
      return .Text.primary
    }
  }
}
