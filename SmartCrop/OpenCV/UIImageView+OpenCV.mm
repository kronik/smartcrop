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

#import "UIImageView+OpenCV.h"
#import "UIImage+OpenCV.h"
#import "UIImage+OpenCVBW.h"
#import "UIImage+Rotate.h"
#import "UIImageView+ContentFrame.h"
#import "CropView.h"

@implementation UIImageView (OpenCV)

- (CropRect)detectEdges {
    cv::Mat original = self.image.CVMat;
    CGSize targetSize = self.contentSize;
    cv::resize(original, original, cvSize(targetSize.width, targetSize.height));
    
    std::vector<std::vector<cv::Point>>squares;
    std::vector<cv::Point> largest_square;
    
    CropRect rect;
    
    rect.topLeft = CGPointMake(0, 0);
    rect.topRight = CGPointMake(self.frame.size.width, 0);
    rect.bottomLeft = CGPointMake(0, self.frame.size.height);
    rect.bottomRight = CGPointMake(self.frame.size.width, self.frame.size.height);
    
    find_squares(original, squares);
    find_largest_square(squares, largest_square);
    
    if (largest_square.size() == 4) {
        // Manually sorting points, needs major improvement. Sorry.
        
        NSMutableArray *points = [NSMutableArray array];
        NSMutableDictionary *sortedPoints = [NSMutableDictionary dictionary];
        
        for (int i = 0; i < 4; i++) {
            NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:[NSValue valueWithCGPoint:CGPointMake(largest_square[i].x, largest_square[i].y)], @"point" , [NSNumber numberWithInt:(largest_square[i].x + largest_square[i].y)], @"value", nil];
            [points addObject:dict];
        }
        
        int min = [[points valueForKeyPath:@"@min.value"] intValue];
        int max = [[points valueForKeyPath:@"@max.value"] intValue];
        
        int minIndex = 0;
        int maxIndex = 0;
        
        int missingIndexOne = 0;
        int missingIndexTwo = 0;
        
        for (int i = 0; i < 4; i++) {
            NSDictionary *dict = [points objectAtIndex:i];
            
            if ([[dict objectForKey:@"value"] intValue] == min) {
                [sortedPoints setObject:[dict objectForKey:@"point"] forKey:@"0"];
                minIndex = i;
                continue;
            }
            
            if ([[dict objectForKey:@"value"] intValue] == max) {
                [sortedPoints setObject:[dict objectForKey:@"point"] forKey:@"2"];
                maxIndex = i;
                continue;
            }
            
            missingIndexOne = i;
        }
        
        for (int i = 0; i < 4; i++) {
            if (missingIndexOne != i && minIndex != i && maxIndex != i) {
                missingIndexTwo = i;
            }
        }
        
        if (largest_square[missingIndexOne].x < largest_square[missingIndexTwo].x) {
            //2nd Point Found
            [sortedPoints setObject:[[points objectAtIndex:missingIndexOne] objectForKey:@"point"] forKey:@"3"];
            [sortedPoints setObject:[[points objectAtIndex:missingIndexTwo] objectForKey:@"point"] forKey:@"1"];
        } else {
            //4rd Point Found
            [sortedPoints setObject:[[points objectAtIndex:missingIndexOne] objectForKey:@"point"] forKey:@"1"];
            [sortedPoints setObject:[[points objectAtIndex:missingIndexTwo] objectForKey:@"point"] forKey:@"3"];
        }
        
        rect.topLeft = [(NSValue *)[sortedPoints objectForKey:@"0"] CGPointValue];
        rect.topRight = [(NSValue *)[sortedPoints objectForKey:@"1"] CGPointValue];
        rect.bottomLeft = [(NSValue *)[sortedPoints objectForKey:@"3"] CGPointValue];
        rect.bottomRight = [(NSValue *)[sortedPoints objectForKey:@"2"] CGPointValue];
    }
    
    original.release();
    
    return rect;
}

void find_squares(cv::Mat& image, std::vector<std::vector<cv::Point>>&squares) {
    
    // blur will enhance edge detection
    
    cv::Mat blurred(image);
    GaussianBlur(image, blurred, cvSize(11,11), 0);//change from median blur to gaussian for more accuracy of square detection
    
    cv::Mat gray0(blurred.size(), CV_8U), gray;
    std::vector<std::vector<cv::Point> > contours;
    
    // find squares in every color plane of the image
    for (int c = 0; c < 3; c++) {
        int ch[] = {c, 0};
        mixChannels(&blurred, 1, &gray0, 1, ch, 1);
        
        // try several threshold levels
        const int threshold_level = 2;
        for (int l = 0; l < threshold_level; l++) {
            // Use Canny instead of zero threshold level!
            // Canny helps to catch squares with gradient shading
            if (l == 0) {
                Canny(gray0, gray, 10, 20, 3); //
                //                Canny(gray0, gray, 0, 50, 5);
                
                // Dilate helps to remove potential holes between edge segments
                dilate(gray, gray, cv::Mat(), cv::Point(-1,-1));
            } else {
                gray = gray0 >= (l+1) * 255 / threshold_level;
            }
            
            // Find contours and store them in a list
            findContours(gray, contours, CV_RETR_LIST, CV_CHAIN_APPROX_SIMPLE);
            
            // Test contours
            std::vector<cv::Point> approx;
            for (size_t i = 0; i < contours.size(); i++) {
                // approximate contour with accuracy proportional
                // to the contour perimeter
                approxPolyDP(cv::Mat(contours[i]), approx, arcLength(cv::Mat(contours[i]), true)*0.02, true);
                
                // Note: absolute value of an area is used because
                // area may be positive or negative - in accordance with the
                // contour orientation
                if (approx.size() == 4 &&
                    fabs(contourArea(cv::Mat(approx))) > 1000 &&
                    isContourConvex(cv::Mat(approx))) {
                    double maxCosine = 0;
                    
                    for (int j = 2; j < 5; j++) {
                        double cosine = fabs(angle(approx[j%4], approx[j-2], approx[j-1]));
                        maxCosine = MAX(maxCosine, cosine);
                    }
                    
                    if (maxCosine < 0.3) {
                        squares.push_back(approx);
                    }
                }
            }
        }
    }
}

