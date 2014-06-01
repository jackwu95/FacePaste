//
//  FilterCell.h
//  FacePaste
//
//  Created by Jack Wu on 2014-05-31.
//  Copyright (c) 2014 Jack Wu. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GPUImage.h"
@interface FilterCell : UICollectionViewCell

@property (strong, nonatomic) IBOutlet GPUImageView * imageView;
@property (strong, nonatomic) GPUImageOutput <GPUImageInput> * filter;

@end
