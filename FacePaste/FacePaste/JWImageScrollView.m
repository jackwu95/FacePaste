//
//  JWImageScrollView.m
//
//  Created by Jack Wu on 2014-04-02.
//

#import "JWImageScrollView.h"

@interface JWImageScrollView () <UIGestureRecognizerDelegate>

@property (strong, nonatomic) UITapGestureRecognizer * doubleTapGestureRecognizer;

@property (nonatomic) BOOL manualZooming;

@end

@implementation JWImageScrollView

#pragma mark - UIScrollView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setup];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self setup];
    }
    return self;
}

- (void)setup {
    self.delegate = self;
    
    self.scrollsToTop = NO;
    self.showsHorizontalScrollIndicator = NO;
    self.showsVerticalScrollIndicator   = NO;
    self.canCancelContentTouches        = NO;
    self.bounces = YES;
    self.bouncesZoom = YES;
    
    // Find the subview container if only one subview
    // Else create a new one
    if (self.subviews.count == 1) {
        if ([self.subviews[0] isKindOfClass:[UIView class]]) {
            _subviewContainer = self.subviews[0];
        }
    }
    else if (self.subviews.count > 1) {
        NSLog(@"It is not recommended to have more than one direct subview of JWImageScroll");
    }
    
    if (!_subviewContainer) {
        _subviewContainer = [[UIView alloc] init];
        _subviewContainer.userInteractionEnabled = YES;
        [self addSubview:_subviewContainer];
    }
    _subviewContainer.clipsToBounds = YES;
    _subviewContainer.frame = self.bounds;
    [_subviewContainer addObserver:self forKeyPath:@"frame" options:NSKeyValueObservingOptionNew context:NULL];
    
    self.pinchGestureRecognizer.delegate = self;
    
    // Set up default values
    self.shadowsEnabled         = NO;
    self.doubleTapToZoomEnabled = NO;
    self.oneFingerPanEnabled    = YES;
    
    // Internal State Variables
    _manualZooming = NO;
}

- (void)dealloc {
    [_subviewContainer removeObserver:self forKeyPath:@"frame"];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    if (!_manualZooming) {
        [self centerSubviewContainer];
    }
}

#pragma mark - Observer

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"frame"]) {
        CGRect newFrame = [change[@"new"] CGRectValue];
        float scaleToFit = 1.0f / MAX(newFrame.size.width/self.bounds.size.width, newFrame.size.height/self.bounds.size.height);
        float scaleToFill = 1.0f / MIN(newFrame.size.width/self.bounds.size.width, newFrame.size.height/self.bounds.size.height);
        
        self.minimumZoomScale = scaleToFit ;
        self.maximumZoomScale = MAX(scaleToFill*4.0f,scaleToFit*4.0f);
        self.contentSize = newFrame.size;
        if (_shadowsEnabled) {
            CGPathRef path = [UIBezierPath bezierPathWithRect:_subviewContainer.bounds].CGPath;
            [_subviewContainer.layer setShadowPath:path];
        }
    }
}

#pragma mark - Public

- (void)resetContainerView {
    for (UIView * v in _subviewContainer.subviews) {
        [v removeFromSuperview];
    }
}

- (void)zoomOutToFitScreenDuration:(NSTimeInterval)duration completion:(void (^)(BOOL finished))completion{
    _manualZooming = NO;
    if (duration > 0.0) {
        [UIView animateWithDuration:duration delay:0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
            [self setZoomScale:self.minimumZoomScale animated:NO];
        }completion:completion];
    }
    else {
        [self setZoomScale:self.minimumZoomScale animated:NO];
        if (completion) {
            completion(YES);
        }
    }
}

- (void)zoomOutToFitScreen:(BOOL)animated {
    [self zoomOutToFitScreenDuration:animated?0.5:0 completion:nil];
}

