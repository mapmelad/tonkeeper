import UIKit

public final class TKFancyQRCodeView: UIView, ConfigurableView {
  
  public var color: UIColor = UIColor(hex: "CAFF7A", alpha: 1) {
    didSet {
      qrCodeContainer.backgroundColor = color
      bottomPartView.backgroundColor = color
    }
  }
  
  public let qrCodeContainer = UIView()
  public let qrCodeImageViewContainer = UIView()
  public let qrCodeImageView = UIImageView()
  public let bottomPartView = UIView()
  public let labelStackView = UIStackView()
  public let topLabel = UILabel()
  public let bottomLabel = UILabel()
  public let maskImageView = UIImageView(image: UIImage.imageWithName("Rectangle"))
  
  public override init(frame: CGRect) {
    super.init(frame: frame)
    setup()
  }
  
  public required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  public override func layoutSubviews() {
    super.layoutSubviews()
    bottomPartView.layoutIfNeeded()
    maskImageView.frame = bottomPartView.bounds
    qrCodeImageView.frame = qrCodeImageViewContainer.bounds
  }
  
  public struct Model {
    public let images: [UIImage]
    public let topString: String?
    public let bottomString: String?
    
    public init(images: [UIImage], topString: String?, bottomString: String?) {
      self.images = images
      self.topString = topString
      self.bottomString = bottomString
    }
  }
  
  public func configure(model: Model) {
    
    if model.images.isEmpty {
      qrCodeImageView.image = nil
    } else {
      qrCodeImageView.stopAnimating()
      qrCodeImageView.animationImages = fixImages(model.images)
      qrCodeImageView.animationDuration = 0.1 * TimeInterval(model.images.count)
      qrCodeImageView.startAnimating()
    }
    topLabel.text = model.topString?.uppercased()
    bottomLabel.text = model.bottomString?.uppercased()
    setNeedsLayout()
  }
}

private extension TKFancyQRCodeView {
  func setup() {
    labelStackView.axis = .vertical
    
    topLabel.textColor = .black
    topLabel.font = .monospacedSystemFont(ofSize: 14, weight: .medium)
    bottomLabel.textColor = .black
    bottomLabel.font = .monospacedSystemFont(ofSize: 14, weight: .medium)
    
    qrCodeContainer.backgroundColor = color
    qrCodeContainer.layer.cornerCurve = .continuous
    qrCodeContainer.layer.cornerRadius = 16
    qrCodeContainer.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
    
    bottomPartView.backgroundColor = color
    bottomPartView.mask = maskImageView
    
    qrCodeImageView.contentMode = .center

    addSubview(qrCodeContainer)
    qrCodeContainer.addSubview(qrCodeImageViewContainer)
    qrCodeImageViewContainer.addSubview(qrCodeImageView)
    addSubview(bottomPartView)
    bottomPartView.addSubview(labelStackView)
    labelStackView.addArrangedSubview(topLabel)
    labelStackView.addArrangedSubview(bottomLabel)
    
    setupConstraints()
  }
  
  func setupConstraints() {
    qrCodeContainer.snp.makeConstraints { make in
      make.top.left.right.equalTo(self)
    }
    
    qrCodeImageViewContainer.snp.makeConstraints { make in
      make.top.left.right.equalTo(qrCodeContainer).inset(24).priority(.high)
      make.bottom.equalTo(qrCodeContainer).priority(.high)
      make.height.equalTo(qrCodeImageViewContainer.snp.width)
    }

    bottomPartView.snp.makeConstraints { make in
      make.top.equalTo(qrCodeContainer.snp.bottom).offset(-1)
      make.left.right.equalTo(qrCodeContainer)
      make.height.equalTo(76)
      make.bottom.equalTo(self).priority(.high)
    }
    
    labelStackView.snp.makeConstraints { make in
      make.left.right.equalTo(bottomPartView).inset(24)
      make.top.equalTo(bottomPartView).offset(16)
      make.bottom.equalTo(bottomPartView).offset(-18).priority(.high)
    }
    
    topLabel.snp.makeConstraints { make in
      make.height.equalTo(20)
    }
    
    bottomLabel.snp.makeConstraints { make in
      make.height.equalTo(20)
    }
  }

  func fixImages(_ images: [UIImage]) -> [UIImage] {
    let context = CIContext(options: nil)
    return images.compactMap { image -> UIImage? in
      guard image.cgImage == nil else { return image }
      guard let ciImage = image.ciImage else { return nil }
      guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else {
        return nil
      }
      return UIImage(cgImage: cgImage)
    }
  }
}
