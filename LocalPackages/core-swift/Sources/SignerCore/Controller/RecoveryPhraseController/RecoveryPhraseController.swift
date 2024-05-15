import Foundation

public final class RecoveryPhraseController {
  private let key: WalletKey
  private let password: String
  private let mnemonicsRepository: MnemonicsRepository
  
  init(key: WalletKey, mnemonicsRepository: MnemonicsRepository, password: String) {
    self.key = key
    self.password = password
    self.mnemonicsRepository = mnemonicsRepository
  }
  
  public func getRecoveryPhrase() -> [String] {
    do {
      let phrase = try mnemonicsRepository.getMnemonic(walletKey: key, password: password)
      return phrase.mnemonicWords
    } catch {
      return []
    }
  }
}
