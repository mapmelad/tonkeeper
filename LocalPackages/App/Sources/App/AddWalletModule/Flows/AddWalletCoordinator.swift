import UIKit
import TKCoordinator
import TKUIKit
import KeeperCore

public final class AddWalletCoordinator: RouterCoordinator<ViewControllerRouter> {
  
  public var didCancel: (() -> Void)?
  public var didAddWallets: (() -> Void)?
  
  private var pairSignerCoordinator: PairSignerCoordinator?
  
  private let options: [AddWalletOption]
  private let walletAddController: WalletAddController
  private let createWalletCoordinatorProvider: (NavigationControllerRouter, _ passcode: String?) -> CreateWalletCoordinator
  private let importWalletCoordinatorProvider: (NavigationControllerRouter, _ passcode: String?, _ isTestnet: Bool) -> ImportWalletCoordinator
  private let importWatchOnlyWalletCoordinatorProvider: (NavigationControllerRouter, _ passcode: String?) -> ImportWatchOnlyWalletCoordinator
  private let pairSignerCoordinatorProvider: (NavigationControllerRouter, _ passcode: String?) -> PairSignerCoordinator
  private let createPasscodeCoordinatorProvider: ((NavigationControllerRouter) -> CreatePasscodeCoordinator)?
  
  init(router: ViewControllerRouter,
       options: [AddWalletOption],
       walletAddController: WalletAddController,
       createWalletCoordinatorProvider: @escaping (NavigationControllerRouter, _ passcode: String?) -> CreateWalletCoordinator,
       importWalletCoordinatorProvider: @escaping (NavigationControllerRouter, _ passcode: String?, _ isTestnet: Bool) -> ImportWalletCoordinator,
       importWatchOnlyWalletCoordinatorProvider: @escaping (NavigationControllerRouter, _ passcode: String?) -> ImportWatchOnlyWalletCoordinator,
       pairSignerCoordinatorProvider: @escaping (NavigationControllerRouter, _ passcode: String?) -> PairSignerCoordinator,
       createPasscodeCoordinatorProvider: ((NavigationControllerRouter) -> CreatePasscodeCoordinator)?) {
    self.walletAddController = walletAddController
    self.options = options
    self.createWalletCoordinatorProvider = createWalletCoordinatorProvider
    self.importWalletCoordinatorProvider = importWalletCoordinatorProvider
    self.importWatchOnlyWalletCoordinatorProvider = importWatchOnlyWalletCoordinatorProvider
    self.pairSignerCoordinatorProvider = pairSignerCoordinatorProvider
    self.createPasscodeCoordinatorProvider = createPasscodeCoordinatorProvider
    super.init(router: router)
  }
  
  public override func start() {
    openAddWalletOptionPicker()
  }
  
  public override func handleDeeplink(deeplink: CoordinatorDeeplink?) -> Bool {
    guard let tonkeeperDeeplink = deeplink as? TonkeeperDeeplink else { return false }
    
    switch tonkeeperDeeplink {
    case .signer(let signerDeeplink):
      guard let pairSignerCoordinator else { return false }
      return pairSignerCoordinator.handleDeeplink(deeplink: signerDeeplink)
    default:
      return false
    }
  }
}

private extension AddWalletCoordinator {
  func openAddWalletOptionPicker() {
    let module = AddWalletOptionPickerAssembly.module(
      options: options
    )
    let bottomSheetViewController = TKBottomSheetViewController(contentViewController: module.view)
    
    module.output.didSelectOption = { [weak self, unowned bottomSheetViewController] option in
      bottomSheetViewController.dismiss {
        self?.handleSelectedOption(option)
      }
    }
    
    bottomSheetViewController.didClose = { [weak self] interactivly in
      if interactivly {
        self?.didCancel?()
      }
    }
    
    bottomSheetViewController.present(fromViewController: router.rootViewController)
  }
  
