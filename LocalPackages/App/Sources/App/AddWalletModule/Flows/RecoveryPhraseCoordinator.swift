import UIKit
import KeeperCore
import TKCore
import TKCoordinator
import TKUIKit
import TKScreenKit
import TKLocalize

public final class RecoveryPhraseCoordinator: RouterCoordinator<NavigationControllerRouter> {
  
  public var didCancel: (() -> Void)?
  public var didImportWallets: (([String], [WalletContractVersion]) -> Void)?
  
  private let walletsUpdateAssembly: WalletsUpdateAssembly
  private let isTestnet: Bool
  
  init(router: NavigationControllerRouter,
       walletsUpdateAssembly: WalletsUpdateAssembly,
       isTestnet: Bool) {
    self.walletsUpdateAssembly = walletsUpdateAssembly
    self.isTestnet = isTestnet
    super.init(router: router)
  }
  
  public override func start() {
    openInputRecoveryPhrase()
  }
}

private extension RecoveryPhraseCoordinator {
  func openInputRecoveryPhrase() {
    let inputRecoveryPhrase = TKInputRecoveryPhraseAssembly.module(
      title: TKLocales.ImportWallet.title,
      caption: TKLocales.ImportWallet.description,
      continueButtonTitle: TKLocales.Actions.continue_action,
      pasteButtonTitle: TKLocales.Actions.paste,
      validator: AddWalletInputRecoveryPhraseValidator(),
      suggestsProvider: AddWalletInputRecoveryPhraseSuggestsProvider()
    )
    
    inputRecoveryPhrase.output.didInputRecoveryPhrase = { [weak self] phrase, completion in
      guard let self = self else { return }
      self.detectActiveWallets(phrase: phrase, completion: completion)
    }
    
    if router.rootViewController.viewControllers.isEmpty {
      inputRecoveryPhrase.viewController.setupLeftCloseButton { [weak self] in
        self?.didCancel?()
      }
    } else {
      inputRecoveryPhrase.viewController.setupBackButton()
    }
    
    router.push(
      viewController: inputRecoveryPhrase.viewController,
      animated: true,
      onPopClosures: { [weak self] in
        self?.didCancel?()
      },
      completion: nil)
  }
  
  func detectActiveWallets(phrase: [String], completion: @escaping () -> Void) {
    Task {
      do {
        let activeWallets = try await walletsUpdateAssembly.walletImportController().findActiveWallets(
          phrase: phrase,
          isTestnet: isTestnet
        )
        await MainActor.run {
          completion()
          handleActiveWallets(phrase: phrase, activeWalletModels: activeWallets)
        }
      } catch {
        await MainActor.run {
          completion()
        }
      }
    }
  }
  
  func handleActiveWallets(phrase: [String], activeWalletModels: [ActiveWalletModel]) {
    if activeWalletModels.count == 1, activeWalletModels[0].revision == WalletContractVersion.currentVersion {
      didImportWallets?(phrase, [WalletContractVersion.currentVersion])
    } else {
      openChooseWalletToAdd(phrase: phrase, activeWalletModels: activeWalletModels)
    }
  }
  
  func openChooseWalletToAdd(phrase: [String], activeWalletModels: [ActiveWalletModel]) {
    let controller = walletsUpdateAssembly.chooseWalletController(activeWalletModels: activeWalletModels)
    let module = ChooseWalletToAddAssembly.module(controller: controller)
    
    module.output.didSelectRevisions = { [weak self] revisions in
      self?.didImportWallets?(phrase, revisions)
    }
    
    module.view.setupBackButton()
    
    router.push(
      viewController: module.view,
      animated: true,
      onPopClosures: {},
      completion: nil)
  }
}
