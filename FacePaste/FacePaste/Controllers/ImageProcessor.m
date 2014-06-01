//
//  ImageProcessor.m
//  FaceSwap
//
//  Created by Jack Wu on 2014-05-31.
//  Copyright (c) 2014 Jack Wu. All rights reserved.
//

#import <CoreImage/CoreImage.h>
#import "ImageProcessor.h"
#import "Face.h"
#import "UIImage+Convenience.h"

@interface ImageProcessor ()

@property (strong, nonatomic) CIFilter * scaleFilter;
@property (strong, nonatomic) CIFilter * sourceOverFilter;
@property (strong, nonatomic) CIFilter * radialGradient;
@property (strong, nonatomic) CIFilter * multiplyFilter;
@property (strong, nonatomic) dispatch_queue_t processQueue;


@end

@implementation ImageProcessor

+ (instancetype)sharedProcessor {
    static id instance = NULL;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

- (void)replaceFaces:(NSArray *)faces inImage:(UIImage *)image withFace:(Face *)face {
    
    if (!_processQueue) {
        _processQueue = dispatch_queue_create("processingQueue", DISPATCH_QUEUE_SERIAL);
    }
    
    dispatch_async(_processQueue, ^{
        if (!face.image) {
            face.image = [image croppedImage:face.bounds];
        }
        
        
        CIImage * faceImage = [[CIImage alloc] initWithImage:face.image];
        CGAffineTransform faceTransform = CGAffineTransformMakeScale(1, -1);
        faceTransform = CGAffineTransformTranslate(faceTransform, 0, -face.image.size.height);
        
        CGRect rectForCoreImage = CGRectApplyAffineTransform((CGRect){CGPointZero,face.bounds.size}, faceTransform);
        CGFloat innerRadius = CGRectGetWidth(rectForCoreImage) * 0.75 * 0.5;
        CGFloat outerRadius = CGRectGetWidth(rectForCoreImage) * 1 * 0.5;
        
        CIVector * center = [CIVector vectorWithX:CGRectGetMidX(rectForCoreImage) Y:CGRectGetMidY(rectForCoreImage)];
        [self.radialGradient setValue:center forKeyPath:kCIInputCenterKey];
        [self.radialGradient setValue:@(innerRadius) forKeyPath:@"inputRadius0"];
        [self.radialGradient setValue:@(outerRadius) forKeyPath:@"inputRadius1"];
        [self.radialGradient setValue:[CIColor colorWithCGColor:[UIColor whiteColor].CGColor] forKeyPath:@"inputColor0"];
        [self.radialGradient setValue:[CIColor colorWithCGColor:[UIColor clearColor].CGColor] forKeyPath:@"inputColor1"];

        CIImage * circle = [self.radialGradient valueForKey:kCIOutputImageKey];
        
        CIFilter * blendFilter = [CIFilter filterWithName:@"CIMultiplyCompositing"];
        [blendFilter setDefaults];
        [blendFilter setValue:faceImage forKeyPath:kCIInputImageKey];
        [blendFilter setValue:circle forKeyPath:kCIInputBackgroundImageKey];
        
        CIImage * faceToBlend = [blendFilter valueForKey:kCIOutputImageKey];

        CIImage * processingImage = [[CIImage alloc] initWithImage:image];

//        CIImage * test;
        for (Face * f in faces) {
            if (CGRectEqualToRect(f.bounds, face.bounds)) {
                continue;
            }
            CGAffineTransform transform = CGAffineTransformMakeScale(1, -1);
            transform = CGAffineTransformTranslate(transform, 0, -image.size.height);
            CGRect destination = CGRectApplyAffineTransform(f.bounds, transform);
            
            // Scale the face to the destination size
            [self.scaleFilter setValue:faceToBlend forKeyPath:kCIInputImageKey];
            [self.scaleFilter setValue:@(destination.size.width / face.bounds.size.width) forKeyPath:kCIInputScaleKey];
            
            CIImage * scaledFace = [self.scaleFilter valueForKey:kCIOutputImageKey];
            CIImage * scaledAndTranslatedFace = [scaledFace imageByApplyingTransform:CGAffineTransformMakeTranslation(destination.origin.x, destination.origin.y)];
            [self.sourceOverFilter setValue:processingImage forKey:kCIInputBackgroundImageKey];
            [self.sourceOverFilter setValue:scaledAndTranslatedFace forKeyPath:kCIInputImageKey];
            
//            test = scaledAndTranslatedFace;
            processingImage = [self.sourceOverFilter valueForKey:kCIOutputImageKey];
//            break;
        }
        
        UIImage * finalImage = [UIImage imageWithCIImage:processingImage];
        
        if ([self.delegate respondsToSelector:@selector(imageProcessorProcessedImage:)]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.delegate imageProcessorProcessedImage:finalImage];
            });
        }
    });
    
    
    
}

- (CIFilter *)multiplyFilter {
    if (!_multiplyFilter) {
        _multiplyFilter = [CIFilter filterWithName:@"CIMultiplyCompositing"];
        [_multiplyFilter setDefaults];
    }
    return _multiplyFilter;
}

- (CIFilter *)sourceOverFilter {
    if (!_sourceOverFilter) {
        _sourceOverFilter = [CIFilter filterWithName:@"CISourceOverCompositing"];
        [_sourceOverFilter setDefaults];
    }
    return _sourceOverFilter;
}

- (CIFilter *)radialGradient {
    if (!_radialGradient) {
        _radialGradient = [CIFilter filterWithName:@"CIRadialGradient"];
        [_radialGradient setDefaults];
    }
    return _radialGradient;
}

- (CIFilter *)scaleFilter {
    if (!_scaleFilter) {
        _scaleFilter = [CIFilter filterWithName:@"CILanczosScaleTransform"];
        [_scaleFilter setDefaults];
    }
    return _scaleFilter;
}
@end
