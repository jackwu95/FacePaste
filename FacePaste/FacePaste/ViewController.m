//
//  ViewController.m
//  FaceSwap
//
//  Created by Jack Wu on 2014-05-30.
//  Copyright (c) 2014 Jack Wu. All rights reserved.
//

#import "ViewController.h"
#import "UIImage+Convenience.h"
#import "MBProgressHUD.h"
#import "FaceDetector.h"
#import "ImageProcessor.h"
#import "JWImageScrollView.h"
#import "FilterViewController.h"

@interface ViewController () <UINavigationControllerDelegate, UIImagePickerControllerDelegate, FaceDetectorDelegate, ImageProcessorDelegate>

@property (weak, nonatomic) IBOutlet JWImageScrollView * scrollView;
@property (strong, nonatomic) UIImageView  *mainImageView;

@property (strong, nonatomic) UIImagePickerController * imagePickerController;
@property (strong, nonatomic) UIImage * workingImage;

@property (strong, nonatomic) NSArray * faceButtons;

@end

@implementation ViewController

#pragma mark - Lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    UIViewController * destinationVC = [segue destinationViewController];
    if ([destinationVC isKindOfClass:[FilterViewController class]]) {
        
        UIImage * image = _mainImageView.image;
        if (!image.CGImage) {
            // CIImage backed, need to create a CGImage
            CIContext * context = [CIContext contextWithOptions:nil];
            CGImageRef cgImage = [context createCGImage:image.CIImage fromRect:[image.CIImage extent]];
            image = [UIImage imageWithCGImage:cgImage];
        }
        else {
            image = _mainImageView.image;
        }
        
        ((FilterViewController *)destinationVC).workingImage = image;
    }
}

#pragma mark - Custom Accessors

- (UIImagePickerController *)imagePickerController {
    if (!_imagePickerController) { /* Lazy Loading */
        _imagePickerController = [[UIImagePickerController alloc] init];
        _imagePickerController.allowsEditing = NO;
        _imagePickerController.delegate = self;
    }
    return _imagePickerController;
}

#pragma mark - IBActions

- (IBAction)takePhotoFromCamera:(UIBarButtonItem *)sender {
    self.imagePickerController.sourceType = UIImagePickerControllerSourceTypeCamera;
    [self presentViewController:self.imagePickerController animated:YES completion:nil];
}

- (IBAction)takePhotoFromAlbum:(UIBarButtonItem *)sender {
    self.imagePickerController.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    [self presentViewController:self.imagePickerController animated:YES completion:nil];
}

- (IBAction)modify:(UIBarButtonItem *)sender {
    // Hide/Show the face circles
    if (sender.tag == 1) {
        sender.tag = 0;
        for (UIView * v in self.faceButtons) {
            v.hidden = NO;
        }
    }
    else {
        sender.tag = 1;
        for (UIView * v in self.faceButtons) {
            v.hidden = YES;
        }
    }
}

- (void)faceSelected:(UIButton *)sender {
    
    NSLog(@"Face Selected:%d",(int)sender.tag);
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    
    // Process the image with the selected face
    [ImageProcessor sharedProcessor].delegate = self;
    [[ImageProcessor sharedProcessor] replaceFaces:[FaceDetector sharedDetector].detectedFaces inImage:_workingImage withFace:[FaceDetector sharedDetector].detectedFaces[sender.tag]];
}

#pragma mark - Private

- (void)setupWithImage:(UIImage*)image {
    UIImage * fixedImage;
    
    // Cap the image to 1000 * 1000 pixels maximum
    if (image.size.width * image.size.height > 1000 * 1000) {
        // This fixes orientation for us too!
        fixedImage = [image resizedImageWithContentMode:UIViewContentModeScaleAspectFit bounds:CGSizeMake(1000,1000) interpolationQuality:kCGInterpolationHigh];
    }
    else {
        // Fix orientation
        fixedImage = [image imageWithFixedOrientation];
    }
    _workingImage = fixedImage;
    
    for (UIButton * button in _faceButtons) {
        [button removeFromSuperview];
    }
    _faceButtons = nil;

    // Reset the scroll view and the image view
    [_scrollView resetContainerView];
    _mainImageView = [[UIImageView alloc] initWithImage:_workingImage];
    _mainImageView.backgroundColor = [UIColor blueColor];
    [_scrollView.subviewContainer addSubview:_mainImageView];
    _scrollView.subviewContainer.frame = _mainImageView.bounds;
    [_scrollView zoomOutToFitScreen:NO];
    
    // Start face detection
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    [FaceDetector sharedDetector].delegate = self;
    [[FaceDetector sharedDetector] detectFacesInImage:(_workingImage)];
}

#pragma mark - Protocol Conformance

#pragma mark FaceDetectorDelegate

- (void)faceDetectorFinishedDetectingFaces:(NSArray*)faces {
    [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
    if (faces.count < 2) {
        UIAlertView * alert = [[UIAlertView alloc] initWithTitle:@"Not enough faces!" message:@"We need at least 2 faces to do the magic." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
        return;
    }
    
    // Create a button for each face
    NSMutableArray * buttons = [@[] mutableCopy];
    for (NSInteger i = 0; i < faces.count; i++ ) {
        UIButton * button = [UIButton buttonWithType:UIButtonTypeCustom];
        button.tag = i;
        button.backgroundColor = [UIColor clearColor];
        
        Face * face = faces[i];
        button.frame = face.bounds;
        button.layer.borderWidth = 3;
        button.layer.borderColor = [UIColor whiteColor].CGColor;
        button.layer.cornerRadius = button.bounds.size.width/2;
        [button addTarget:self action:@selector(faceSelected:) forControlEvents:UIControlEventTouchUpInside];
        [_scrollView.subviewContainer addSubview:button];
        
        [buttons addObject:button];
    }
    _faceButtons = [NSArray arrayWithArray:buttons];
}

#pragma mark ImageProcessorDelegate

- (void)imageProcessorProcessedImage:(UIImage *)outputImage {
    [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
//    _workingImage = outputImage;
    self.mainImageView.image = outputImage;
}

#pragma mark UIImagePickerDelegate

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [[picker presentingViewController] dismissViewControllerAnimated:YES completion:nil];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    // Dismiss the imagepicker
    [[picker presentingViewController] dismissViewControllerAnimated:YES completion:nil];
    [self setupWithImage:info[UIImagePickerControllerOriginalImage]];
}


@end