- (void)zoomToRect:(CGRect)rect duration:(NSTimeInterval)duration completion:(void (^)(BOOL finished))completion{
    if (duration > 0.0) {
        [UIView animateWithDuration:duration delay:0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
            [self zoomToRect:rect animated:NO];
        } completion:completion];
    }
    else {
        [self zoomToRect:rect animated:NO];
        if (completion) {
            completion(YES);
        }
    }
}

- (void)zoomToRect:(CGRect)rect animated:(BOOL)animated {
    _manualZooming = YES;
    [super zoomToRect:rect animated:animated];
}

#pragma mark - Private

- (void)setupDoubleTapToZoom {
    if (!_doubleTapGestureRecognizer) {
        _doubleTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(doubleTap:)];
        _doubleTapGestureRecognizer.numberOfTapsRequired = 2;
        _doubleTapGestureRecognizer.numberOfTouchesRequired = 1;
        [self addGestureRecognizer:_doubleTapGestureRecognizer];
        _doubleTapGestureRecognizer.delaysTouchesEnded = NO;
    }
    _doubleTapGestureRecognizer.enabled = YES;
}

- (void)teardownDoubleTapToZoom {
    if (_doubleTapGestureRecognizer) {
        [self removeGestureRecognizer:_doubleTapGestureRecognizer];
        _doubleTapGestureRecognizer = nil;
    }
}

- (void)doubleTap:(UIGestureRecognizer *)recognizer {
    static BOOL isSecondTime = NO;
    static const CGFloat scaleAmount = 2.0f;
    
    CGFloat newScale = self.zoomScale;
    if (isSecondTime) {
        newScale /= scaleAmount;
    }
    else {
        newScale *= scaleAmount;
    }
    isSecondTime = !isSecondTime;

    newScale = MAX(self.minimumZoomScale, MIN(self.maximumZoomScale, newScale));
    if (newScale == self.minimumZoomScale && !isSecondTime) {
        return;
    }
    
    CGRect zoomBox = [self zoomRectForScrollView:self withScale:newScale withCenter:[recognizer locationInView:_subviewContainer]];
    [self zoomToRect:zoomBox animated:YES];
}

- (void)centerSubviewContainer {
    return;
    CGRect innerFrame = _subviewContainer.frame;
    CGRect scrollerBounds = self.bounds;
    
    if ( ( innerFrame.size.width < scrollerBounds.size.width ) || ( innerFrame.size.height < scrollerBounds.size.height ) )
    {
        CGFloat tempx = _subviewContainer.center.x - ( scrollerBounds.size.width / 2 );
        CGFloat tempy = _subviewContainer.center.y - ( scrollerBounds.size.height / 2 );
        CGPoint myScrollViewOffset = CGPointMake( tempx, tempy);
        
        self.contentOffset = myScrollViewOffset;
        
    }
    
    UIEdgeInsets anEdgeInset = { 0, 0, 0, 0};
    if ( scrollerBounds.size.width > innerFrame.size.width )
    {
        anEdgeInset.left = (scrollerBounds.size.width - innerFrame.size.width) / 2;
        anEdgeInset.right = -anEdgeInset.left; // I don't know why this needs to be negative, but that's what works
    }
    if ( scrollerBounds.size.height > innerFrame.size.height )
    {
        anEdgeInset.top = (scrollerBounds.size.height - innerFrame.size.height) / 2;
        anEdgeInset.bottom = -anEdgeInset.top; // I don't know why this needs to be negative, but that's what works
    }
    self.contentInset = anEdgeInset;
}

#pragma mark - ScrollView Delegate

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    if (!(scrollView == self)) {
        return nil;
    }
    return _subviewContainer;
}

- (void)scrollViewWillBeginDecelerating:(UIScrollView *)scrollView {
    _manualZooming = NO;
    [self centerSubviewContainer];
}

#pragma mark - Gesture Recognizer Delegate

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    if (gestureRecognizer == self.pinchGestureRecognizer) {
        _manualZooming = YES;
    }
    return YES;
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    _manualZooming = NO;
    [self centerSubviewContainer];
}