void find_largest_square(const std::vector<std::vector<cv::Point> >& squares, std::vector<cv::Point>& biggest_square) {
    if (!squares.size()) {
        // no squares detected
        return;
    }
    
    int max_width = 0;
    int max_height = 0;
    int max_square_idx = 0;
    
    for (size_t i = 0; i < squares.size(); i++) {
        // Convert a set of 4 unordered Points into a meaningful cv::Rect structure.
        cv::Rect rectangle = boundingRect(cv::Mat(squares[i]));
        
        //        cout << "find_largest_square: #" << i << " rectangle x:" << rectangle.x << " y:" << rectangle.y << " " << rectangle.width << "x" << rectangle.height << endl;
        
        // Store the index position of the biggest square found
        if ((rectangle.width >= max_width) && (rectangle.height >= max_height)) {
            max_width = rectangle.width;
            max_height = rectangle.height;
            max_square_idx = i;
        }
    }
    
    biggest_square = squares[max_square_idx];
}

double angle( cv::Point pt1, cv::Point pt2, cv::Point pt0 ) {
    double dx1 = pt1.x - pt0.x;
    double dy1 = pt1.y - pt0.y;
    double dx2 = pt2.x - pt0.x;
    double dy2 = pt2.y - pt0.y;
    return (dx1*dx2 + dy1*dy2)/sqrt((dx1*dx1 + dy1*dy1)*(dx2*dx2 + dy2*dy2) + 1e-10);
}

- (CGPoint)coordinatesForPoint: (CGPoint)point withScaleFactor: (CGFloat)scaleFactor {
    return CGPointMake((point.x) / scaleFactor, (point.y) / scaleFactor);
}

- (void)showCrop: (CropRect)cropRect {
    for (UIView *subview in self.subviews) {
        [subview removeFromSuperview];
    }
    
    CropView *cropView = [[CropView alloc] initWithFrame:self.bounds];
    
    cropView.backgroundColor = [UIColor clearColor];
    cropView.clipsToBounds = NO;
    cropView.contentMode = UIViewContentModeRedraw;
    
    [cropView showCrop:cropRect];
    
    [self addSubview:cropView];
}

- (UIImage *)crop: (CropRect)cropRect andApplyBW:(BOOL)applyBW {
    CGFloat scaleFactor =  [self contentScale];
    CGPoint ptBottomLeft = [self coordinatesForPoint:cropRect.bottomLeft withScaleFactor:scaleFactor];
    CGPoint ptBottomRight = [self coordinatesForPoint:cropRect.bottomRight withScaleFactor:scaleFactor];
    CGPoint ptTopRight = [self coordinatesForPoint:cropRect.topRight withScaleFactor:scaleFactor];
    CGPoint ptTopLeft = [self coordinatesForPoint:cropRect.topLeft withScaleFactor:scaleFactor];
    
    CGFloat w1 = sqrt( pow(ptBottomRight.x - ptBottomLeft.x , 2) + pow(ptBottomRight.x - ptBottomLeft.x, 2));
    CGFloat w2 = sqrt( pow(ptTopRight.x - ptTopLeft.x , 2) + pow(ptTopRight.x - ptTopLeft.x, 2));
    
    CGFloat h1 = sqrt( pow(ptTopRight.y - ptBottomRight.y , 2) + pow(ptTopRight.y - ptBottomRight.y, 2));
    CGFloat h2 = sqrt( pow(ptTopLeft.y - ptBottomLeft.y , 2) + pow(ptTopLeft.y - ptBottomLeft.y, 2));
    
    CGFloat maxWidth = (w1 < w2) ? w1 : w2;
    CGFloat maxHeight = (h1 < h2) ? h1 : h2;
    
    cv::Point2f src[4], dst[4];
    src[0].x = ptTopLeft.x;
    src[0].y = ptTopLeft.y;
    src[1].x = ptTopRight.x;
    src[1].y = ptTopRight.y;
    src[2].x = ptBottomRight.x;
    src[2].y = ptBottomRight.y;
    src[3].x = ptBottomLeft.x;
    src[3].y = ptBottomLeft.y;
    
    dst[0].x = 0;
    dst[0].y = 0;
    dst[1].x = maxWidth - 1;
    dst[1].y = 0;
    dst[2].x = maxWidth - 1;
    dst[2].y = maxHeight - 1;
    dst[3].x = 0;
    dst[3].y = maxHeight - 1;
    
    cv::Mat undistorted = cv::Mat( cvSize(maxWidth,maxHeight), CV_8UC4);
    cv::Mat original = self.image.CVMat;
    
    cv::warpPerspective(original, undistorted, cv::getPerspectiveTransform(src, dst), cvSize(maxWidth, maxHeight));
    
    UIImage *processedImage = [UIImage imageWithCVMat:undistorted];
    
    if (applyBW) {
        processedImage = [processedImage blackAndWhite];
    }
    
    for (UIView *subview in self.subviews) {
        [subview removeFromSuperview];
    }
    
    self.image = processedImage;
    
    return processedImage;
}

@end