  func handleSelectedOption(_ option: AddWalletOption) {
    let navigationController = TKNavigationController()
    navigationController.configureTransparentAppearance()
    let router = NavigationControllerRouter(rootViewController: navigationController)
    
    if let createPasscodeCoordinator = createPasscodeCoordinatorProvider?(router) {
      createPasscodeCoordinator.didCreatePasscode = { [weak self] passcode in
        self?.openOption(option: option, passcode: passcode, router: router)
      }
      
      createPasscodeCoordinator.didCancel = { [weak self, weak createPasscodeCoordinator] in
        navigationController.dismiss(animated: true) {
          self?.didCancel?()
        }
        guard let coordinator = createPasscodeCoordinator else { return }
        self?.removeChild(coordinator)
      }
      
      addChild(createPasscodeCoordinator)
      createPasscodeCoordinator.start()
      self.router.present(navigationController, onDismiss: { [weak self, weak createPasscodeCoordinator] in
        self?.didCancel?()
        guard let coordinator = createPasscodeCoordinator else { return }
        self?.removeChild(coordinator)
      })
    } else {
      openOption(option: option, passcode: nil, router: router)
      self.router.present(navigationController, onDismiss: { [weak self] in
        self?.didCancel?()
      })
    }
  }
  
  func openOption(option: AddWalletOption, passcode: String?, router: NavigationControllerRouter) {
    switch option {
    case .createRegular:
      openCreateRegularWallet(router: router, passcode: passcode)
    case .importRegular:
      openAddWallet(router: router, passcode: passcode, isTestnet: false)
    case .importWatchOnly:
      openAddWatchOnlyWallet(router: router, passcode: passcode)
    case .importTestnet:
      openAddWallet(router: router, passcode: passcode, isTestnet: true)
    case .signer:
      openPairSigner(router: router, passcode: passcode)
    }
  }
  
  func openCreateRegularWallet(router: NavigationControllerRouter, passcode: String?) {
    let coordinator = createWalletCoordinatorProvider(
      router, passcode
    )
    
    coordinator.didCancel = { [weak self, weak coordinator] in
      guard let coordinator = coordinator else { return }
      self?.removeChild(coordinator)
      router.dismiss(animated: true, completion: {
        self?.didCancel?()
      })
    }
    
    coordinator.didCreateWallet = { [weak self, weak coordinator] in
      guard let coordinator = coordinator else { return }
      self?.removeChild(coordinator)
      router.dismiss(animated: true, completion :{
        self?.didAddWallets?()
      })
    }
    
    addChild(coordinator)
    coordinator.start()
  }

  func openAddWatchOnlyWallet(router: NavigationControllerRouter, passcode: String?) {
    let coordinator = importWatchOnlyWalletCoordinatorProvider(
      router, passcode
    )
    
    coordinator.didCancel = { [weak self, weak coordinator] in
      router.dismiss(animated: true) {
        self?.didCancel?()
      }
      guard let coordinator = coordinator else { return }
      self?.removeChild(coordinator)
    }
    
    coordinator.didImportWallet = { [weak self, weak coordinator] in
      guard let coordinator = coordinator else { return }
      self?.removeChild(coordinator)
      router.dismiss(animated: true) {
        self?.didAddWallets?()
      }
    }
    
    addChild(coordinator)
    coordinator.start()
  }

  func openAddWallet(router: NavigationControllerRouter, passcode: String?, isTestnet: Bool) {
    let coordinator = importWalletCoordinatorProvider(
      router, passcode, isTestnet
    )
    
    coordinator.didCancel = { [weak self, weak coordinator] in
      guard let coordinator = coordinator else { return }
      self?.removeChild(coordinator)
      self?.didCancel?()
    }
    
    coordinator.didImportWallets = { [weak self, weak coordinator] in
      guard let coordinator = coordinator else { return }
      self?.removeChild(coordinator)
      router.dismiss(animated: true) {
        self?.didAddWallets?()
      }
    }
    
    addChild(coordinator)
    coordinator.start()
  }
  
  func openPairSigner(router: NavigationControllerRouter, passcode: String?) {
    let coordinator = pairSignerCoordinatorProvider(
      router, passcode
    )
    
    coordinator.didCancel = { [weak self, weak coordinator] in
      router.dismiss(animated: true) {
        self?.didCancel?()
      }
      self?.pairSignerCoordinator = nil
      guard let coordinator else { return }
      self?.removeChild(coordinator)
    }
    
    coordinator.didPaired = {[weak self, weak coordinator] in
      router.dismiss(animated: true) {
        self?.didAddWallets?()
      }
      self?.pairSignerCoordinator = nil
      guard let coordinator else { return }
      self?.removeChild(coordinator)
    }
    
    self.pairSignerCoordinator = coordinator
    
    addChild(coordinator)
    coordinator.start()
  }
}
