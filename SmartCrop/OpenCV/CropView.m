#import "CropView.h"

@interface CropView ()

@property (nonatomic) CropRect lastCropRect;

@end

@implementation CropView

-(void)showCrop:(CropRect)rect {
    _lastCropRect = rect;
    
    [self setNeedsDisplay];
    [self drawRect:self.bounds];
}

- (void)drawRect:(CGRect)rect;
{
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    if (context) {
        CGContextSetRGBFillColor(context, 0.0f, 0.0f, 0.0f, 1.0f);
        
        CGContextSetRGBStrokeColor(context, 0.1294f, 0.588f, 0.9529f, 1.0f);
        
        CGContextSetLineJoin(context, kCGLineJoinRound);
        CGContextSetLineWidth(context, 4.0f);
        
        CGRect boundingRect = CGContextGetClipBoundingBox(context);
        CGContextAddRect(context, boundingRect);
        CGContextFillRect(context, boundingRect);
        
        CGMutablePathRef pathRef = CGPathCreateMutable();
        
        CGPathMoveToPoint(pathRef, NULL, _lastCropRect.bottomLeft.x, _lastCropRect.bottomLeft.y);
        CGPathAddLineToPoint(pathRef, NULL, _lastCropRect.bottomRight.x, _lastCropRect.bottomRight.y);
        CGPathAddLineToPoint(pathRef, NULL, _lastCropRect.topRight.x, _lastCropRect.topRight.y);
        CGPathAddLineToPoint(pathRef, NULL, _lastCropRect.topLeft.x, _lastCropRect.topLeft.y);

        CGPathCloseSubpath(pathRef);
        CGContextAddPath(context, pathRef);
        CGContextStrokePath(context);
        
        CGContextSetBlendMode(context, kCGBlendModeClear);
        
        CGContextAddPath(context, pathRef);
        
        CGContextSetRGBFillColor(context, 0.0f, 0.0f, 1.0f, 0.5f);
        CGContextFillPath(context);
        
        CGContextSetBlendMode(context, kCGBlendModeNormal);
        
        CGPathRelease(pathRef);
    }
}

@end
