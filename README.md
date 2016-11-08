
#Small improvement - Big impact

###Real life story
In [CXA](http://www.cxagroup.com) (as a broker company) we process huge amount of documents every single day. Recently we decided to shift more in paperless document processing. Less paperwork - faster claim turnaround - happier customers. And we started to encourage clients to upload right documents by explaining them what the right document is and how to scan documents in a way they could be used without requesting original hard copies. I thought _“what else could I do to improve this entire process and eliminate user errors?”_. Very often clients send us document photos taken on their smartphone. 

<img src="https://raw.githubusercontent.com/kronik/smartcrop/master/Images/claims-incorrect.png" width="30%"/>￼

 And this is how idea of __image perspective correction__ was born. 

Image perspective correction is a warp transformation which basically changes “point of view” to the object:

<img src="https://raw.githubusercontent.com/kronik/smartcrop/master/Images/perspective.png" width="50%"/>
￼

There is a good post on [FlexMonkey website](https://realm.io/news/tryswift-gladman-simon-advanced-core-image/) about “Perspective Transform & Correction with Core Image”. 

In their [tutorial](https://realm.io/news/tryswift-gladman-simon-advanced-core-image/) you basically have two images (background and source) and to place source image on background you need to:

1. Detect area (edges) on background image 
2. Figure out image transformation from step 1
3. Apply this transformation to the source image
4. Combine background and transformed source image 

To solve our problem I still need to detect edges but after that I need to crop detected area:

1. Detect area (edges) on background image 
2. Figure out image transformation from step 1
3. Apply this transformation and crop to background image

Sounds not so terrible 🤓

Let’s code this! 

```swift
let originalImage = UIImage(named: "doc")
let docImage = CIImage(image: originalImage!)!
var rect: CIRectangleFeature = CIRectangleFeature()

// First step: Detect edges on our photo: 
if let detector = CIDetector(ofType: CIDetectorTypeRectangle,
							 context: ciContext,
							 options: [CIDetectorAccuracy: CIDetectorAccuracyHigh]) {
	
	rect = detector.features(in: docImage).first as! CIRectangleFeature
}

// Second step: Prepare transformation:
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
        
// Third step: Apply transformation
let outputImage = perspectiveCorrection.outputImage

// Optional forth step: Adjust contrast, brightness and saturation for better image recognition:
let finalImage = CIFilter(name: "CIColorControls", withInputParameters: [
		kCIInputImageKey: outputImage,
		kCIInputBrightnessKey: NSNumber(value: 0.0),
		kCIInputSaturationKey: NSNumber(value: 0.0),
		kCIInputContrastKey:   NSNumber(value: 1.14)]
	)?.outputImage
```
Here is how it works:

<img src="https://raw.githubusercontent.com/kronik/smartcrop/master/Images/CI-step1.png" width="22%"/> <img src="https://raw.githubusercontent.com/kronik/smartcrop/master/Images/CI-step2.png" width="22%"/> <img src="https://raw.githubusercontent.com/kronik/smartcrop/master/Images/CI-step3.png" width="22%"/> <img src="https://raw.githubusercontent.com/kronik/smartcrop/master/Images/CI-step4.png" width="22%"/>
￼

Now I have grayscale final image fully ready for recognition! 😎🙌 

Some more coding and I’m testing this code on different images right from camera. And __BOOM!__

<img src="https://raw.githubusercontent.com/kronik/smartcrop/master/Images/Error.png" width="30%"/>

 I see that edge detection doesn’t work really well on real life sample photos 😱🤔 

Ok... some googling shows that quite popular image processing library - [OpenCV](http://opencv.org) might produce much better results. [Robin posted](https://medium.com/ios-os-x-development/the-fd4fcb249358#.ghmlq9ts3)  very descriptive article on how to run this cross-platform library on iOS. The main problem is that [OpenCV](http://opencv.org)  is implemented on C/C++ and Swift can’t directly work with C++ code. So it requires to implement wrapper layer for OpenCV. There are already [bunch of samples](https://github.com/foundry/OpenCVSwiftStitch) on how to do this properly. Ok, let’s just implement our algorithm now on OpenCV. I’ve implemented interaction with OpenCV library mostly as a UIImageView and UIImage categories:

```Objective-C
#import <UIKit/UIKit.h>

typedef struct CropRect {
    CGPoint topLeft;
    CGPoint topRight;
    CGPoint bottomLeft;
    CGPoint bottomRight;
} CropRect;

@interface UIImageView (OpenCV)

- (CropRect)detectEdges;
- (UIImage *)crop: (CropRect)cropRect andApplyBW:(BOOL)applyBW;
- (void)showCrop: (CropRect)cropRect;

@end

@interface UIImage (OpenCV)

//cv::Mat to UIImage
+ (UIImage *)imageWithCVMat:(const cv::Mat&)cvMat;
- (id)initWithCVMat:(const cv::Mat&)cvMat;

 //UIImage to cv::Mat
- (cv::Mat)CVMat;
- (cv::Mat)CVMat3;  // no alpha channel
- (cv::Mat)CVGrayscaleMat;

@end
```

Full source code is available on [github](https://github.com/kronik/smartcrop.git)

Here is how last implementation works with OpenCV:

<img src="https://raw.githubusercontent.com/kronik/smartcrop/master/Images/OpenCV-step1.png" width="22%"/> <img src="https://raw.githubusercontent.com/kronik/smartcrop/master/Images/OpenCV-step2.png" width="22%"/> <img src="https://raw.githubusercontent.com/kronik/smartcrop/master/Images/OpenCV-step3.png" width="22%"/> <img src="https://raw.githubusercontent.com/kronik/smartcrop/master/Images/OpenCV-step4.png" width="22%"/>

Surprisingly now even in some edge-cases document detection works really well! 🎉

###Conclusion:
Very often first implementation doesn’t show great results. Like in my case modern CoreImage filters seem very easy to pickup and make it work in just matter of minutes but came up with some disappointing results. In same time old image processing library does the thing. And couple of hours of wiring this C++ library with Swift application definitely worth it. 

_Try again and again, be curious, be insistent!_

What we’ve got? Now CXA application has extremely reliable way of taking well-prepared document photos which are:

1. easy to read
2. ready for further data processing (like OCR)
3. lighter, so app consumes less internet traffic  

__And finally__: better documents quality causes shorter claims turnaround - more happier customers!