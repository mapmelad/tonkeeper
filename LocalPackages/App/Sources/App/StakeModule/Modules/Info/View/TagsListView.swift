//
//  TagsListView.swift
//
//
//  Created by Semyon on 19/05/2024.
//

import SnapKit
import TKUIKit
import UIKit


final class TagsListView: UIView {
  struct Model {
    let tags: [TagView.Model]
  }

  let verticalStackView = UIStackView()
  private var previousWidth: CGFloat = 0
  private let tags: [TagView.Model]

  init(model: Model) {
    self.tags = model.tags
    super.init(frame: .zero)
    setup()
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  private func setup() {
    addSubview(verticalStackView)
    verticalStackView.axis = .vertical
    verticalStackView.spacing = 8
    verticalStackView.isLayoutMarginsRelativeArrangement = true
    verticalStackView.layoutMargins = UIEdgeInsets(top: 0, left: 0, bottom: 16, right: 0)
    verticalStackView.snp.makeConstraints { make in
      make.edges.equalTo(self)
      make.height.greaterThanOrEqualTo(48)
      make.width.greaterThanOrEqualTo(48)
    }
  }

  override func layoutSubviews() {
    if bounds.size.width == previousWidth {
      super.layoutSubviews()
      return
    }
    previousWidth = bounds.size.width
    let availableWidth: CGFloat = bounds.size.width - (verticalStackView.layoutMargins.left + verticalStackView.layoutMargins.right)
    let makeRow: () -> HorizontalStackView = {
      let row = HorizontalStackView()
      row.frame.size.width = availableWidth
      row.spacing = 8
      return row
    }
    verticalStackView.subviews.forEach(verticalStackView.removeArrangedSubview(_:))
    var currentRow: HorizontalStackView = makeRow()
    verticalStackView.addArrangedSubview(currentRow)
    for tagModel in tags {
      let tagView = TagView(model: tagModel)
      tagView.setNeedsLayout()
      tagView.layoutIfNeeded()
      if !currentRow.canFit(view: tagView) {
        currentRow = makeRow()
        verticalStackView.addArrangedSubview(currentRow)
        // TODO: We intentionally don't bother with views that larger than container width here...
      }
      currentRow.addSubview(tagView)
    }
    super.layoutSubviews()
  }
}

final class TagView: UIView {
  struct Model {
    let icon: UIImage
    let title: String
  }

  let imageView: UIImageView
  let titleLabel = UILabel()

  init(model: Model) {
    self.imageView = UIImageView(image: model.icon)
    super.init(frame: .zero)
    setup(with: model)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  private func setup(with model: Model) {
    addSubview(imageView)
    addSubview(titleLabel)

    imageView.tintColor = .Button.secondaryForeground
    backgroundColor = .Button.secondaryBackground
    layer.cornerRadius = 18

    imageView.setContentHuggingPriority(.required, for: .horizontal)
    titleLabel.setContentHuggingPriority(.required, for: .horizontal)
    setContentHuggingPriority(.required, for: .horizontal)

    imageView.setContentCompressionResistancePriority(.required, for: .horizontal)
    titleLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
    setContentCompressionResistancePriority(.required, for: .horizontal)

    titleLabel.attributedText = model.title.withTextStyle(
      .label2,
      color: .Button.secondaryForeground
    )

    imageView.snp.makeConstraints { make in
      make.width.equalTo(16)
      make.height.equalTo(16)
      make.leading.equalTo(snp.leading).offset(16)
      make.centerY.equalTo(snp.centerY)
    }

    titleLabel.snp.makeConstraints { make in
      make.leading.equalTo(imageView.snp.trailing).offset(8)
      make.centerY.equalTo(snp.centerY)
      make.trailing.equalTo(snp.trailing).offset(-16)
    }

    snp.makeConstraints { make in
      make.height.equalTo(36)
    }
  }
}

final class HorizontalStackView: UIView {
  var spacing: CGFloat = 0
  private var maxX: CGFloat = 0

  override func addSubview(_ view: UIView) {
    super.addSubview(view)
    view.frame.origin.y = 0
    view.frame.origin.x = maxX
    maxX += view.bounds.width + spacing
  }

  override var intrinsicContentSize: CGSize {
    var offset: CGFloat = 0
    let size = subviews.reduce(into: CGSize.zero) { partialResult, view in
      offset += view.bounds.width
      partialResult.height = max(partialResult.height, view.bounds.height)
      partialResult.width = offset
      offset += spacing
    }
    return size
  }

  override func layoutSubviews() {
    super.layoutSubviews()
    var offset: CGFloat = 0
    for v in subviews {
      v.frame.origin.y = 0
      v.frame.origin.x = offset
      offset = v.bounds.width + spacing
    }
    maxX = offset
  }

  func canFit(view: UIView) -> Bool {
    let availableSpace = bounds.width - maxX
    return availableSpace >= view.bounds.width
  }
}
