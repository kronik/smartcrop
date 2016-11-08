//
//  ViewController.swift
//  SmartCrop
//
//  Created by Dmitry on 4/11/16.
//  Copyright © 2016 Dmitry Klimkin. All rights reserved.
//

import UIKit
import CoreImage

class ViewController: UIViewController {
    
    private var imageView: UIImageView!
    private var nextStepButton: UIButton!
    private var rect: CIRectangleFeature = CIRectangleFeature()
    private var cropedImage: UIImage!
    private var finalImage: UIImage!
    private var infoLabel: UILabel!
    private var currentStep = 0
    private var time: TimeInterval = 0
    private var cropRect: CropRect!
    private var useCI = true

    private let originalImage = UIImage(named: "doc")
    private let ciContext = CIContext(options: nil)

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        buildUI()
    }
    
    private func buildUI() {
        view.backgroundColor = UIColor.black
        
        let imageWidth = view.frame.width
        let imageHeight = imageWidth / 3 * 4
        let infoHeight: CGFloat = 50
        
        var yOffset: CGFloat = 0
        
        infoLabel = UILabel(frame: CGRect(x: 0.0, y: 0.0, width: imageWidth, height: infoHeight))
        
        infoLabel.font = UIFont.systemFont(ofSize: 13.0)
        infoLabel.textAlignment = .center
        infoLabel.textColor = UIColor.white
        infoLabel.numberOfLines = 0
        infoLabel.lineBreakMode = .byWordWrapping;
        infoLabel.text = "Original Image"

        view.addSubview(infoLabel)

        yOffset += infoHeight
        
        imageView = UIImageView(frame: CGRect(x: 0, y: 50, width: imageWidth, height: imageHeight))
        
        imageView.backgroundColor = UIColor.black
        imageView.contentMode = .scaleAspectFit
        imageView.image = originalImage
        
        view.addSubview(imageView)
        
        yOffset += imageHeight
        
        nextStepButton = UIButton(type: .custom)
        
        nextStepButton.frame = CGRect(x: 0, y: yOffset, width: imageWidth, height: view.frame.height - yOffset)
        
        nextStepButton.setTitle("Detect Edges", for: .normal)
        nextStepButton.setTitleColor(.white, for: .normal)
        nextStepButton.setTitleColor(.darkGray, for: .selected)
        nextStepButton.setTitleColor(.darkGray, for: .highlighted)
        
        nextStepButton.addTarget(self, action: #selector(ViewController.onNextStep), for: .touchUpInside)
        
        view.addSubview(nextStepButton)
        
        currentStep = 1
    }
    
    func onNextStep() {
        currentStep += 1
        
        switch currentStep {
        case 1:
            useCI ? executeCIStep1() : executeOpenCVStep1()
            break
            
        case 2:
            useCI ? executeCIStep2() : executeOpenCVStep2()
            break

        case 3:
            useCI ? executeCIStep3() : executeOpenCVStep3()
            break
            
        case 4:
            useCI ? executeCIStep4() : executeOpenCVStep4()
            break
            
        default:
            currentStep = 0
            useCI = !useCI
            onNextStep()
            break
        }
    }
    
    private func executeCIStep1() {
        infoLabel.text = "Original Image"
        nextStepButton.setTitle("Detect Edges", for: .normal)
        imageView.image = originalImage
        
        time = 0
    }

    private func executeOpenCVStep1() {
        infoLabel.text = "Original Image"
        nextStepButton.setTitle("Detect Edges", for: .normal)
        imageView.image = originalImage
        
        time = 0
    }
    
    private func executeCIStep2() {
        infoLabel.text = "Detected Edges"
        nextStepButton.setTitle("Working...", for: .normal)
        
        let startTime = Date()
        
        let docImage = CIImage(image: originalImage!)!
        
        if let detector = CIDetector(ofType: CIDetectorTypeRectangle,
                                     context: ciContext,
                                     options: [CIDetectorAccuracy: CIDetectorAccuracyHigh]) {
            
            rect = detector.features(in: docImage).first as! CIRectangleFeature
        }
        
        var overlay = CIImage(color: CIColor(red: 0, green: 0, blue: 1, alpha: 0.5))
        
        overlay = overlay.cropping(to: docImage.extent)
        
        overlay = overlay.applyingFilter("CIPerspectiveTransformWithExtent", withInputParameters:
            [kCIInputExtentKey : CIVector(cgRect: docImage.extent),
             "inputTopLeft": CIVector(cgPoint:rect.topLeft),
             "inputTopRight": CIVector(cgPoint:rect.topRight),
             "inputBottomRight": CIVector(cgPoint:rect.bottomRight),
             "inputBottomLeft": CIVector(cgPoint:rect.bottomLeft)
            ] )
        
        let image = overlay.compositingOverImage(docImage)
        
        let updatedImage = UIImage(ciImage: image, scale: originalImage!.scale, orientation: originalImage!.imageOrientation)
        
        time += Date().timeIntervalSince(startTime)
        
        imageView.image = updatedImage
        nextStepButton.setTitle("Crop Image", for: .normal)
    }

    private func executeOpenCVStep2() {
        infoLabel.text = "Detected Edges"
        nextStepButton.setTitle("Working...", for: .normal)
        
        let startTime = Date()
        
        cropRect = imageView.detectEdges()
        
        imageView.showCrop(cropRect)
        
        time += Date().timeIntervalSince(startTime)
        
        nextStepButton.setTitle("Crop Image", for: .normal)
    }
    
    private func executeCIStep3() {
        infoLabel.text = "Croped Image"
        nextStepButton.setTitle("Working...", for: .normal)
        
        let startTime = Date()

        let perspectiveCorrection = CIFilter(name: "CIPerspectiveCorrection")!
        let docImage = CIImage(image: originalImage!)!
        
        perspectiveCorrection.setValue(CIVector(cgPoint:rect.topLeft),
                                       forKey: "inputTopLeft")
        perspectiveCorrection.setValue(CIVector(cgPoint:rect.topRight),
                                       forKey: "inputTopRight")
        perspectiveCorrection.setValue(CIVector(cgPoint:rect.bottomRight),
                                       forKey: "inputBottomRight")
        perspectiveCorrection.setValue(CIVector(cgPoint:rect.bottomLeft),
                                       forKey: "inputBottomLeft")
        perspectiveCorrection.setValue(docImage,
                                       forKey: kCIInputImageKey)
        
        let outputImage = perspectiveCorrection.outputImage
        
        let updatedImage = UIImage(ciImage: outputImage!, scale: originalImage!.scale, orientation: originalImage!.imageOrientation)
        
        cropedImage = updatedImage.fixed()
        
        time += Date().timeIntervalSince(startTime)
        
        imageView.image = cropedImage
        nextStepButton.setTitle("Adjust Image", for: .normal)
    }
    
    private func executeOpenCVStep3() {
        infoLabel.text = "Croped Image"
        nextStepButton.setTitle("Working...", for: .normal)
        
        let startTime = Date()
        
        cropedImage = imageView.crop(cropRect, andApplyBW: false)
        
        time += Date().timeIntervalSince(startTime)
        
        imageView.image = cropedImage
        nextStepButton.setTitle("Adjust Image", for: .normal)
    }

    private func executeCIStep4() {
        infoLabel.text = "Tuned contrast, brightness and saturation"
        nextStepButton.setTitle("Working...", for: .normal)
        
        let startTime = Date()

        let ciImage = CIImage(cgImage: cropedImage.cgImage!)
        
        let bwImage = CIFilter(name: "CIColorControls", withInputParameters: [
            kCIInputImageKey: ciImage,
            kCIInputBrightnessKey: NSNumber(value: 0.0),
            kCIInputSaturationKey: NSNumber(value: 0.0),
            kCIInputContrastKey:   NSNumber(value: 1.14)]
            )?.outputImage
        
        let updatedImage = UIImage(ciImage: bwImage!, scale: originalImage!.scale, orientation: originalImage!.imageOrientation)
        
        finalImage = updatedImage.fixed()
        
        time += Date().timeIntervalSince(startTime)

        self.imageView.image = finalImage
        
        infoLabel.text = "CI total time: " + String(format: "%.2f", time) + " sec"
        
        UIView.animate(withDuration: 0.3, delay: 0.0, usingSpringWithDamping: 1.0, initialSpringVelocity: 0.0, options: .curveEaseInOut, animations: {
            
            self.nextStepButton.setTitle("Start Over", for: .normal)
            
        }, completion: { (finished) in
            
        })
    }

    private func executeOpenCVStep4() {
        infoLabel.text = "Tuned contrast, brightness and saturation"
        nextStepButton.setTitle("Working...", for: .normal)
        
        let startTime = Date()
        
        finalImage = cropedImage.blackAndWhite()
        
        time += Date().timeIntervalSince(startTime)
        
        self.imageView.image = finalImage
        
        infoLabel.text = "OpenCV total time: " + String(format: "%.2f", time) + " sec"
        
        UIView.animate(withDuration: 0.3, delay: 0.0, usingSpringWithDamping: 1.0, initialSpringVelocity: 0.0, options: .curveEaseInOut, animations: {
            
            self.nextStepButton.setTitle("Start Over", for: .normal)
            
        }, completion: { (finished) in
            
        })
    }
}

extension UIImage {
    func fixed() -> UIImage {
        let ciContext = CIContext(options: nil)
        
        let cgImg = ciContext.createCGImage(ciImage!, from: ciImage!.extent)
        let image = UIImage(cgImage: cgImg!, scale: scale, orientation: .left)

        return image
    }
}
