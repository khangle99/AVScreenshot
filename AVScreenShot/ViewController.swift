//
//  ViewController.swift
//  AVScreenShot
//
//  Created by LAP15651 on 27/09/2022.
//

import UIKit
import AVKit
import VideoToolbox

class ViewController: UIViewController {
    
    @IBOutlet weak var playerContainer: UIView!
    private var player: AVPlayer!
    private var videoOutput: AVPlayerItemVideoOutput!
    
    @IBOutlet weak var thumbholderImageVIew: UIImageView!
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        setupStream()
    }
    
    private func setupStream() {

        let urlStr = "https://cph-p2p-msl.akamaized.net/hls/live/2000341/test/master.m3u8"
      
        videoOutput = AVPlayerItemVideoOutput()
        let item = AVPlayerItem(url: URL(string: urlStr)!)
        item.add(videoOutput) // capture avplayer current frame through videoOutput
        
        player = AVPlayer(playerItem: item)
        let layer = AVPlayerLayer(player: player)
        //layer.videoGravity = .resize
        layer.frame = playerContainer.layer.bounds
        
        playerContainer.layer.addSublayer(layer)
        player.play()
    }
    
    override func viewWillAppear(_ animated: Bool) {
      super.viewWillAppear(animated)
        NotificationCenter.default.addObserver(self, selector: #selector(handleScreenshot), name: UIApplication.userDidTakeScreenshotNotification, object: nil)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
      super.viewDidDisappear(animated)
        NotificationCenter.default.removeObserver(self, name: UIApplication.userDidTakeScreenshotNotification, object: nil)
    }
    
    @objc func handleScreenshot() {
        
        // capture avplayer screenshot
        thumbholderImageVIew.image = imageFromCurrentPlayerContext()
        
        // capture whole screen
        thumbholderImageVIew.isHidden = false
        let img = view.asImage()
        thumbholderImageVIew.isHidden = true
        
        // add watermark
        let logo = UIImage(named: "logo")!
        let qr = UIImage(named: "sampleqr")!
        
        let processedImg = addWaterMark(originImage: img, logoImage: logo, title: "Sing nowdqwdqwdqwdqwdqwdqwdq", subtitle: "Author NamedqdqqwdqdqwdqqNamedqdqqwdqdqwdqqNamedqdqqwdqdqwdqq", qrImage: qr)
        
        let urlString = "Something"
        
        let activityVC = UIActivityViewController(activityItems: [urlString, processedImg], applicationActivities: nil)
        self.present(activityVC, animated: true, completion: nil)

    }
    
    /// To add watermark to image
    /// - Parameters:
    ///   - originImage: origin image
    ///   - logoImage: app logo
    ///   - title: title for big label
    ///   - subtitle: subtitle
    ///   - qrImage: qrcode image
    /// - Returns: Image which include app watermark
    private func addWaterMark(originImage: UIImage, logoImage: UIImage, title: String, subtitle: String, qrImage: UIImage) -> UIImage {
        
        let originalSize = originImage.size
        let watermarkHeight: CGFloat = originalSize.height*0.1
        let spacing: CGFloat = 10
        
        let containerView = UIView(frame: CGRect(origin: .zero, size: CGSize(width: originalSize.width, height: originalSize.height + watermarkHeight)))
        
        // add image
        let imageView = UIImageView(image: originImage)
        containerView.addSubview(imageView)
        
        // let watermark container
        let stack = UIStackView(frame: CGRect(origin: CGPoint(x: 0, y: imageView.frame.height), size: CGSize(width: originalSize.width, height: watermarkHeight)))
        stack.spacing = spacing
        stack.axis = .horizontal
        stack.distribution = .fill
        stack.alignment = .center
        stack.layoutMargins = .init(top: 0, left: 16, bottom: 0, right: 16)
        stack.isLayoutMarginsRelativeArrangement = true
        
        stack.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            stack.topAnchor.constraint(equalTo: containerView.bottomAnchor),
            stack.heightAnchor.constraint(equalToConstant: watermarkHeight)
        ])
       
        
        // add logo
        let logoImageView = UIImageView()
     
        logoImageView.contentMode = .scaleAspectFit
        logoImageView.image = logoImage
        stack.addArrangedSubview(logoImageView)
        NSLayoutConstraint.activate([
            logoImageView.widthAnchor.constraint(equalToConstant: watermarkHeight*0.6),
            logoImageView.heightAnchor.constraint(equalToConstant: watermarkHeight*0.6),
        ])
        
        // add title & subtitle
        let songInfoStack = UIStackView()
        songInfoStack.axis = .vertical
        songInfoStack.alignment = .leading
        songInfoStack.distribution = .fillEqually
        
        let titleLabel = UILabel()
        titleLabel.textColor = .black
        titleLabel.text = title
        titleLabel.sizeToFit()
        songInfoStack.addArrangedSubview(titleLabel)
        
        let subtitleLabel = UILabel()
        subtitleLabel.textColor = .black
        subtitleLabel.text = subtitle
        subtitleLabel.font = .systemFont(ofSize: 12)
        subtitleLabel.sizeToFit()
        songInfoStack.addArrangedSubview(subtitleLabel)
        
        stack.addArrangedSubview(songInfoStack)
        NSLayoutConstraint.activate([
            songInfoStack.heightAnchor.constraint(equalTo: logoImageView.heightAnchor)
        ])
        
        // add qr
        let qrImageView = UIImageView()
        qrImageView.contentMode = .scaleAspectFit
        qrImageView.image = qrImage
        stack.addArrangedSubview(qrImageView)
        NSLayoutConstraint.activate([
            qrImageView.widthAnchor.constraint(equalToConstant: watermarkHeight*0.85)
        ])
        
        stack.layoutIfNeeded()
        let renderer = UIGraphicsImageRenderer(bounds: containerView.frame)
        return renderer.image { ctx in
            containerView.layer.render(in: ctx.cgContext)
        }
        
    }

    private func imageFromCurrentPlayerContext() -> UIImage? {
        
        let buffer = self.videoOutput.copyPixelBuffer(forItemTime: self.player.currentTime(), itemTimeForDisplay: nil)
        if let buffer = buffer {
            return UIImage(pixelBuffer: buffer)
        }
        
        return nil
    }
    
}

extension UIView {
    func asImage() -> UIImage {
        let renderer = UIGraphicsImageRenderer(bounds: bounds)
        return renderer.image { rendererContext in
            layer.render(in: rendererContext.cgContext)
        }
    }
}


extension UIImage {
    public convenience init?(pixelBuffer: CVPixelBuffer) {
        var cgImage: CGImage?
        VTCreateCGImageFromCVPixelBuffer(pixelBuffer, options: nil, imageOut: &cgImage)

        guard let cgImage = cgImage else {
            return nil
        }

        self.init(cgImage: cgImage)
    }
}
