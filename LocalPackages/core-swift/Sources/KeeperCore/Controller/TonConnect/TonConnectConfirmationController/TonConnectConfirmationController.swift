import Foundation
import TonSwift
import BigInt

public final class TonConnectConfirmationController {
  public struct Model {
    public let event: HistoryEvent
    public let fee: String
    public let walletName: String
  }
  
  private let wallet: Wallet
  private let appRequest: TonConnect.AppRequest
  private let app: TonConnectApp
  private let tonConnectService: TonConnectService
  private let sendService: SendService
  private let nftService: NFTService
  private let ratesStore: RatesStore
  private let currencyStore: CurrencyStore
  private let tonConnectConfirmationMapper: TonConnectConfirmationMapper
  
  init(wallet: Wallet,
       appRequest: TonConnect.AppRequest,
       app: TonConnectApp,
       tonConnectService: TonConnectService,
       sendService: SendService,
       nftService: NFTService,
       ratesStore: RatesStore,
       currencyStore: CurrencyStore,
       tonConnectConfirmationMapper: TonConnectConfirmationMapper) {
    self.wallet = wallet
    self.appRequest = appRequest
    self.app = app
    self.tonConnectService = tonConnectService
    self.sendService = sendService
    self.nftService = nftService
    self.ratesStore = ratesStore
    self.currencyStore = currencyStore
    self.tonConnectConfirmationMapper = tonConnectConfirmationMapper
  }
  
  public func createRequestModel() async throws -> Model {
    guard let parameters = appRequest.params.first else { throw NSError(domain: "", code: 3232) }
    let model = try await emulateAppRequest(appRequestParam: parameters)
    return model
  }
  
  public func cancel() async {
    try? await tonConnectService.cancelRequest(appRequest: appRequest, app: app)
  }
  
  public func confirm() async throws {
    guard let parameters = appRequest.params.first else { return }
    let seqno = try await sendService.loadSeqno(wallet: wallet)
    let boc = try await tonConnectService.createConfirmTransactionBoc(
      wallet: wallet,
      seqno: seqno,
      parameters: parameters
    )
    
    try await sendService.sendTransaction(boc: boc, wallet: wallet)
    try await tonConnectService.confirmRequest(boc: boc, appRequest: appRequest, app: app)
  }
}

private extension TonConnectConfirmationController {
  func emulateAppRequest(appRequestParam: TonConnect.AppRequest.Param) async throws -> Model {
    let seqno = try await sendService.loadSeqno(wallet: wallet)
    let boc = try await tonConnectService.createEmulateRequestBoc(
      wallet: wallet,
      seqno: seqno,
      parameters: appRequestParam
    )
    
    let currency = await currencyStore.getActiveCurrency()
    let rates = ratesStore.getRates(jettons: []).ton.first(where: { $0.currency == currency })
    let transactionInfo = try await sendService.loadTransactionInfo(boc: boc, wallet: wallet)
    let event = try AccountEvent(accountEvent: transactionInfo.event)
    let nfts = try await loadEventNFTs(event: event)
    
    return try tonConnectConfirmationMapper.mapTransactionInfo(
      transactionInfo,
      tonRates: rates,
      currency: currency,
      nftsCollection: nfts,
      wallet: wallet
    )
  }
  
  func createRequestTransactionBoc(parameters: TonConnect.AppRequest.Param,
                                   signClosure: (WalletTransfer) async throws -> Data) async throws  -> String{
    let seqno = try await sendService.loadSeqno(wallet: wallet)
    let payloads = parameters.messages.map { message in
        TonConnectTransferMessageBuilder.Payload(
            value: BigInt(integerLiteral: message.amount),
            recipientAddress: message.address,
            stateInit: message.stateInit,
            payload: message.payload)
    }
    return try await TonConnectTransferMessageBuilder.sendTonConnectTransfer(
      wallet: wallet,
      seqno: seqno,
      payloads: payloads,
      sender: parameters.from,
      signClosure: signClosure)
  }
  
  func loadEventNFTs(event: AccountEvent) async throws -> NFTsCollection {
    var nftAddressesToLoad = Set<Address>()
    var nfts = [Address: NFT]()
    for action in event.actions {
      switch action.type {
      case .nftItemTransfer(let nftItemTransfer):
        nftAddressesToLoad.insert(nftItemTransfer.nftAddress)
      case .nftPurchase(let nftPurchase):
        nfts[nftPurchase.nft.address] = nftPurchase.nft
        try? nftService.saveNFT(nft: nftPurchase.nft, isTestnet: wallet.isTestnet)
      default: continue
      }
    }
    
    if let loadedNFTs = try? await nftService.loadNFTs(addresses: Array(nftAddressesToLoad), isTestnet: wallet.isTestnet) {
      nfts.merge(loadedNFTs, uniquingKeysWith: { $1 })
    }
    
    return NFTsCollection(nfts: nfts)
  }
}
