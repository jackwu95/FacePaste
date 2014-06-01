//
//  FaceDetector.m
//  FaceSwap
//
//  Created by Jack Wu on 2014-05-31.
//  Copyright (c) 2014 Jack Wu. All rights reserved.
//

#import "FaceDetector.h"

@interface FaceDetector ()

@property (strong, nonatomic) dispatch_queue_t detectQueue;
@property (strong, nonatomic) CIDetector * detector;

@end

@implementation FaceDetector

+ (instancetype)sharedDetector {
    static id instance = NULL;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

- (void)detectFacesInImage:(UIImage *)anImage {
    if (!_detectQueue) {
        _detectQueue = dispatch_queue_create("detectQueue", DISPATCH_QUEUE_SERIAL);
    }
    if (!_detector) {
        NSDictionary * options = @{CIDetectorAccuracy:CIDetectorAccuracyHigh,
                                   CIDetectorTracking:@NO};
        _detector = [CIDetector detectorOfType:CIDetectorTypeFace context:nil options:options];
    }
    
    dispatch_async(_detectQueue, ^{
        CIImage * image = [[CIImage alloc] initWithImage:anImage];
        NSArray * features = [_detector featuresInImage:image];
        
        CGAffineTransform featureTransform = CGAffineTransformMakeScale(1, -1);
        featureTransform = CGAffineTransformTranslate(featureTransform, 0, -anImage.size.height);
        
        NSMutableArray * faces = [@[] mutableCopy];
        for (CIFaceFeature * ff in features) {
            Face * face = [[Face alloc] init];
            face.bounds = CGRectApplyAffineTransform(ff.bounds, featureTransform);
            face.image = nil;
            [faces addObject:face];
        }
        
        _detectedFaces = [NSArray arrayWithArray:faces];
        
        if ([_delegate respondsToSelector:@selector(faceDetectorFinishedDetectingFaces:)]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [_delegate faceDetectorFinishedDetectingFaces:_detectedFaces];
            });
        }
    });
    
}
@end
