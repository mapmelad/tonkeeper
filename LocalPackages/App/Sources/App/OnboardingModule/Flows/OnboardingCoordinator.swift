import UIKit
import TKCoordinator
import TKUIKit
import TKCore
import KeeperCore

public final class OnboardingCoordinator: RouterCoordinator<NavigationControllerRouter> {
  
  private weak var addWalletCoordinator: AddWalletCoordinator?
  
  private let coreAssembly: TKCore.CoreAssembly
  private let keeperCoreOnboardingAssembly: KeeperCore.OnboardingAssembly
  
  public var didFinishOnboarding: (() -> Void)?
  
  init(router: NavigationControllerRouter,
       coreAssembly: TKCore.CoreAssembly,
       keeperCoreOnboardingAssembly: KeeperCore.OnboardingAssembly) {
    self.coreAssembly = coreAssembly
    self.keeperCoreOnboardingAssembly = keeperCoreOnboardingAssembly
    super.init(router: router)
  }
  
  public override func start(deeplink: CoordinatorDeeplink? = nil) {
    openOnboardingStart()
    _ = handleDeeplink(deeplink: deeplink)
  }
  
  public override func handleDeeplink(deeplink: CoordinatorDeeplink?) -> Bool {
    guard let coreDeeplink = deeplink as? KeeperCore.Deeplink else { return false }
    return handleCoreDeeplink(coreDeeplink)
  }
}

private extension OnboardingCoordinator {
  func openOnboardingStart() {
    let module = OnboardingRootAssembly.module()
    
    module.output.didTapCreateButton = { [weak self] in
      self?.openCreate()
    }
    
    module.output.didTapImportButton = { [weak self] in
      guard let self else { return }
      self.openAddWallet(router: ViewControllerRouter(rootViewController: self.router.rootViewController))
    }
    
    router.push(viewController: module.view, animated: false)
  }
  
  func openCreate() {
    let navigationController = TKNavigationController()
    navigationController.configureTransparentAppearance()
    navigationController.isModalInPresentation = true
    
    let coordinator = OnboardingCreateCoordinator(
      router: NavigationControllerRouter(rootViewController: navigationController),
      assembly: keeperCoreOnboardingAssembly,
      coreAssembly: coreAssembly
    )
    coordinator.didCancel = { [weak self, weak coordinator, weak navigationController] in
      guard let coordinator = coordinator else { return }
      self?.removeChild(coordinator)
      navigationController?.dismiss(animated: true)
    }
    
    coordinator.didCreateWallet = { [weak self, weak coordinator] in
      guard let coordinator = coordinator else { return }
      self?.removeChild(coordinator)
      self?.didFinishOnboarding?()
      navigationController.dismiss(animated: true)
    }
    
    addChild(coordinator)
    coordinator.start()
    
    router.present(navigationController)
  }
  
  func openAddWallet(router: ViewControllerRouter) {
    let module = AddWalletModule(
      dependencies: AddWalletModule.Dependencies(
        walletsUpdateAssembly: keeperCoreOnboardingAssembly.walletsUpdateAssembly,
        coreAssembly: coreAssembly,
        scannerAssembly: keeperCoreOnboardingAssembly.scannerAssembly(),
        passcodeAssembly: keeperCoreOnboardingAssembly.passcodeAssembly
      )
    )
    
    let coordinator = module.createAddWalletCoordinator(options: [.importRegular, .importWatchOnly, .importTestnet, .signer],
                                                        createPasscode: true,
                                                        router: router)
    coordinator.didAddWallets = { [weak self, weak coordinator] in
      self?.didFinishOnboarding?()
      guard let coordinator else { return }
      self?.removeChild(coordinator)
    }
    coordinator.didCancel = { [weak self, weak coordinator] in
      guard let coordinator else { return }
      self?.removeChild(coordinator)
    }
    
    addWalletCoordinator = coordinator
    
    addChild(coordinator)
    coordinator.start()
  }
  
  func handleCoreDeeplink(_ deeplink: KeeperCore.Deeplink) -> Bool {
    switch deeplink {
    case .tonkeeper(let tonkeeperDeeplink):
      return handleTonkeeperDeeplink(tonkeeperDeeplink)
    default:
      return false
    }
  }
  
  func handleTonkeeperDeeplink(_ deeplink: TonkeeperDeeplink) -> Bool {
    switch deeplink {
    case .signer(let signerDeeplink):
      if let addWalletCoordinator, addWalletCoordinator.handleDeeplink(deeplink: deeplink) {
        return true
      }
      router.dismiss(animated: true) { [weak self] in
        self?.handleSignerDeeplink(signerDeeplink)
      }
      return true
    case let .publish(model):
      // TODO:
      return false
    }
  }
  
  func handleSignerDeeplink(_ deeplink: TonkeeperDeeplink.SignerDeeplink) {
    
    let navigationController = TKNavigationController()
    navigationController.configureTransparentAppearance()
    
    switch deeplink {
    case .link(let publicKey, let name):
      openCreatePasscode { [weak self, keeperCoreOnboardingAssembly, coreAssembly] passcode in
        guard let passcode else { return }
        let coordinator = AddWalletModule(
          dependencies: AddWalletModule.Dependencies(
            walletsUpdateAssembly: keeperCoreOnboardingAssembly.walletsUpdateAssembly,
            coreAssembly: coreAssembly,
            scannerAssembly: keeperCoreOnboardingAssembly.scannerAssembly(),
            passcodeAssembly: keeperCoreOnboardingAssembly.passcodeAssembly
          )
        ).createPairSignerImportCoordinator(
          publicKey: publicKey,
          name: name,
          passcode: passcode,
          router: NavigationControllerRouter(
            rootViewController: navigationController
          )
        )
        
        coordinator.didPrepareForPresent = { [weak self] in
          self?.router.present(navigationController)
        }
        
        coordinator.didCancel = { [weak self, weak coordinator, weak navigationController] in
          navigationController?.dismiss(animated: true)
          guard let coordinator else { return }
          self?.removeChild(coordinator)
        }
        
        coordinator.didPaired = { [weak self, weak coordinator, weak navigationController] in
          navigationController?.dismiss(animated: true, completion: {
            self?.didFinishOnboarding?()
          })
          guard let coordinator else { return }
          self?.removeChild(coordinator)
        }
        
        self?.addChild(coordinator)
        coordinator.start()
      }
    }
  }
  
  func openCreatePasscode(completion: @escaping (String?) -> Void) {
    let navigationController = TKNavigationController()
    navigationController.configureTransparentAppearance()
    
    let coordinator = PasscodeModule(
      dependencies: PasscodeModule.Dependencies(
        passcodeAssembly: keeperCoreOnboardingAssembly.passcodeAssembly
      )
    ).createCreatePasscodeCoordinator(router: NavigationControllerRouter(rootViewController: navigationController))
    
    coordinator.didCreatePasscode = { passcode in
      navigationController.dismiss(animated: true) {
        completion(passcode)
      }
    }
    
    coordinator.didCancel = { [weak self, weak coordinator] in
      navigationController.dismiss(animated: true) {
        completion(nil)
      }
      guard let coordinator = coordinator else { return }
      self?.removeChild(coordinator)
    }
    
    addChild(coordinator)
    coordinator.start()
    
    router.present(navigationController)
  }
}
