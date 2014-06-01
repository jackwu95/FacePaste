//
//  ImageProcessor.h
//  FaceSwap
//
//  Created by Jack Wu on 2014-05-31.
//  Copyright (c) 2014 Jack Wu. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol ImageProcessorDelegate <NSObject>

- (void)imageProcessorProcessedImage:(UIImage*)result;

@end

@class Face;
@interface ImageProcessor : NSObject

+ (instancetype)sharedProcessor;

@property (weak, nonatomic) id<ImageProcessorDelegate> delegate;

- (void)replaceFaces:(NSArray *)faces inImage:(UIImage *)image withFace:(Face *)face;

@end
