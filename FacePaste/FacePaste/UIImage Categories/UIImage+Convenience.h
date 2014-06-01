//
//  UIImage+Convenience.h
//  FaceSwap
//
//  Created by Jack Wu on 2014-05-31.
//  Copyright (c) 2014 Jack Wu. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UIImage+Resize.h"

@interface UIImage (Convenience)

- (UIImage *)imageWithFixedOrientation;

- (UIImage *)cropToRect:(CGRect)rect;

@end
