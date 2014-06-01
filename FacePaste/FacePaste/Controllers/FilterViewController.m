//
//  FilterViewController.m
//  FacePaste
//
//  Created by Jack Wu on 2014-05-31.
//  Copyright (c) 2014 Jack Wu. All rights reserved.
//

#import "FilterViewController.h"
#import "FilterCell.h"
#import "GPUImage.h"
#import "UIImage+Resize.h"
@interface FilterViewController () <UICollectionViewDelegate, UICollectionViewDataSource>

@property (weak, nonatomic) IBOutlet UIImageView * outputImageView;
@property (weak, nonatomic) IBOutlet UICollectionView * filterPickerCollectionView;

@property (strong, nonatomic) GPUImagePicture * workingPicture;
@property (strong, nonatomic) GPUImagePicture * workingThumbnail;

@property (strong, nonatomic) NSArray * filters;
@property (strong, nonatomic) GPUImageOutput<GPUImageInput> * currentSelectedFilter;
@end

@implementation FilterViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if (!_workingImage) {
        return;
    }
    [self setupGPUFilters];
    [self setupGPUPictures];
    [self.filterPickerCollectionView reloadData];
    _outputImageView.image = _workingImage;
}

- (void)viewDidAppear:(BOOL)animated {
    if (!_workingImage) {
        NSLog(@"Didn't set a working image");
        [self.navigationController popViewControllerAnimated:YES];
        return;
    }
}

- (void)setupGPUPictures {
    if (_workingPicture) {
        [_workingPicture removeAllTargets];
        [_workingPicture removeOutputFramebuffer];
        _workingPicture = nil;
    }
    if (_workingThumbnail) {
        [_workingThumbnail removeAllTargets];
        [_workingThumbnail removeOutputFramebuffer];
        _workingThumbnail = nil;
    }
    
    _workingPicture = [[GPUImagePicture alloc] initWithImage:_workingImage];
    
    // Create a thumbnail
    UIImage * thumbnail = [_workingImage thumbnailImage:100 transparentBorder:0 cornerRadius:0 interpolationQuality:kCGInterpolationHigh];
    _workingThumbnail = [[GPUImagePicture alloc] initWithImage:thumbnail];
}

- (void)setupGPUFilters {
    NSMutableArray * filters = [@[] mutableCopy];
    
    GPUImageOutput * filter = [[GPUImageAmatorkaFilter alloc] init];
    [filters addObject:filter];
    
    filter = [[GPUImageMissEtikateFilter alloc] init];
    [filters addObject:filter];

    filter = [[GPUImageSoftEleganceFilter alloc] init];
    [filters addObject:filter];
    
    filter = [[GPUImageColorInvertFilter alloc] init];
    [filters addObject:filter];
    
    filter = [[GPUImageGrayscaleFilter alloc] init];
    [filters addObject:filter];
    
    filter = [[GPUImageEmbossFilter alloc] init];
    [filters addObject:filter];
    
    filter = [[GPUImageHalftoneFilter alloc] init];
    [filters addObject:filter];
    
    filter = [[GPUImageBilateralFilter alloc] init];
    [filters addObject:filter];
    
    filter = [[GPUImagePixellateFilter alloc] init];
    [filters addObject:filter];
    
    filter = [[GPUImageSketchFilter alloc] init];
    [filters addObject:filter];
    
    filter = [[GPUImageToonFilter alloc] init];
    [filters addObject:filter];
    
    _filters = filters;
}

#pragma mark - Actions

- (IBAction)save:(id)sender {
    // Save to Album
    UIImageWriteToSavedPhotosAlbum(_outputImageView.image, nil, nil, nil);
}

#pragma mark - UICollectionView

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    GPUImageOutput<GPUImageInput> * filter = _filters[indexPath.row];
    
    [filter removeAllTargets];
    [_workingPicture removeAllTargets];
    [_workingPicture addTarget:filter];
    
    [filter useNextFrameForImageCapture];
    [_workingPicture processImage];
    
    // Grab the filtered image
    UIImage * image = [filter imageFromCurrentFramebuffer];
    _outputImageView.image = image;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return _filters.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    FilterCell * cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"filterCell" forIndexPath:indexPath];
    
    // Clean up the previous filter
    [_workingThumbnail removeTarget:cell.filter];
    [cell.filter removeAllTargets];
    
    // Set up the new filter
    cell.filter = _filters[indexPath.row];
    [cell.filter removeAllTargets];
    
    [_workingThumbnail addTarget:cell.filter];
    [cell.filter addTarget:cell.imageView];
    
    [_workingThumbnail processImage];
    return cell;
}
 
@end