#pragma mark Getters/Setters/Helpers

- (void)setShadowsEnabled:(BOOL)shadowsEnabled {
    if (_shadowsEnabled == shadowsEnabled) {
        return;
    }
    _shadowsEnabled = shadowsEnabled;
    if (_shadowsEnabled) {
        _subviewContainer.layer.shadowOffset = CGSizeZero;
        _subviewContainer.layer.shadowOpacity = 0.7f;
        _subviewContainer.layer.shadowRadius = 5;
        
        CGPathRef path = [UIBezierPath bezierPathWithRect:_subviewContainer.bounds].CGPath;
        [_subviewContainer.layer setShadowPath:path];
    }
    else {
        _subviewContainer.layer.shadowRadius = 0;
        _subviewContainer.layer.shadowOpacity = 0;
        [_subviewContainer.layer setShadowPath:nil];
    }
}

-(void) setOneFingerPanEnabled:(BOOL)oneFingerPanEnabled {
    if (oneFingerPanEnabled) {
        self.panGestureRecognizer.minimumNumberOfTouches = 1;
    }
    else {
        self.panGestureRecognizer.minimumNumberOfTouches = 2;
    }
}
-(BOOL) oneFingerPanEnabled {
    return (self.panGestureRecognizer.minimumNumberOfTouches == 1);
}

- (void)setDoubleTapToZoomEnabled:(BOOL)doubleTapToZoomEnabled {
    if (_doubleTapToZoomEnabled == doubleTapToZoomEnabled) {
        return;
    }
    _doubleTapToZoomEnabled = doubleTapToZoomEnabled;
    if (_doubleTapToZoomEnabled) {
        [self setupDoubleTapToZoom];
    }
    else {
        [self teardownDoubleTapToZoom];
    }
}

-(void)setAnchorPointInViewChoords:(CGPoint)point forView:(UIView*)view {
    point.x /= view.bounds.size.width;
    point.y /= view.bounds.size.height;
    [self setAnchorPoint:point forView:view];
}

-(void)setAnchorPoint:(CGPoint)anchorPoint forView:(UIView *)view {
    CGPoint newPoint = CGPointMake(view.bounds.size.width * anchorPoint.x, view.bounds.size.height * anchorPoint.y);
    CGPoint oldPoint = CGPointMake(view.bounds.size.width * view.layer.anchorPoint.x, view.bounds.size.height * view.layer.anchorPoint.y);
    
    newPoint = CGPointApplyAffineTransform(newPoint, view.transform);
    oldPoint = CGPointApplyAffineTransform(oldPoint, view.transform);
    
    CGPoint position = view.layer.position;
    
    position.x -= oldPoint.x;
    position.x += newPoint.x;
    
    position.y -= oldPoint.y;
    position.y += newPoint.y;
    
    //TODO:check the position if it contains NAN
    if (position.x != position.x || position.y != position.y) {
        return;
    }
    view.layer.position = position;
    view.layer.anchorPoint = anchorPoint;
}

- (CGRect)zoomRectForScrollView:(UIScrollView *)scrollView withScale:(float)scale withCenter:(CGPoint)center {
    
    CGRect zoomRect;
    
    // The zoom rect is in the content view's coordinates.
    // At a zoom scale of 1.0, it would be the size of the
    // imageScrollView's bounds.
    // As the zoom scale decreases, so more content is visible,
    // the size of the rect grows.
    zoomRect.size.height = scrollView.bounds.size.height / scale;
    zoomRect.size.width  = scrollView.bounds.size.width  / scale;
    
    // choose an origin so as to get the right center.
    zoomRect.origin.x = center.x - (zoomRect.size.width  / 2.0);
    zoomRect.origin.y = center.y - (zoomRect.size.height / 2.0);
    
    return zoomRect;
}


@end
