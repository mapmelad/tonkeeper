import UIKit
import TKUIKit
import SignerLocalize

final class SettingsRootItemsProvider: SettingsLiteItemsProvider {
  
  var title: String {
    SignerLocalize.Settings.title
  }
  
  var didTapChangePassword: (() -> Void)?
  var didTapLegal: (() -> Void)?
  
  private let urlOpener: URLOpener
  
  init(urlOpener: URLOpener) {
    self.urlOpener = urlOpener
  }
  
  func getSections() -> [SettingsSection] {
    createSections()
  }
  
  func createSections() -> [SettingsSection] {
    return [
      createFirstSection(),
      createSecondSection(),
      createFooterSection()
    ]
  }
  
  func createFirstSection() -> SettingsSection {
    SettingsSection(
      items: [
        createListItem(id: "ChangePasswordIdentifier",
                       title: SignerLocalize.Settings.Items.change_password,
                       image: .TKUIKit.Icons.Size28.lock,
                       tintColor: .Accent.blue,
                       action: { [weak self] in
                         self?.didTapChangePassword?()
                       })
      ]
    )
  }
  
  func createSecondSection() -> SettingsSection {
    SettingsSection(
      items: [
        createListItem(id: "SupportIdentifier",
                       title: SignerLocalize.Settings.Items.support,
                       image: .TKUIKit.Icons.Size28.messageBubble,
                       tintColor: .Accent.blue,
                       action: { [urlOpener] in
                         guard let url = InfoProvider.supportURL() else { return }
                         urlOpener.open(url: url)
                       }),
        createListItem(id: "LegalIdentifier",
                       title: SignerLocalize.Settings.Items.legal,
                       image: .TKUIKit.Icons.Size28.doc,
                       tintColor: .Icon.secondary,
                       action: { [weak self] in
                         self?.didTapLegal?()
                       })
      ]
    )
  }
  
  func createFooterSection() -> SettingsSection {
    var string = ""
    if let version = InfoProvider.appVersion() {
      string += version
    }
    if let build = InfoProvider.buildVersion() {
      string += "(\(build))"
    }
    
    return SettingsSection(items: [
      SettingsListFooterCell.Model(top: SignerLocalize.App.name,
                                   bottom: "\(SignerLocalize.Settings.Footer.version(string))")
    ])
  }
  
  func createListItem(id: String,
                      title: String,
                      subtitle: String? = nil,
                      image: UIImage?,
                      tintColor: UIColor,
                      action: @escaping () -> Void) -> TKUIListItemCell.Configuration {
    let accessoryConfiguration: TKUIListItemAccessoryView.Configuration
    if let image {
      accessoryConfiguration = .image(
        TKUIListItemImageAccessoryView.Configuration(
          image: image,
          tintColor: tintColor,
          padding: .zero
        )
      )
    } else {
      accessoryConfiguration = .none
    }
    
    return TKUIListItemCell.Configuration(
      id: id,
      listItemConfiguration: TKUIListItemView.Configuration(
        contentConfiguration: TKUIListItemContentView.Configuration(
          leftItemConfiguration: TKUIListItemContentLeftItem.Configuration(
            title: title.withTextStyle(
              .label1,
              color: .Text.primary,
              alignment: .left,
              lineBreakMode: .byTruncatingTail
            ),
            tagViewModel: nil,
            subtitle: nil,
            description: subtitle?.withTextStyle(.body2, color: .Text.secondary)
          ),
          rightItemConfiguration: nil
        ),
        accessoryConfiguration: accessoryConfiguration
      ),
      selectionClosure: {
        action()
      }
    )
  }
}

private extension String {
  static let deleteItemIdentifier = "DeleteItemIdentifier"
  static let nameItemIdentifier = "NameItemIdentifier"
  static let hexItemIdentifier = "HexItemIdentifier"
  static let recoveryPhraseItemIdentifier = "RecoveryPhraseItemIdentifier"
  static let linkToWebItemIdentifier = "LinkToWebItemIdentifier"
  static let linkToDeviceItemIdentifier = "LinkToDeviceItemIdentifier"
  static let qrCodeDescriptionItemIdentifier = "QRCodeDescriptionItemIdentifier"
}
