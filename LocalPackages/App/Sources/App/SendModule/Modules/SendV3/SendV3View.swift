import UIKit
import TKUIKit
import SnapKit

final class SendV3View: UIView {
  let scrollView = TKUIScrollView()
  let stackView: UIStackView = {
    let stackView = UIStackView()
    stackView.axis = .vertical
    stackView.spacing = .contentVerticalPadding
    stackView.isLayoutMarginsRelativeArrangement = true
    stackView.directionalLayoutMargins = NSDirectionalEdgeInsets(
      top: 0,
      leading: 16,
      bottom: 16,
      trailing: 16
    )
    return stackView
  }()
  
  let recipientTextField = TKTextField(
    textFieldInputView: TKTextFieldInputView(
      textInputControl: TKTextInputTextViewControl()
    )
  )
  
  let amountInputView = SendV3AmountInputView()
  
  let commentInputView = SendV3CommentInputView()
  
  let continueButton = TKButton(
    configuration: .actionButtonConfiguration(
      category: .primary,
      size: .large
    )
  )
  
  let recipientPasteButton = TKButton()
  let recipientScanButton = TKButton()
  let commentPasteButton = TKButton()

  override init(frame: CGRect) {
    super.init(frame: frame)
    setup()
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  private func setup() {
    recipientTextField.rightItems = [
      TKTextField.RightItem(view: recipientPasteButton, mode: .empty),
      TKTextField.RightItem(view: recipientScanButton, mode: .empty)
    ]
    commentInputView.commentTextField.rightItems = [TKTextField.RightItem(view: commentPasteButton, mode: .empty)]
    
    addSubview(scrollView)
    scrollView.addSubview(stackView)

    stackView.addArrangedSubview(recipientTextField)
    stackView.addArrangedSubview(amountInputView)
    stackView.addArrangedSubview(commentInputView)
    stackView.addArrangedSubview(continueButton)
    
    scrollView.snp.makeConstraints { make in
      make.edges.equalTo(self)
      make.width.equalTo(self)
    }
    
    stackView.snp.makeConstraints { make in
      make.top.equalTo(scrollView).offset(CGFloat.contentVerticalPadding)
      make.left.right.bottom.equalTo(scrollView).priority(.high)
      make.width.equalTo(scrollView)
    }
  }
}

private extension CGFloat {
  static let contentVerticalPadding: CGFloat = 16
}
