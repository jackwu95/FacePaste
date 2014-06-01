//
//  FaceDetector.h
//  FaceSwap
//
//  Created by Jack Wu on 2014-05-31.
//  Copyright (c) 2014 Jack Wu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Face.h"

@protocol FaceDetectorDelegate <NSObject>

- (void)faceDetectorFinishedDetectingFaces:(NSArray*)faces;

@end

@interface FaceDetector : NSObject

+ (instancetype)sharedDetector;

@property (weak, nonatomic) id<FaceDetectorDelegate> delegate;
@property (strong, nonatomic) NSArray * detectedFaces;

- (void)detectFacesInImage:(UIImage *)anImage;
@end
