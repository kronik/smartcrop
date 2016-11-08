//
//  UIImage+OpenCV.mm
//  OpenCVClient
//
//  Created by Washe on 01/12/2012.
//  Copyright 2012 Washe / Foundry. All rights reserved.
//
//  Permission is given to use this source code file without charge in any
//  project, commercial or otherwise, entirely at your risk, with the condition
//  that any redistribution (in part or whole) of source code must retain
//  this copyright and permission notice. Attribution in compiled projects is
//  appreciated but not required.
//
//  adapted from
//  http://docs.opencv.org/doc/tutorials/ios/image_manipulation/image_manipulation.html#opencviosimagemanipulation

#import "UIImage+OpenCV.h"
#import "UIImage+OpenCVBW.h"

@implementation UIImage (OpenCVBW)

- (UIImage *)blackAndWhite {
    cv::Mat original = [self CVGrayscaleMat];
    cv::Mat grayMat;
    
    if ( original.channels() == 1 ) {
        grayMat = original;
    }
    else {
        grayMat = cv :: Mat( original.rows, original.cols, CV_8UC1 );
        cv::cvtColor( original, grayMat, CV_BGR2GRAY );
    }

    cv::Mat new_image = cv::Mat::zeros( grayMat.size(), grayMat.type() );
    
    grayMat.convertTo(new_image, -1, 1.4, -50);
    grayMat.release();
    
    UIImage *blackWhiteImage = [UIImage imageWithCVMat: new_image];
    
    new_image.release();
    
    return blackWhiteImage;
}

@end
