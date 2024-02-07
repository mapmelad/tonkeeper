import Foundation
import TKUIKit
import UIKit
import KeeperCore

protocol WalletsListModuleOutput: AnyObject {
  var didTapAddWalletButton: (() -> Void)? { get set }
  var didSelectWallet: (() -> Void)? { get set }
}

protocol WalletsListViewModel: AnyObject {
  var didUpdateHeaderItem: ((TKPullCardHeaderItem) -> Void)? { get set }
  var didUpdateItems: (([WalletsListWalletCell.Model]) -> Void)? { get set }
  var didUpdateSelectedItem: ((Int?, Bool) -> Void)? { get set }
  var didUpdateFooterModel: ((WalletsListFooterView.Model) -> Void)? { get set }
  var didUpdateIsEditing: ((Bool) -> Void)? { get set }
  
  func viewDidLoad()
  func moveWallet(fromIndex: Int, toIndex: Int)
  func didSelectWallet(at index: Int)
}

final class WalletsListViewModelImplementation: WalletsListViewModel, WalletsListModuleOutput {
  
  // MARK: - WalletsListModuleOutput
  
  var didTapAddWalletButton: (() -> Void)?
  var didSelectWallet: (() -> Void)?
    
  // MARK: - WalletsListViewModel
  
  var didUpdateHeaderItem: ((TKPullCardHeaderItem) -> Void)?
  var didUpdateItems: (([WalletsListWalletCell.Model]) -> Void)?
  var didUpdateSelectedItem: ((Int?, Bool) -> Void)?
  var didUpdateFooterModel: ((WalletsListFooterView.Model) -> Void)?
  var didUpdateIsEditing: ((Bool) -> Void)?
  
  func viewDidLoad() {
    setupWalletListControllerBindings()
    didUpdateFooterModel?(createFooterModel())
    didUpdateHeaderItem?(createHeaderItem())
    walletItems = self.createListItems()
  }
  
  func moveWallet(fromIndex: Int, toIndex: Int) {
    walletListController.moveWallet(fromIndex: fromIndex, toIndex: toIndex)
  }
  
  func didSelectWallet(at index: Int) {
    walletItems[index].selectionHandler?()
  }
  
  // MARK: - State
  
  private var isEditing = false {
    didSet {
      didUpdateIsEditing?(isEditing)
      didUpdateHeaderItem?(createHeaderItem())
      if !isEditing {
        didUpdateSelectedItem?(getSelectedItemIndex(), true)
      }
    }
  }
  
  private var walletItems = [WalletsListWalletCell.Model]() {
    didSet {
      didUpdateItems?(walletItems)
      didUpdateSelectedItem?(getSelectedItemIndex(), false)
    }
  }

  // MARK: - Dependencies
  
  private let walletListController: WalletListController
  
  init(walletListController: WalletListController) {
    self.walletListController = walletListController
  }
}

private extension WalletsListViewModelImplementation {
  func setupWalletListControllerBindings() {
    walletListController.didUpdateWallets = { [weak self] in
      guard let self = self else { return }
      Task { @MainActor in
        self.walletItems = self.createListItems()
        self.didUpdateHeaderItem?(self.createHeaderItem())
      }
    }
  }
  
  func createHeaderItem() -> TKPullCardHeaderItem {
    var leftButton: TKPullCardHeaderItem.LeftButton?
    if walletListController.walletsModels.count > 1 {
      let leftButtonModel = TKUIHeaderTitleIconButton.Model(title: isEditing ? "Done": "Edit")
      leftButton = TKPullCardHeaderItem.LeftButton(
        model: leftButtonModel) { [weak self] in
          self?.isEditing.toggle()
        }
    }
    return TKPullCardHeaderItem(
      title: "Wallets",
      leftButton: leftButton)
  }
  
  func createListItems() -> [WalletsListWalletCell.Model] {
    let models = walletListController.walletsModels
    let isSelectable = models.count > 1
    let isHighlightable = models.count > 1
    let items = models
      .enumerated()
      .map {
        index,
        walletModel in
        
        let contentModel = WalletsListWalletCellContentView.Model(
          emoji: walletModel.emoji,
          backgroundColor: .Tint.color(with: walletModel.colorIdentifier),
          walletName: walletModel.name,
          balance: walletModel.balance
        )
        
        return WalletsListWalletCell.Model(
          identifier: walletModel.identifier,
          isHighlightable: isHighlightable,
          isSelectable: isSelectable,
          selectionHandler: { [weak self] in
            guard isSelectable else { return }
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
            self?.didSelectWallet?()
            self?.walletListController.setWalletActive(with: walletModel.identifier)
          },
          cellContentModel: contentModel
        )
      }
    return items
  }
  
  func getSelectedItemIndex() -> Int? {
    guard walletListController.walletsModels.count > 1 else { return nil }
    return walletListController.activeWalletIndex
  }
  
  func createFooterModel() -> WalletsListFooterView.Model {
    WalletsListFooterView.Model(
      addWalletButtonModel: TKUIHeaderTitleIconButton.Model(title: "Add Wallet"),
      addWalletButtonAction: { [weak self] in
        self?.didTapAddWalletButton?()
      }
    )
  }
}