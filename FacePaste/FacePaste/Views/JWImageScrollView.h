//
//  JWImageScrollView.h
//
//  Created by Jack Wu on 2014-04-02.
//

#import <UIKit/UIKit.h>

/*
NOTE: If you assign the UIScrollViewDelegate to your own class,
you will need to implement the following method:

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    if (scrollView == MyMAScrollView) {
        return MyMAScrollView.subviewContainer;
    }
    return nil;
}
*/

/**
 MAScrollView is a subclass of UIScrollView that keeps the image in the center when zoomed out.
 */
@interface JWImageScrollView : UIScrollView <UIScrollViewDelegate>

/** 
 Container for subviews
 */
@property (strong, nonatomic) UIView *subviewContainer;

/** 
 Reset the container view
 */
- (void)resetContainerView;

/**
 Enable Shadow. Defaults to `YES`
 */
@property (assign, nonatomic) BOOL shadowsEnabled;

/**
 Enable One Touch Panning. Defaults to `YES`
 */
@property (assign, nonatomic) BOOL  oneFingerPanEnabled;

/**
 Enable Double Tap to Zoom. Defaults to `NO`
 */
@property (assign, nonatomic) BOOL  doubleTapToZoomEnabled;

/**
 Zoom to rect animated with `duration`
 */
- (void)zoomToRect:(CGRect)rect duration:(NSTimeInterval)duration completion:(void (^)(BOOL finished))completion;

/**
 Sets `zoomScale` to `minimumZoomScale` with `duration`
 */
- (void)zoomOutToFitScreenDuration:(NSTimeInterval)duration completion:(void (^)(BOOL finished))completion;

/**
 If animated, animation `duration` is 0.5
 */
- (void)zoomOutToFitScreen:(BOOL)animated;

@end
