import UIKit
import TKCoordinator
import TKUIKit

public final class WalletCoordinator: RouterCoordinator<NavigationControllerRouter> {
  
  public override init(router: NavigationControllerRouter) {
    super.init(router: router)
    router.rootViewController.tabBarItem.title = "Wallet"
    router.rootViewController.tabBarItem.image = .TKUIKit.Icons.Size28.wallet
  }
  
  public override func start() {
    openWalletBalance()
  }
}

private extension WalletCoordinator {
  func openWalletBalance() {
    let module = WalletBalanceAssembly.module()
    
    router.push(viewController: module.view, animated: false)
  }
}