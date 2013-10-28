//
//  EasyPhotoViewController.m
//  EasyPhoto
//
//  Created by Sungju Kwon on 25/10/2013.
//  Copyright (c) 2013 Sungju Kwon. All rights reserved.
//

#import "EasyPhotoViewController.h"
#import "SendPhotoViewController.h"

@interface EasyPhotoViewController ()

@property (nonatomic) GPUImageStillCamera *videoCamera;
@property (nonatomic) GPUImageOutput<GPUImageInput> *filter;
@property (nonatomic) GPUImagePicture *sourcePicture;

@property (nonatomic) UIImage *originalImage;

@property (nonatomic) float scale;
@property (nonatomic) int filterNo;
@property (nonatomic) int frameNo;
@property (nonatomic) float cropFactorStart;
@property (nonatomic) float cropFactorEnd;
@property (nonatomic) AVCaptureFlashMode flashMode;
@property (nonatomic) CGRect previewRect;
@property (nonatomic) BOOL vignetteMode;
@property (nonatomic) int cameraPosition;
@property (nonatomic) int timerMode;

@property (nonatomic) UIScrollView *filterScrollView;
@property (nonatomic) UIScrollView *frameScrollView;
@property (nonatomic) NSArray *filterImageArray;
@property (nonatomic) NSArray *filterSelectedImageArray;
@property (nonatomic) NSArray *frameImageArray;
@property (nonatomic) NSArray *frameSelectedImageArray;
@property (nonatomic) NSMutableArray *frameUIImageArray;
@property (nonatomic) int curMenuKind;

@property (nonatomic) BOOL savedFlipMode;
@property (nonatomic) BOOL savedFlashMode;

@property (nonatomic) UIImage *imageFlash;
@property (nonatomic) UIImage *imageNoFlash;
@property (nonatomic) UIImage *imageAutoFlash;

@property (nonatomic) UIImage *imageTimerNo;
@property (nonatomic) UIImage *imageTimer2;
@property (nonatomic) UIImage *imageTimer5;
@property (nonatomic) UIImage *imageTimer10;

@property (nonatomic) int kMenuShowY;
@property (nonatomic) int kMenuHideY;

@property (nonatomic) float cropStartY;
@property (nonatomic) float cropEndY;

@end

static inline double radians (double degrees) {return degrees * M_PI/180;}

@implementation EasyPhotoViewController

- (UIImage *)loadFrame:(int)no {
    NSString *frameName = [NSString stringWithFormat:@"frame%02d", no];
    NSString *framePath = [[NSBundle mainBundle] pathForResource:frameName ofType:@"png"];
    if (framePath == nil) return nil;
    
    UIImage *frameImage = [[UIImage alloc] initWithContentsOfFile:framePath];
    
    return frameImage;
}

- (void)loadAllFrameImages {
    int count = [self.frameImageArray count];
    self.frameUIImageArray = [[NSMutableArray alloc] initWithCapacity:count];
    
    for (int i = 0; i <= count; i++) {
        [self.frameUIImageArray addObject:[self loadFrame:i]];
    }
}

#define kMenuX      0
#define kMenuHeight 60
#define kMenuWidth  320

#define kScrollObjWidth  60
#define kScrollObjHeight 60

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    if ([[UIScreen mainScreen] respondsToSelector:@selector(scale)] == YES) {
        self.scale = [[UIScreen mainScreen] scale];
    } else {
        self.scale = 1.0f;
    }
    self.kMenuShowY = 350;
    self.kMenuHideY = 420;
    self.cropStartY = 0.24f;
    self.cropEndY = 0.84f;

    self.filterNo = 0;
    self.frameNo = 0;
    self.vignetteMode = FALSE;
    self.curMenuKind = 0;
    self.cameraPosition = AVCaptureDevicePositionBack;
    
    self.focusImageView.hidden = YES;
    self.flashView.hidden = YES;
    self.timerView.hidden = YES;
    self.timerButton.hidden = YES;
    [self.timerButton setTitle:NSLocalizedString(@"Cancel", nil) forState:UIControlStateHighlighted];
    
    UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapToAutoFocus:)];
    [singleTap setNumberOfTapsRequired:1];
    [self.frameView addGestureRecognizer:singleTap];
    [self.filterView addGestureRecognizer:singleTap];
    
    self.filterScrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(kMenuX, self.kMenuHideY, kMenuWidth, kMenuHeight)];
    [self.view insertSubview:self.filterScrollView belowSubview:self.toolBar];
    
    self.filterImageArray = [[NSArray alloc] initWithObjects:
                             @"filter_default.png",
                             @"filter_lomo.png",
                             @"filter_amaro.png",
                             @"filter_bluewooden.png",
                             @"filter_gray.png",
                             @"filter_ilford400.png",
                             @"filter_lomoweird.png",
                             @"filter_nashville.png",
                             @"filter_old.png",
                             @"filter_oldblue.png",
                             @"filter_olddarkpaper.png",
                             @"filter_oldgreen.png",
                             @"filter_oldpaper.png",
                             @"filter_sepia.png",
                             @"filter_sketch.png",
                             @"filter_toon.png",
                             @"filter_invert.png",
                             @"filter_emboss.png",
                             nil];
    
    self.filterSelectedImageArray = [[NSArray alloc] initWithObjects:
                                     @"filter_s_default.png",
                                     @"filter_s_lomo.png",
                                     @"filter_s_amaro.png",
                                     @"filter_s_bluewooden.png",
                                     @"filter_s_gray.png",
                                     @"filter_s_ilford400.png",
                                     @"filter_s_lomoweird.png",
                                     @"filter_s_nashville.png",
                                     @"filter_s_old.png",
                                     @"filter_s_oldblue.png",
                                     @"filter_s_olddarkpaper.png",
                                     @"filter_s_oldgreen.png",
                                     @"filter_s_oldpaper.png",
                                     @"filter_s_sepia.png",
                                     @"filter_s_sketch.png",
                                     @"filter_s_toon.png",
                                     @"filter_s_invert.png",
                                     @"filter_s_emboss.png",
                                     nil];
    
    [self.filterScrollView setBounces:YES];
    [self.filterScrollView setAlwaysBounceVertical:NO];
    [self.filterScrollView setAlwaysBounceHorizontal:YES];
    self.filterScrollView.showsVerticalScrollIndicator = NO;
    self.filterScrollView.showsHorizontalScrollIndicator = NO;
    
    [self setMenuItem:self.filterScrollView withImages:self.filterImageArray withSelectedImages:self.filterSelectedImageArray run:@selector(filterSelected:)];
    
    self.frameScrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(kMenuX, self.kMenuHideY, kMenuWidth, kMenuHeight)];
    [self.view insertSubview:self.frameScrollView belowSubview:self.toolBar];
    
    self.frameImageArray = [[NSArray alloc] initWithObjects:
                            @"frame00thumb.png",
                            @"frame01thumb.png",
                            @"frame02thumb.png",
                            @"frame03thumb.png",
                            @"frame04thumb.png",
                            @"frame05thumb.png",
                            @"frame06thumb.png",
                            @"frame07thumb.png",
                            @"frame08thumb.png",
                            @"frame09thumb.png",
                            @"frame10thumb.png",
                            @"frame11thumb.png",
                            @"frame12thumb.png",
                            @"frame13thumb.png",
                            @"frame14thumb.png",
                            @"frame15thumb.png",
                            @"frame16thumb.png",
                            nil];
    
    self.frameSelectedImageArray = [[NSArray alloc] initWithObjects:
                                    @"frame00_s_thumb.png",
                                    @"frame01_s_thumb.png",
                                    @"frame02_s_thumb.png",
                                    @"frame03_s_thumb.png",
                                    @"frame04_s_thumb.png",
                                    @"frame05_s_thumb.png",
                                    @"frame06_s_thumb.png",
                                    @"frame07_s_thumb.png",
                                    @"frame08_s_thumb.png",
                                    @"frame09_s_thumb.png",
                                    @"frame10_s_thumb.png",
                                    @"frame11_s_thumb.png",
                                    @"frame12_s_thumb.png",
                                    @"frame13_s_thumb.png",
                                    @"frame14_s_thumb.png",
                                    @"frame15_s_thumb.png",
                                    @"frame16_s_thumb.png",
                                    nil];
    

    [self.frameScrollView setBounces:YES];
    [self.frameScrollView setAlwaysBounceVertical:NO];
    [self.frameScrollView setAlwaysBounceHorizontal:YES];
    self.frameScrollView.showsVerticalScrollIndicator = NO;
    self.frameScrollView.showsHorizontalScrollIndicator = NO;
    
    [self setMenuItem:self.frameScrollView withImages:self.frameImageArray withSelectedImages:self.frameSelectedImageArray run:@selector(frameSelected:)];
    
    [self.filterView setFillMode:kGPUImageFillModePreserveAspectRatioAndFill];
    self.previewRect = self.filterView.frame;
    
    [self setupCamera];
    
    self.flipCameraButton.enabled = [self hasFrontCamera];
    self.flashButton.enabled = [self hasFlash];
    
    [self.flashView viewWithTag:0].layer.cornerRadius = 8;
    [self.timerView viewWithTag:0].layer.cornerRadius = 8;
    
    self.imageNoFlash = [UIImage imageNamed:@"t_noflash.png"];
    self.imageAutoFlash = [UIImage imageNamed:@"t_autoflash.png"];
    self.imageFlash = [UIImage imageNamed:@"t_flash.png"];
    self.flashMode = AVCaptureFlashModeOff;
    
    self.imageTimerNo = [UIImage imageNamed:@"timerno.png"];
    self.imageTimer2 = [UIImage imageNamed:@"timer2.png"];
    self.imageTimer5 = [UIImage imageNamed:@"timer5.png"];
    self.imageTimer10 = [UIImage imageNamed:@"timer10.png"];
}

- (void)viewDidAppear:(BOOL)animated
{
    int y;
    
    CGPoint toolBarPoint = self.toolBar.frame.origin;
    if (toolBarPoint.y > 0) {
        self.kMenuHideY = toolBarPoint.y;
        self.kMenuShowY = toolBarPoint.y - kMenuHeight;
        
        CGRect frame = self.filterScrollView.frame;
        CGRect newFrame = CGRectMake(0, self.kMenuHideY, frame.size.width, frame.size.height);
        self.filterScrollView.frame = newFrame;
        self.frameScrollView.frame = newFrame;
    }
    
    //y = (self.view.frame.size.height / 2) - (self.view.frame.size.width / 2);
    y = self.toolBar.frame.origin.y - self.view.frame.size.width;
    
    CGRect viewRect = CGRectMake(0, y, self.view.frame.size.width, self.view.frame.size.width);
    self.filterView.frame = viewRect;
    self.frameView.frame = viewRect;
    self.stillFilterView.frame = viewRect;
    self.previewRect = viewRect;
    
    [self loadConfig];
    
    self.cropStartY =  self.frameView.frame.origin.y / self.view.frame.size.height;
    self.cropEndY = (self.frameView.frame.origin.y +self.frameView.frame.size.height) / self.view.frame.size.height;
    
    float imageWidth = 1080;
    float imageHeight = 1920;
    float startY = (imageHeight - imageWidth) / 2;
    self.cropStartY = startY / imageHeight;
    self.cropEndY = imageWidth / imageHeight;
    
    [self selectScrollMenu:self.filterScrollView fromFilter:0 toFilter:self.filterNo + 1];
    [self selectScrollMenu:self.frameScrollView fromFilter:0 toFilter:self.frameNo + 1];
    
    if (self.videoCamera != nil && self.originalImage == nil) {
        [self setCameraFrame:self.frameNo];
        [self setCameraFilter:self.filterNo];
        if (self.cameraPosition != self.videoCamera.cameraPosition)
            [self.videoCamera rotateCamera];
        [self.videoCamera resumeCameraCapture];
        [self setFlashMenuStatus];
        self.filmRollButton.image = [UIImage imageNamed:@"filmroll.png"];
    } else {
        self.filmRollButton.image = [UIImage imageNamed:@"camera.png"];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)setTimerImage
{
    switch (self.timerMode) {
        case 0:
            self.timerBarButton.image = self.imageTimerNo;
            break;
        case 2:
            self.timerBarButton.image = self.imageTimer2;
            break;
        case 5:
            self.timerBarButton.image = self.imageTimer5;
            break;
        case 10:
            self.timerBarButton.image = self.imageTimer10;
            break;
        default:
            break;
    }
}

#pragma mark -
#pragma mark Config
- (void)loadConfig
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    self.filterNo = ((NSNumber *)[defaults valueForKey:@"filterNo"]).intValue;
    self.frameNo = ((NSNumber *)[defaults valueForKey:@"frameNo"]).intValue;
    self.vignetteMode = ((NSNumber *)[defaults valueForKey:@"vignetteMode"]).boolValue;
    self.curMenuKind = ((NSNumber *)[defaults valueForKey:@"curMenuKind"]).intValue;
    self.cameraPosition = ((NSNumber *)[defaults valueForKey:@"cameraPosition"]).intValue;
    if ([defaults valueForKey:@"cameraPosition"] == nil)
        self.cameraPosition = AVCaptureDevicePositionBack;
    self.timerMode = ((NSNumber *)[defaults valueForKey:@"timerMode"]).intValue;
    [self setTimerImage];
}

#pragma mark -
#pragma mark Camera Setup
- (void)setupCamera {
    self.videoCamera = [[GPUImageStillCamera alloc]
                        initWithSessionPreset:AVCaptureSessionPreset1920x1080 cameraPosition:self.cameraPosition];
    
    self.videoCamera.outputImageOrientation = UIInterfaceOrientationPortrait;
    
    [self loadConfig];
    [self setCameraFilter:self.filterNo];

    [self.videoCamera startCameraCapture];
}

- (BOOL)hasFrontCamera {
    NSArray *devices = [AVCaptureDevice devices];
    
    BOOL hasFrontCamera = NO;
    for (AVCaptureDevice *device in devices) {
        if ([device hasMediaType:AVMediaTypeVideo]) {
            if ([device position] == AVCaptureDevicePositionFront) {
                hasFrontCamera = YES;
            }
        }
    }
    return hasFrontCamera;
}

- (BOOL)hasFlash {
    return [self.videoCamera.inputCamera hasFlash];
}

- (void)setFlash:(AVCaptureFlashMode)mode {
    AVCaptureDevice *videoInput = self.videoCamera.inputCamera;
    
    if (![videoInput hasFlash]) return;
    [self.videoCamera.captureSession beginConfiguration];
    [videoInput lockForConfiguration:nil];
    
    [videoInput setFlashMode:mode];
    
    [videoInput unlockForConfiguration];
    [self.videoCamera.captureSession commitConfiguration];
}

- (void)autoFocusAtPoint:(CGPoint)point
{
    AVCaptureDevice *inputDevice;
    
    if ([inputDevice isFocusModeSupported:AVCaptureFocusModeAutoFocus]) {
        NSError *error;
        if ([inputDevice lockForConfiguration:&error]) {
            [inputDevice setFocusPointOfInterest:point];
            [inputDevice setFocusMode:AVCaptureFocusModeAutoFocus];
            [inputDevice unlockForConfiguration];
        }
    }
}

#pragma mark -
#pragma mark Scroll Menu

- (void)selectScrollMenu:(UIScrollView *)scrollView fromFilter:(int)oldFilterNo toFilter:(int)newFilterNo {
    UIView *view = nil;
    NSArray *subviews = [scrollView subviews];
    
    for (view in subviews) {
        if ([view isKindOfClass:[UIView class]]) {
            if (view.tag == oldFilterNo) {
                UIButton *button = (UIButton *)view;
                [button setSelected:NO];
            }
            if (view.tag == newFilterNo) {
                UIButton *button = (UIButton *)view;
                [button setSelected:YES];
            }
        }
    }
}

- (void)filterSelected:(UIButton *)button {
    int oldFilterNo = self.filterNo;
    self.filterNo = button.tag - 1;

    [self selectScrollMenu:self.filterScrollView fromFilter:oldFilterNo + 1 toFilter:self.filterNo + 1];
    [self setCameraFilter:self.filterNo];
}

- (void)frameSelected:(UIButton *)button {
    int oldFrameNo = self.frameNo;
    self.frameNo = button.tag - 1;

    [self selectScrollMenu:self.frameScrollView fromFilter:oldFrameNo + 1 toFilter:self.frameNo + 1];
    [self setCameraFrame:self.frameNo];
}

- (void)layoutScrollDetailViews:(UIScrollView *)scrollView withCount:(int)count
{
    UIView *view = nil;
    NSArray *subviews = [scrollView subviews];
    
    CGFloat curXLoc = 0;
    for (view in subviews) {
        if ([view isKindOfClass:[UIView class]] && view.tag > 0) {
            CGRect frame = view.frame;
            frame.origin = CGPointMake(curXLoc, 0);
            frame.size.width = (kScrollObjWidth) + 10;
            frame.size.height = (kScrollObjHeight);
            view.frame = frame;
            curXLoc += (kScrollObjWidth) + 10;
        }
    }
    
    [scrollView setContentSize:CGSizeMake((count * (kScrollObjWidth + 10)),
                                          [scrollView bounds].size.height)];
    [scrollView setMaximumZoomScale:1.0];
    [scrollView setMinimumZoomScale:1.0];
    [scrollView becomeFirstResponder];
    [scrollView setNeedsDisplay];
    scrollView.pagingEnabled = NO;
}

- (void)removeViews:(UIScrollView *)scrollView;
{
    UIView *view = nil;
    NSArray *subviews = [scrollView subviews];
    
    for (view in subviews) {
        if ([view isKindOfClass:[UIView class]] && view.tag > 0) {
            [view removeFromSuperview];
        }
    }
}

- (void)setMenuItem:(UIScrollView *)scrollView withImages:(NSArray *)imageArray withSelectedImages:(NSArray *)selectedImageArray run:(SEL)selector {
    int i = 0;
    [self removeViews:scrollView];
    
    for (NSString *imageName in imageArray) {
        UIButton *button = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, kScrollObjWidth, kScrollObjHeight)];
        [button setImage:[UIImage imageNamed:imageName] forState:UIControlStateNormal];
        [button setImage:[UIImage imageNamed:[selectedImageArray objectAtIndex:i]] forState:UIControlStateSelected];
        
        button.tag = ++i;
        [button addTarget:self action:selector forControlEvents:UIControlEventTouchUpInside];
        [scrollView addSubview:button];
    }
    
    [self layoutScrollDetailViews:scrollView withCount:[imageArray count]];
}

#pragma mark -
#pragma mark Selectors

- (void)hideMenus {
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:0.5];
    [UIView setAnimationDelay:0.0];
    [UIView setAnimationCurve:UIViewAnimationCurveEaseOut];
    
    self.flashView.hidden = YES;
    self.timerView.hidden = YES;
    
    [UIView commitAnimations];
}

- (void)scrollMenuShow:(BOOL)show forScroll:(UIScrollView *)scrollView {
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:0.5];
    [UIView setAnimationDelay:0.0];
    
    CGRect rect = scrollView.frame;
    if (show) {
        rect.origin.y = self.kMenuShowY;
        [UIView setAnimationCurve:UIViewAnimationCurveEaseOut];
    } else {
        rect.origin.y = self.kMenuHideY;
        [UIView setAnimationCurve:UIViewAnimationCurveEaseIn];
    }
    scrollView.frame = rect;
    
    rect = self.previewRect;
    rect.origin.x = 0;
    rect.origin.y = self.previewRect.origin.y - (show ? 20.0 : 0.0);
    rect.size = self.previewRect.size;
    self.frameView.frame = rect;
    self.stillFilterView.frame = rect;
    self.filterView.frame = rect;
    
    [UIView commitAnimations];
}

- (CGPoint)convertToPointOfInterestFromViewCoordinates:(CGPoint)viewCoordinates
{
    CGPoint pointOfInterest = CGPointMake(.5f, .5f);
    CGSize frameSize;
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    frameSize.height = screenRect.size.width;
    frameSize.width = screenRect.size.height;
    // Scale, switch x and y, and reverse x
    pointOfInterest = CGPointMake(viewCoordinates.y / frameSize.height, 1.f - (viewCoordinates.x / frameSize.width));
    
    return pointOfInterest;
}

- (void)tapToAutoFocus:(UIGestureRecognizer *)gestureRecognizer
{
    [self hideMenus];
    [self scrollMenuShow:NO forScroll:self.frameScrollView];
    [self scrollMenuShow:NO forScroll:self.filterScrollView];
    
    CGPoint focusPoint = [gestureRecognizer locationInView:self.view];
    CGRect newLocation = self.focusImageView.frame;
    newLocation.origin.x = focusPoint.x - (newLocation.size.width / 2);
    newLocation.origin.y = focusPoint.y - (newLocation.size.height / 2);
    
    self.focusImageView.frame = newLocation;
    [self.focusImageView setHidden:NO];
    
    CGPoint tapPoint = [gestureRecognizer locationInView:self.view];
    CGPoint convertedFocusPoint = [self convertToPointOfInterestFromViewCoordinates:tapPoint];
    [self autoFocusAtPoint:convertedFocusPoint];
    
    [self performSelector:@selector(hideFocusImageView:) withObject:nil afterDelay:0.5];
}

- (void)hideFocusImageView:(id)data {
    [self.focusImageView setHidden:YES];
}


#pragma mark -
#pragma mark Filter and Frame

- (void)showSendPhotoViewController:(UIImage *)image {
    SendPhotoViewController *sendPhotoViewController = [[SendPhotoViewController alloc] initWithNibName:@"SendPhotoViewController" bundle:nil];
    
    sendPhotoViewController.photoImage = image;
    [self presentViewController:sendPhotoViewController animated:YES completion:^{
        
    }];
}

- (void)sendToTheTarget:(UIImage *)stillImage
{
    GPUImageAlphaBlendFilter *blendFilter = [[GPUImageAlphaBlendFilter alloc] init];
    GPUImagePicture *imageToProcess = [[GPUImagePicture alloc] initWithImage:stillImage];
    GPUImagePicture *border = [[GPUImagePicture alloc] initWithImage:self.frameView.image];
    
    blendFilter.mix = 1.0f;
    [imageToProcess addTarget:blendFilter];
    [border addTarget:blendFilter];
    
    [border processImage];
    [imageToProcess processImage];
    [self showSendPhotoViewController:[blendFilter imageFromCurrentlyProcessedOutput]];
    
    return;
}

- (void)setCameraFilter:(int)no {
    self.filterView.hidden = YES;
    
    if (self.filter != nil) {
        if (self.originalImage == nil) {
            [self.videoCamera stopCameraCapture];

            [self.videoCamera removeTarget:self.filter];
        }
    }
    GPUImageFilterGroup *newFilter = nil;
    
    switch (no) {
        case 0:
            newFilter = [self filterDefaultFilter];
            break;
        case 1:
            newFilter = [self filterLomoFilter];
            break;
        case 2:
            newFilter = [self filterAmaroFilter];
            break;
        case 3:
            newFilter = [self filterWoodenFilter];
            break;
        case 4:
            newFilter = [self filterGrayFilter];
            break;
        case 5:
            newFilter = [self filterIlford400Filter];
            break;
        case 6:
            newFilter = [self filterLomoWeirdFilter];
            break;
        case 7:
            newFilter = [self filterNashvilleFilter];
            break;
        case 8:
            newFilter = [self filterOldFilter];
            break;
        case 9:
            newFilter = [self filterOldBlueFilter];
            break;
        case 10:
            newFilter = [self filterOldDarkPaperFilter];
            break;
        case 11:
            newFilter = [self filterOldGreenFilter];
            break;
        case 12:
            newFilter = [self filterOldPaperFilter];
            break;
        case 13:
            newFilter = [self filterSepiaFilter];
            break;
        case 14:
            newFilter = [self filterSketchFilter];
            break;
        case 15:
            newFilter = [self filterToonFilter];
            break;
        case 16:
            newFilter = [self filterInvertFilter];
            break;
        case 17:
            newFilter = [self filterEmbossFilter];
            break;
        default:
            break;
    }
    if (newFilter != nil)
        self.filter = newFilter;
    
    if (self.originalImage == nil) {
        [self.videoCamera addTarget:self.filter];
        
        [self.filter addTarget:self.filterView];
        [self.videoCamera startCameraCapture];
    } else {
        self.stillFilterView.image = [self.filter imageByFilteringImage:self.originalImage];
    }
    
    self.filterView.hidden = NO;
}

- (void)setCameraFrame:(int)no {
    self.frameView.image = [self loadFrame:no];
}

- (GPUImageFilterGroup *)filterDefaultFilter {
    GPUImageFilterGroup *newFilter;
    
    newFilter = [[GPUImageFilterGroup alloc] init];
    
    GPUImageCropFilter *cropFilter = [[GPUImageCropFilter alloc] initWithCropRegion:CGRectMake(0.f, self.cropStartY, 1.f, self.cropEndY)];
    
    GPUImageBrightnessFilter *brightFilter = [[GPUImageBrightnessFilter alloc] init];
    [brightFilter setBrightness:0.0];
    
    GPUImageVignetteFilter *vignetteFilter = [[GPUImageVignetteFilter alloc] init];
    if (self.vignetteMode == NO)
        [vignetteFilter setVignetteEnd:5.0];
    
    [(GPUImageFilterGroup *)newFilter addFilter:cropFilter];
    [(GPUImageFilterGroup *)newFilter addFilter:brightFilter];
    [(GPUImageFilterGroup *)newFilter addFilter:vignetteFilter];
    
    [cropFilter prepareForImageCapture];
    [brightFilter prepareForImageCapture];
    [vignetteFilter prepareForImageCapture];
    
    [cropFilter addTarget:brightFilter];
    [brightFilter addTarget:vignetteFilter];
    
    [(GPUImageFilterGroup *)newFilter setInitialFilters:[NSArray arrayWithObject:cropFilter]];
    [(GPUImageFilterGroup *)newFilter setTerminalFilter:vignetteFilter];
    
    [newFilter prepareForImageCapture];
    
    return newFilter;
}

- (GPUImageFilterGroup *)filterOldPaperFilter {
    GPUImageFilterGroup *newFilter;
    
    newFilter = [[GPUImageFilterGroup alloc] init];
    
    self.sourcePicture = [[GPUImagePicture alloc] initWithImage:[UIImage imageNamed:@"oldpaper1.jpg"] smoothlyScaleOutput:YES];
    [self.sourcePicture processImage];
    
    GPUImageCropFilter *cropFilter = [[GPUImageCropFilter alloc] initWithCropRegion:CGRectMake(0.f, self.cropStartY, 1.f, self.cropEndY)];
    
    GPUImageGammaFilter *gammaFilter = [[GPUImageGammaFilter alloc] init];
    [gammaFilter setGamma:1.0];
    
    GPUImageContrastFilter *contrastFilter = [[GPUImageContrastFilter alloc] init];
    [contrastFilter setContrast:2.5];
    
    GPUImageSoftLightBlendFilter *imageFilter = [[GPUImageSoftLightBlendFilter alloc] init];
    
    GPUImageToneCurveFilter *curveFilter = [[GPUImageToneCurveFilter alloc] init];
    [curveFilter setRedControlPoints:[NSArray arrayWithObjects:[NSValue valueWithCGPoint:CGPointMake(0.0, 0.15)], [NSValue valueWithCGPoint:CGPointMake(0.5, 0.65)], [NSValue valueWithCGPoint:CGPointMake(1.0, 0.85)], nil]];
    
    GPUImageVignetteFilter *vignetteFilter = [[GPUImageVignetteFilter alloc] init];
    if (self.vignetteMode == NO)
        [vignetteFilter setVignetteEnd:5.0];
    
    [(GPUImageFilterGroup *)newFilter addFilter:cropFilter];
    [(GPUImageFilterGroup *)newFilter addFilter:gammaFilter];
    [(GPUImageFilterGroup *)newFilter addFilter:contrastFilter];
    [(GPUImageFilterGroup *)newFilter addFilter:imageFilter];
    [(GPUImageFilterGroup *)newFilter addFilter:curveFilter];
    [(GPUImageFilterGroup *)newFilter addFilter:vignetteFilter];
    
    [cropFilter prepareForImageCapture];
    [gammaFilter prepareForImageCapture];
    [contrastFilter prepareForImageCapture];
    [imageFilter prepareForImageCapture];
    [curveFilter prepareForImageCapture];
    [vignetteFilter prepareForImageCapture];
    
    [cropFilter addTarget:gammaFilter];
    [gammaFilter addTarget:contrastFilter];
    [contrastFilter addTarget:imageFilter];
    [imageFilter addTarget:curveFilter];
    [curveFilter addTarget:vignetteFilter];
    
    [(GPUImageFilterGroup *)newFilter setInitialFilters:[NSArray arrayWithObject:cropFilter]];
    [(GPUImageFilterGroup *)newFilter setTerminalFilter:vignetteFilter];
    
    [self.sourcePicture addTarget:imageFilter];
    
    [newFilter prepareForImageCapture];
    
    return newFilter;
}

- (GPUImageFilterGroup *)filterOldBlueFilter {
    GPUImageFilterGroup *newFilter;
    
    newFilter = [[GPUImageFilterGroup alloc] init];
    
    self.sourcePicture = [[GPUImagePicture alloc] initWithImage:[UIImage imageNamed:@"oldpaper3.jpg"] smoothlyScaleOutput:YES];
    [self.sourcePicture processImage];
    
    GPUImageCropFilter *cropFilter = [[GPUImageCropFilter alloc] initWithCropRegion:CGRectMake(0.f, self.cropStartY, 1.f, self.cropEndY)];
    
    GPUImageGammaFilter *gammaFilter = [[GPUImageGammaFilter alloc] init];
    [gammaFilter setGamma:1.0];
    
    GPUImageContrastFilter *contrastFilter = [[GPUImageContrastFilter alloc] init];
    [contrastFilter setContrast:2.5];
    
    GPUImageSoftLightBlendFilter *imageFilter = [[GPUImageSoftLightBlendFilter alloc] init];
    
    GPUImageToneCurveFilter *curveFilter = [[GPUImageToneCurveFilter alloc] init];
    [curveFilter setBlueControlPoints:[NSArray arrayWithObjects:[NSValue valueWithCGPoint:CGPointMake(0.0, 0.15)], [NSValue valueWithCGPoint:CGPointMake(0.5, 0.65)], [NSValue valueWithCGPoint:CGPointMake(1.0, 0.85)], nil]];
    
    GPUImageVignetteFilter *vignetteFilter = [[GPUImageVignetteFilter alloc] init];
    if (self.vignetteMode == NO)
        [vignetteFilter setVignetteEnd:5.0];
    
    [(GPUImageFilterGroup *)newFilter addFilter:cropFilter];
    [(GPUImageFilterGroup *)newFilter addFilter:gammaFilter];
    [(GPUImageFilterGroup *)newFilter addFilter:contrastFilter];
    [(GPUImageFilterGroup *)newFilter addFilter:imageFilter];
    [(GPUImageFilterGroup *)newFilter addFilter:curveFilter];
    [(GPUImageFilterGroup *)newFilter addFilter:vignetteFilter];
    
    [cropFilter prepareForImageCapture];
    [gammaFilter prepareForImageCapture];
    [contrastFilter prepareForImageCapture];
    [imageFilter prepareForImageCapture];
    [curveFilter prepareForImageCapture];
    [vignetteFilter prepareForImageCapture];
    
    [cropFilter addTarget:gammaFilter];
    [gammaFilter addTarget:contrastFilter];
    [contrastFilter addTarget:imageFilter];
    [imageFilter addTarget:curveFilter];
    [curveFilter addTarget:vignetteFilter];
    
    [(GPUImageFilterGroup *)newFilter setInitialFilters:[NSArray arrayWithObject:cropFilter]];
    [(GPUImageFilterGroup *)newFilter setTerminalFilter:vignetteFilter];
    
    [self.sourcePicture addTarget:imageFilter];
    
    [newFilter prepareForImageCapture];
    
    return newFilter;
}

- (GPUImageFilterGroup *)filterOldGreenFilter {
    GPUImageFilterGroup *newFilter;
    
    newFilter = [[GPUImageFilterGroup alloc] init];
    
    self.sourcePicture = [[GPUImagePicture alloc] initWithImage:[UIImage imageNamed:@"oldpaper4.jpg"] smoothlyScaleOutput:YES];
    [self.sourcePicture processImage];
    
    GPUImageCropFilter *cropFilter = [[GPUImageCropFilter alloc] initWithCropRegion:CGRectMake(0.f, self.cropStartY, 1.f, self.cropEndY)];
    
    GPUImageGammaFilter *gammaFilter = [[GPUImageGammaFilter alloc] init];
    [gammaFilter setGamma:1.0];
    
    GPUImageContrastFilter *contrastFilter = [[GPUImageContrastFilter alloc] init];
    [contrastFilter setContrast:2.5];
    
    GPUImageSoftLightBlendFilter *imageFilter = [[GPUImageSoftLightBlendFilter alloc] init];
    
    GPUImageToneCurveFilter *curveFilter = [[GPUImageToneCurveFilter alloc] init];
    [curveFilter setRgbCompositeControlPoints:[NSArray arrayWithObjects:[NSValue valueWithCGPoint:CGPointMake(0.0, 0.15)], [NSValue valueWithCGPoint:CGPointMake(0.5, 0.65)], [NSValue valueWithCGPoint:CGPointMake(1.0, 0.85)], nil]];
    //[curveFilter setRGBControlPoints:[NSArray arrayWithObjects:[NSValue valueWithCGPoint:CGPointMake(0.0, 0.15)], [NSValue valueWithCGPoint:CGPointMake(0.5, 0.65)], [NSValue valueWithCGPoint:CGPointMake(1.0, 0.85)], nil]];
    
    GPUImageVignetteFilter *vignetteFilter = [[GPUImageVignetteFilter alloc] init];
    if (self.vignetteMode == NO)
        [vignetteFilter setVignetteEnd:5.0];
    
    [(GPUImageFilterGroup *)newFilter addFilter:cropFilter];
    [(GPUImageFilterGroup *)newFilter addFilter:gammaFilter];
    [(GPUImageFilterGroup *)newFilter addFilter:contrastFilter];
    [(GPUImageFilterGroup *)newFilter addFilter:imageFilter];
    [(GPUImageFilterGroup *)newFilter addFilter:curveFilter];
    [(GPUImageFilterGroup *)newFilter addFilter:vignetteFilter];
    
    [cropFilter prepareForImageCapture];
    [gammaFilter prepareForImageCapture];
    [contrastFilter prepareForImageCapture];
    [imageFilter prepareForImageCapture];
    [curveFilter prepareForImageCapture];
    [vignetteFilter prepareForImageCapture];
    
    [cropFilter addTarget:gammaFilter];
    [gammaFilter addTarget:contrastFilter];
    [contrastFilter addTarget:imageFilter];
    [imageFilter addTarget:curveFilter];
    [curveFilter addTarget:vignetteFilter];
    
    [(GPUImageFilterGroup *)newFilter setInitialFilters:[NSArray arrayWithObject:cropFilter]];
    [(GPUImageFilterGroup *)newFilter setTerminalFilter:vignetteFilter];
    
    [self.sourcePicture addTarget:imageFilter];
    
    [newFilter prepareForImageCapture];
    
    return newFilter;
}

- (GPUImageFilterGroup *)filterOldDarkPaperFilter {
    GPUImageFilterGroup *newFilter;
    
    newFilter = [[GPUImageFilterGroup alloc] init];
    
    self.sourcePicture = [[GPUImagePicture alloc] initWithImage:[UIImage imageNamed:@"oldpaper2.jpg"] smoothlyScaleOutput:YES];
    [self.sourcePicture processImage];
    
    GPUImageCropFilter *cropFilter = [[GPUImageCropFilter alloc] initWithCropRegion:CGRectMake(0.f, self.cropStartY, 1.f, self.cropEndY)];
    
    GPUImageBrightnessFilter *brightFilter = [[GPUImageBrightnessFilter alloc] init];
    [brightFilter setBrightness:-0.1];
    
    GPUImageContrastFilter *contrastFilter = [[GPUImageContrastFilter alloc] init];
    [contrastFilter setContrast:1.5];
    
    GPUImageSoftLightBlendFilter *imageFilter = [[GPUImageSoftLightBlendFilter alloc] init];
    
    GPUImageToneCurveFilter *curveFilter = [[GPUImageToneCurveFilter alloc] init];
    [curveFilter setRedControlPoints:[NSArray arrayWithObjects:[NSValue valueWithCGPoint:CGPointMake(0.0, 0.15)], [NSValue valueWithCGPoint:CGPointMake(0.5, 0.65)], [NSValue valueWithCGPoint:CGPointMake(1.0, 0.85)], nil]];
    
    GPUImageVignetteFilter *vignetteFilter = [[GPUImageVignetteFilter alloc] init];
    if (self.vignetteMode == NO)
        [vignetteFilter setVignetteEnd:5.0];
    
    [(GPUImageFilterGroup *)newFilter addFilter:cropFilter];
    [(GPUImageFilterGroup *)newFilter addFilter:brightFilter];
    [(GPUImageFilterGroup *)newFilter addFilter:contrastFilter];
    [(GPUImageFilterGroup *)newFilter addFilter:imageFilter];
    [(GPUImageFilterGroup *)newFilter addFilter:curveFilter];
    [(GPUImageFilterGroup *)newFilter addFilter:vignetteFilter];
    
    [cropFilter prepareForImageCapture];
    [brightFilter prepareForImageCapture];
    [contrastFilter prepareForImageCapture];
    [imageFilter prepareForImageCapture];
    [curveFilter prepareForImageCapture];
    [vignetteFilter prepareForImageCapture];
    
    [cropFilter addTarget:brightFilter];
    [brightFilter addTarget:contrastFilter];
    [contrastFilter addTarget:imageFilter];
    [imageFilter addTarget:curveFilter];
    [curveFilter addTarget:vignetteFilter];
    
    [(GPUImageFilterGroup *)newFilter setInitialFilters:[NSArray arrayWithObject:cropFilter]];
    [(GPUImageFilterGroup *)newFilter setTerminalFilter:vignetteFilter];
    
    [self.sourcePicture addTarget:imageFilter];
    
    [newFilter prepareForImageCapture];
    
    return newFilter;
}

- (GPUImageFilterGroup *)filterAmaroFilter {
    GPUImageFilterGroup *newFilter;
    
    newFilter = [[GPUImageFilterGroup alloc] init];
    
    self.sourcePicture = [[GPUImagePicture alloc] initWithImage:[UIImage imageNamed:@"amaro.jpg"] smoothlyScaleOutput:YES];
    [self.sourcePicture processImage];
    
    GPUImageCropFilter *cropFilter = [[GPUImageCropFilter alloc] initWithCropRegion:CGRectMake(0.f, self.cropStartY, 1.f, self.cropEndY)];
    
    GPUImageGammaFilter *gammaFilter = [[GPUImageGammaFilter alloc] init];
    [gammaFilter setGamma:1.0];
    
    GPUImageContrastFilter *contrastFilter = [[GPUImageContrastFilter alloc] init];
    [contrastFilter setContrast:1.5];
    
    GPUImageSoftLightBlendFilter *imageFilter = [[GPUImageSoftLightBlendFilter alloc] init];
    
    GPUImageToneCurveFilter *curveFilter = [[GPUImageToneCurveFilter alloc] init];
    [curveFilter setRedControlPoints:[NSArray arrayWithObjects:[NSValue valueWithCGPoint:CGPointMake(0.0, 0.15)], [NSValue valueWithCGPoint:CGPointMake(0.5, 0.65)], [NSValue valueWithCGPoint:CGPointMake(1.0, 0.85)], nil]];
    
    GPUImageVignetteFilter *vignetteFilter = [[GPUImageVignetteFilter alloc] init];
    if (self.vignetteMode == NO)
        [vignetteFilter setVignetteEnd:5.0];
    
    [(GPUImageFilterGroup *)newFilter addFilter:cropFilter];
    [(GPUImageFilterGroup *)newFilter addFilter:gammaFilter];
    [(GPUImageFilterGroup *)newFilter addFilter:contrastFilter];
    [(GPUImageFilterGroup *)newFilter addFilter:imageFilter];
    [(GPUImageFilterGroup *)newFilter addFilter:curveFilter];
    [(GPUImageFilterGroup *)newFilter addFilter:vignetteFilter];
    
    [cropFilter prepareForImageCapture];
    [gammaFilter prepareForImageCapture];
    [contrastFilter prepareForImageCapture];
    [imageFilter prepareForImageCapture];
    [curveFilter prepareForImageCapture];
    [vignetteFilter prepareForImageCapture];
    
    [cropFilter addTarget:gammaFilter];
    [gammaFilter addTarget:contrastFilter];
    [contrastFilter addTarget:imageFilter];
    [imageFilter addTarget:curveFilter];
    [curveFilter addTarget:vignetteFilter];
    
    [(GPUImageFilterGroup *)newFilter setInitialFilters:[NSArray arrayWithObject:cropFilter]];
    [(GPUImageFilterGroup *)newFilter setTerminalFilter:vignetteFilter];
    
    [self.sourcePicture addTarget:imageFilter];
    
    [newFilter prepareForImageCapture];
    
    return newFilter;
}

- (GPUImageFilterGroup *)filterOldFilter {
    GPUImageFilterGroup *newFilter;
    
    newFilter = [[GPUImageFilterGroup alloc] init];
    
    GPUImageCropFilter *cropFilter = [[GPUImageCropFilter alloc] initWithCropRegion:CGRectMake(0.f, self.cropStartY, 1.f, self.cropEndY)];
    
    GPUImageGammaFilter *gammaFilter = [[GPUImageGammaFilter alloc] init];
    [gammaFilter setGamma:0.5];
    
    GPUImageExposureFilter *exposureFilter = [[GPUImageExposureFilter alloc] init];
    [exposureFilter setExposure:0.1];
    
    GPUImageVignetteFilter *vignetteFilter = [[GPUImageVignetteFilter alloc] init];
    if (self.vignetteMode == NO)
        [vignetteFilter setVignetteEnd:5.0];
    
    [(GPUImageFilterGroup *)newFilter addFilter:cropFilter];
    [(GPUImageFilterGroup *)newFilter addFilter:gammaFilter];
    [(GPUImageFilterGroup *)newFilter addFilter:exposureFilter];
    [(GPUImageFilterGroup *)newFilter addFilter:vignetteFilter];
    
    [cropFilter prepareForImageCapture];
    [gammaFilter prepareForImageCapture];
    [exposureFilter prepareForImageCapture];
    [vignetteFilter prepareForImageCapture];
    
    [cropFilter addTarget:gammaFilter];
    [gammaFilter addTarget:exposureFilter];
    [exposureFilter addTarget:vignetteFilter];
    
    [(GPUImageFilterGroup *)newFilter setInitialFilters:[NSArray arrayWithObject:cropFilter]];
    [(GPUImageFilterGroup *)newFilter setTerminalFilter:vignetteFilter];
    
    [newFilter prepareForImageCapture];
    
    return newFilter;
}

- (GPUImageFilterGroup *)filterNashvilleFilter {
    GPUImageFilterGroup *newFilter;
    
    newFilter = [[GPUImageFilterGroup alloc] init];
    
    self.sourcePicture = [[GPUImagePicture alloc] initWithImage:[UIImage imageNamed:@"nashville.png"] smoothlyScaleOutput:YES];
    [self.sourcePicture processImage];
    
    GPUImageCropFilter *cropFilter = [[GPUImageCropFilter alloc] initWithCropRegion:CGRectMake(0.f, self.cropStartY, 1.f, self.cropEndY)];
    
    GPUImageBrightnessFilter *brightFilter = [[GPUImageBrightnessFilter alloc] init];
    [brightFilter setBrightness:-0.1];
    
    GPUImageSoftLightBlendFilter *nashvilleFilter = [[GPUImageSoftLightBlendFilter alloc] init];
    
    GPUImageVignetteFilter *vignetteFilter = [[GPUImageVignetteFilter alloc] init];
    if (self.vignetteMode == NO)
        [vignetteFilter setVignetteEnd:5.0];
    
    [(GPUImageFilterGroup *)newFilter addFilter:cropFilter];
    [(GPUImageFilterGroup *)newFilter addFilter:brightFilter];
    [(GPUImageFilterGroup *)newFilter addFilter:nashvilleFilter];
    [(GPUImageFilterGroup *)newFilter addFilter:vignetteFilter];
    
    [cropFilter prepareForImageCapture];
    [brightFilter prepareForImageCapture];
    [nashvilleFilter prepareForImageCapture];
    [vignetteFilter prepareForImageCapture];
    
    [cropFilter addTarget:brightFilter];
    [brightFilter addTarget:nashvilleFilter];
    [nashvilleFilter addTarget:vignetteFilter];
    
    [(GPUImageFilterGroup *)newFilter setInitialFilters:[NSArray arrayWithObject:cropFilter]];
    [(GPUImageFilterGroup *)newFilter setTerminalFilter:vignetteFilter];
    
    [self.sourcePicture addTarget:nashvilleFilter];
    
    [newFilter prepareForImageCapture];
    
    return newFilter;
}

- (GPUImageFilterGroup *)filterLomoFilter {
    GPUImageFilterGroup *newFilter;
    
    newFilter = [[GPUImageFilterGroup alloc] init];
    
    self.sourcePicture = [[GPUImagePicture alloc] initWithImage:[UIImage imageNamed:@"nashville.png"] smoothlyScaleOutput:YES];
    [self.sourcePicture processImage];
    
    GPUImageCropFilter *cropFilter = [[GPUImageCropFilter alloc] initWithCropRegion:CGRectMake(0.f, self.cropStartY, 1.f, self.cropEndY)];
    
    GPUImageBrightnessFilter *brightFilter = [[GPUImageBrightnessFilter alloc] init];
    [brightFilter setBrightness:0.05];
    GPUImageContrastFilter *contrastFilter = [[GPUImageContrastFilter alloc] init];
    [contrastFilter setContrast:1.5];
    
    GPUImageSoftLightBlendFilter *imageFilter = [[GPUImageSoftLightBlendFilter alloc] init];
    
    GPUImageToneCurveFilter *curveFilter = [[GPUImageToneCurveFilter alloc] init];
    [curveFilter setRgbCompositeControlPoints:[NSArray arrayWithObjects:[NSValue valueWithCGPoint:CGPointMake(0.0, 0.15)], [NSValue valueWithCGPoint:CGPointMake(0.5, 0.5)], [NSValue valueWithCGPoint:CGPointMake(1.0, 0.75)], nil]];
    //[curveFilter setRGBControlPoints:[NSArray arrayWithObjects:[NSValue valueWithCGPoint:CGPointMake(0.0, 0.15)], [NSValue valueWithCGPoint:CGPointMake(0.5, 0.5)], [NSValue valueWithCGPoint:CGPointMake(1.0, 0.75)], nil]];
    
    GPUImageVignetteFilter *vignetteFilter = [[GPUImageVignetteFilter alloc] init];
    if (self.vignetteMode == NO)
        [vignetteFilter setVignetteEnd:5.0];
    
    [(GPUImageFilterGroup *)newFilter addFilter:cropFilter];
    [(GPUImageFilterGroup *)newFilter addFilter:brightFilter];
    [(GPUImageFilterGroup *)newFilter addFilter:contrastFilter];
    [(GPUImageFilterGroup *)newFilter addFilter:imageFilter];
    [(GPUImageFilterGroup *)newFilter addFilter:curveFilter];
    [(GPUImageFilterGroup *)newFilter addFilter:vignetteFilter];
    
    [cropFilter prepareForImageCapture];
    [brightFilter prepareForImageCapture];
    [contrastFilter prepareForImageCapture];
    [imageFilter prepareForImageCapture];
    [curveFilter prepareForImageCapture];
    [vignetteFilter prepareForImageCapture];
    
    [cropFilter addTarget:brightFilter];
    [brightFilter addTarget:contrastFilter];
    [contrastFilter addTarget:imageFilter];
    [imageFilter addTarget:curveFilter];
    [curveFilter addTarget:vignetteFilter];
    
    [(GPUImageFilterGroup *)newFilter setInitialFilters:[NSArray arrayWithObject:cropFilter]];
    [(GPUImageFilterGroup *)newFilter setTerminalFilter:vignetteFilter];
    
    [self.sourcePicture addTarget:imageFilter];
    
    [newFilter prepareForImageCapture];
    
    return newFilter;
}

- (GPUImageFilterGroup *)filterLomoWeirdFilter {
    GPUImageFilterGroup *newFilter;
    
    newFilter = [[GPUImageFilterGroup alloc] init];
    
    self.sourcePicture = [[GPUImagePicture alloc] initWithImage:[UIImage imageNamed:@"nashville.png"] smoothlyScaleOutput:YES];
    [self.sourcePicture processImage];
    
    GPUImageCropFilter *cropFilter = [[GPUImageCropFilter alloc] initWithCropRegion:CGRectMake(0.f, self.cropStartY, 1.f, self.cropEndY)];
    
    GPUImageBrightnessFilter *brightFilter = [[GPUImageBrightnessFilter alloc] init];
    [brightFilter setBrightness:0.1];
    GPUImageContrastFilter *contrastFilter = [[GPUImageContrastFilter alloc] init];
    [contrastFilter setContrast:1.5];
    
    GPUImageSoftLightBlendFilter *imageFilter = [[GPUImageSoftLightBlendFilter alloc] init];
    
    GPUImageToneCurveFilter *curveFilter = [[GPUImageToneCurveFilter alloc] init];
    [curveFilter setRedControlPoints:[NSArray arrayWithObjects:[NSValue valueWithCGPoint:CGPointMake(0.0, 0.0)], [NSValue valueWithCGPoint:CGPointMake(0.5, 0.95)], [NSValue valueWithCGPoint:CGPointMake(0.7, 1.0)], nil]];
    [curveFilter setBlueControlPoints:[NSArray arrayWithObjects:[NSValue valueWithCGPoint:CGPointMake(0.0, 0.0)], [NSValue valueWithCGPoint:CGPointMake(0.5, 0.95)], [NSValue valueWithCGPoint:CGPointMake(1.0, 0.85)], nil]];
    
    GPUImageVignetteFilter *vignetteFilter = [[GPUImageVignetteFilter alloc] init];
    if (self.vignetteMode == NO)
        [vignetteFilter setVignetteEnd:5.0];
    
    [(GPUImageFilterGroup *)newFilter addFilter:cropFilter];
    [(GPUImageFilterGroup *)newFilter addFilter:brightFilter];
    [(GPUImageFilterGroup *)newFilter addFilter:contrastFilter];
    [(GPUImageFilterGroup *)newFilter addFilter:imageFilter];
    [(GPUImageFilterGroup *)newFilter addFilter:curveFilter];
    [(GPUImageFilterGroup *)newFilter addFilter:vignetteFilter];
    
    [cropFilter prepareForImageCapture];
    [brightFilter prepareForImageCapture];
    [contrastFilter prepareForImageCapture];
    [imageFilter prepareForImageCapture];
    [curveFilter prepareForImageCapture];
    [vignetteFilter prepareForImageCapture];
    
    [cropFilter addTarget:brightFilter];
    [brightFilter addTarget:contrastFilter];
    [contrastFilter addTarget:imageFilter];
    [imageFilter addTarget:curveFilter];
    [curveFilter addTarget:vignetteFilter];
    
    [(GPUImageFilterGroup *)newFilter setInitialFilters:[NSArray arrayWithObject:cropFilter]];
    [(GPUImageFilterGroup *)newFilter setTerminalFilter:vignetteFilter];
    
    [self.sourcePicture addTarget:imageFilter];
    
    [newFilter prepareForImageCapture];
    
    return newFilter;
}

- (GPUImageFilterGroup *)filterSepiaFilter {
    GPUImageFilterGroup *newFilter;
    
    newFilter = [[GPUImageFilterGroup alloc] init];
    
    GPUImageCropFilter *cropFilter = [[GPUImageCropFilter alloc] initWithCropRegion:CGRectMake(0.f, self.cropStartY, 1.f, self.cropEndY)];
    
    GPUImageSepiaFilter *sepiaFilter = [[GPUImageSepiaFilter alloc] init];
    
    GPUImageVignetteFilter *vignetteFilter = [[GPUImageVignetteFilter alloc] init];
    if (self.vignetteMode == NO)
        [vignetteFilter setVignetteEnd:5.0];
    
    [(GPUImageFilterGroup *)newFilter addFilter:cropFilter];
    [(GPUImageFilterGroup *)newFilter addFilter:sepiaFilter];
    [(GPUImageFilterGroup *)newFilter addFilter:vignetteFilter];
    
    [cropFilter prepareForImageCapture];
    [sepiaFilter prepareForImageCapture];
    [vignetteFilter prepareForImageCapture];
    
    [cropFilter addTarget:sepiaFilter];
    [sepiaFilter addTarget:vignetteFilter];
    
    [(GPUImageFilterGroup *)newFilter setInitialFilters:[NSArray arrayWithObject:cropFilter]];
    [(GPUImageFilterGroup *)newFilter setTerminalFilter:vignetteFilter];
    
    [newFilter prepareForImageCapture];
    
    return newFilter;
}

- (GPUImageFilterGroup *)filterGrayFilter {
    GPUImageFilterGroup *newFilter;
    
    newFilter = [[GPUImageFilterGroup alloc] init];
    
    GPUImageCropFilter *cropFilter = [[GPUImageCropFilter alloc] initWithCropRegion:CGRectMake(0.f, self.cropStartY, 1.f, self.cropEndY)];
    
    GPUImageGrayscaleFilter *grayFilter = [[GPUImageGrayscaleFilter alloc] init];
    
    GPUImageBrightnessFilter *brightFilter = [[GPUImageBrightnessFilter alloc] init];
    [brightFilter setBrightness:0.1];
    
    GPUImageContrastFilter *contrastFilter = [[GPUImageContrastFilter alloc] init];
    [contrastFilter setContrast:1.5];
    
    GPUImageVignetteFilter *vignetteFilter = [[GPUImageVignetteFilter alloc] init];
    if (self.vignetteMode == NO)
        [vignetteFilter setVignetteEnd:5.0];
    
    [(GPUImageFilterGroup *)newFilter addFilter:cropFilter];
    [(GPUImageFilterGroup *)newFilter addFilter:grayFilter];
    [(GPUImageFilterGroup *)newFilter addFilter:brightFilter];
    [(GPUImageFilterGroup *)newFilter addFilter:contrastFilter];
    [(GPUImageFilterGroup *)newFilter addFilter:vignetteFilter];
    
    [cropFilter prepareForImageCapture];
    [grayFilter prepareForImageCapture];
    [brightFilter prepareForImageCapture];
    [contrastFilter prepareForImageCapture];
    [vignetteFilter prepareForImageCapture];
    
    [cropFilter addTarget:grayFilter];
    [grayFilter addTarget:brightFilter];
    [brightFilter addTarget:contrastFilter];
    [contrastFilter addTarget:vignetteFilter];
    
    [(GPUImageFilterGroup *)newFilter setInitialFilters:[NSArray arrayWithObject:cropFilter]];
    [(GPUImageFilterGroup *)newFilter setTerminalFilter:vignetteFilter];
    
    [newFilter prepareForImageCapture];
    
    return newFilter;
}

- (GPUImageFilterGroup *)filterIlford400Filter {
    GPUImageFilterGroup *newFilter;
    
    newFilter = [[GPUImageFilterGroup alloc] init];
    
    GPUImageCropFilter *cropFilter = [[GPUImageCropFilter alloc] initWithCropRegion:CGRectMake(0.f, self.cropStartY, 1.f, self.cropEndY)];
    
    GPUImageGrayscaleFilter *grayFilter = [[GPUImageGrayscaleFilter alloc] init];
    
    GPUImageContrastFilter *contrastFilter = [[GPUImageContrastFilter alloc] init];
    [contrastFilter setContrast:3.5];
    
    GPUImageVignetteFilter *vignetteFilter = [[GPUImageVignetteFilter alloc] init];
    if (self.vignetteMode == NO)
        [vignetteFilter setVignetteEnd:5.0];
    
    [(GPUImageFilterGroup *)newFilter addFilter:cropFilter];
    [(GPUImageFilterGroup *)newFilter addFilter:grayFilter];
    [(GPUImageFilterGroup *)newFilter addFilter:contrastFilter];
    [(GPUImageFilterGroup *)newFilter addFilter:vignetteFilter];
    
    [cropFilter prepareForImageCapture];
    [grayFilter prepareForImageCapture];
    [contrastFilter prepareForImageCapture];
    [vignetteFilter prepareForImageCapture];
    
    [cropFilter addTarget:grayFilter];
    [grayFilter addTarget:contrastFilter];
    [contrastFilter addTarget:vignetteFilter];
    
    [(GPUImageFilterGroup *)newFilter setInitialFilters:[NSArray arrayWithObject:cropFilter]];
    [(GPUImageFilterGroup *)newFilter setTerminalFilter:vignetteFilter];
    
    [newFilter prepareForImageCapture];
    
    return newFilter;
}

- (GPUImageFilterGroup *)filterSketchFilter {
    GPUImageFilterGroup *newFilter;
    
    newFilter = [[GPUImageFilterGroup alloc] init];
    
    GPUImageCropFilter *cropFilter = [[GPUImageCropFilter alloc] initWithCropRegion:CGRectMake(0.f, self.cropStartY, 1.f, self.cropEndY)];
    
    GPUImageSketchFilter *sketchFilter = [[GPUImageSketchFilter alloc] init];
    
    GPUImageVignetteFilter *vignetteFilter = [[GPUImageVignetteFilter alloc] init];
    if (self.vignetteMode == NO)
        [vignetteFilter setVignetteEnd:5.0];
    
    [(GPUImageFilterGroup *)newFilter addFilter:cropFilter];
    [(GPUImageFilterGroup *)newFilter addFilter:sketchFilter];
    [(GPUImageFilterGroup *)newFilter addFilter:vignetteFilter];
    
    [cropFilter prepareForImageCapture];
    [sketchFilter prepareForImageCapture];
    [vignetteFilter prepareForImageCapture];
    
    [cropFilter addTarget:sketchFilter];
    [sketchFilter addTarget:vignetteFilter];
    
    [(GPUImageFilterGroup *)newFilter setInitialFilters:[NSArray arrayWithObject:cropFilter]];
    [(GPUImageFilterGroup *)newFilter setTerminalFilter:vignetteFilter];
    
    [newFilter prepareForImageCapture];
    
    return newFilter;
}

- (GPUImageFilterGroup *)filterToonFilter {
    GPUImageFilterGroup *newFilter;
    
    newFilter = [[GPUImageFilterGroup alloc] init];
    
    GPUImageCropFilter *cropFilter = [[GPUImageCropFilter alloc] initWithCropRegion:CGRectMake(0.f, self.cropStartY, 1.f, self.cropEndY)];
    
    GPUImageToonFilter *toonFilter = [[GPUImageToonFilter alloc] init];
    
    GPUImageVignetteFilter *vignetteFilter = [[GPUImageVignetteFilter alloc] init];
    if (self.vignetteMode == NO)
        [vignetteFilter setVignetteEnd:5.0];
    
    [(GPUImageFilterGroup *)newFilter addFilter:cropFilter];
    [(GPUImageFilterGroup *)newFilter addFilter:toonFilter];
    [(GPUImageFilterGroup *)newFilter addFilter:vignetteFilter];
    
    [cropFilter prepareForImageCapture];
    [toonFilter prepareForImageCapture];
    [vignetteFilter prepareForImageCapture];
    
    [cropFilter addTarget:toonFilter];
    [toonFilter addTarget:vignetteFilter];
    
    [(GPUImageFilterGroup *)newFilter setInitialFilters:[NSArray arrayWithObject:cropFilter]];
    [(GPUImageFilterGroup *)newFilter setTerminalFilter:vignetteFilter];
    
    [newFilter prepareForImageCapture];
    
    return newFilter;
}

- (GPUImageFilterGroup *)filterInvertFilter {
    GPUImageFilterGroup *newFilter;
    
    newFilter = [[GPUImageFilterGroup alloc] init];
    
    GPUImageCropFilter *cropFilter = [[GPUImageCropFilter alloc] initWithCropRegion:CGRectMake(0.f, self.cropStartY, 1.f, self.cropEndY)];
    
    GPUImageColorInvertFilter *invertFilter = [[GPUImageColorInvertFilter alloc] init];
    
    GPUImageVignetteFilter *vignetteFilter = [[GPUImageVignetteFilter alloc] init];
    if (self.vignetteMode == NO)
        [vignetteFilter setVignetteEnd:5.0];
    
    [(GPUImageFilterGroup *)newFilter addFilter:cropFilter];
    [(GPUImageFilterGroup *)newFilter addFilter:invertFilter];
    [(GPUImageFilterGroup *)newFilter addFilter:vignetteFilter];
    
    [cropFilter prepareForImageCapture];
    [invertFilter prepareForImageCapture];
    [vignetteFilter prepareForImageCapture];
    
    [cropFilter addTarget:invertFilter];
    [invertFilter addTarget:vignetteFilter];
    
    [(GPUImageFilterGroup *)newFilter setInitialFilters:[NSArray arrayWithObject:cropFilter]];
    [(GPUImageFilterGroup *)newFilter setTerminalFilter:vignetteFilter];
    
    [newFilter prepareForImageCapture];
    
    return newFilter;
}

- (GPUImageFilterGroup *)filterEmbossFilter {
    GPUImageFilterGroup *newFilter;
    
    newFilter = [[GPUImageFilterGroup alloc] init];
    
    GPUImageCropFilter *cropFilter = [[GPUImageCropFilter alloc] initWithCropRegion:CGRectMake(0.f, self.cropStartY, 1.f, self.cropEndY)];
    
    GPUImageEmbossFilter *embossFilter = [[GPUImageEmbossFilter alloc] init];
    [embossFilter setIntensity:2.5];
    
    GPUImageVignetteFilter *vignetteFilter = [[GPUImageVignetteFilter alloc] init];
    if (self.vignetteMode == NO)
        [vignetteFilter setVignetteEnd:5.0];
    
    [(GPUImageFilterGroup *)newFilter addFilter:cropFilter];
    [(GPUImageFilterGroup *)newFilter addFilter:embossFilter];
    [(GPUImageFilterGroup *)newFilter addFilter:vignetteFilter];
    
    [cropFilter prepareForImageCapture];
    [embossFilter prepareForImageCapture];
    [vignetteFilter prepareForImageCapture];
    
    [cropFilter addTarget:embossFilter];
    [embossFilter addTarget:vignetteFilter];
    
    [(GPUImageFilterGroup *)newFilter setInitialFilters:[NSArray arrayWithObject:cropFilter]];
    [(GPUImageFilterGroup *)newFilter setTerminalFilter:vignetteFilter];
    
    [newFilter prepareForImageCapture];
    
    return newFilter;
}


- (GPUImageFilterGroup *)filterWoodenFilter {
    GPUImageFilterGroup *newFilter;
    
    newFilter = [[GPUImageFilterGroup alloc] init];
    
    GPUImageCropFilter *cropFilter = [[GPUImageCropFilter alloc] initWithCropRegion:CGRectMake(0.f, self.cropStartY, 1.f, self.cropEndY)];
    
    self.sourcePicture = [[GPUImagePicture alloc] initWithImage:[UIImage imageNamed:@"wooden.png"] smoothlyScaleOutput:YES];
    [self.sourcePicture processImage];
    
    GPUImageBrightnessFilter *brightFilter = [[GPUImageBrightnessFilter alloc] init];
    [brightFilter setBrightness:0.1];
    GPUImageContrastFilter *contrastFilter = [[GPUImageContrastFilter alloc] init];
    [contrastFilter setContrast:1.5];
    
    GPUImageSoftLightBlendFilter *imageFilter = [[GPUImageSoftLightBlendFilter alloc] init];
    
    GPUImageToneCurveFilter *curveFilter = [[GPUImageToneCurveFilter alloc] init];
    [curveFilter setRedControlPoints:[NSArray arrayWithObjects:[NSValue valueWithCGPoint:CGPointMake(0.0, 0.0)], [NSValue valueWithCGPoint:CGPointMake(0.5, 0.95)], [NSValue valueWithCGPoint:CGPointMake(0.7, 1.0)], nil]];
    [curveFilter setBlueControlPoints:[NSArray arrayWithObjects:[NSValue valueWithCGPoint:CGPointMake(0.0, 0.0)], [NSValue valueWithCGPoint:CGPointMake(0.5, 0.95)], [NSValue valueWithCGPoint:CGPointMake(1.0, 0.85)], nil]];
    
    GPUImageVignetteFilter *vignetteFilter = [[GPUImageVignetteFilter alloc] init];
    if (self.vignetteMode == NO)
        [vignetteFilter setVignetteEnd:5.0];
    
    [(GPUImageFilterGroup *)newFilter addFilter:cropFilter];
    [(GPUImageFilterGroup *)newFilter addFilter:brightFilter];
    [(GPUImageFilterGroup *)newFilter addFilter:contrastFilter];
    [(GPUImageFilterGroup *)newFilter addFilter:imageFilter];
    [(GPUImageFilterGroup *)newFilter addFilter:curveFilter];
    [(GPUImageFilterGroup *)newFilter addFilter:vignetteFilter];
    
    [cropFilter prepareForImageCapture];
    [brightFilter prepareForImageCapture];
    [contrastFilter prepareForImageCapture];
    [imageFilter prepareForImageCapture];
    [curveFilter prepareForImageCapture];
    [vignetteFilter prepareForImageCapture];
    
    [cropFilter addTarget:brightFilter];
    [brightFilter addTarget:contrastFilter];
    [contrastFilter addTarget:imageFilter];
    [imageFilter addTarget:curveFilter];
    [curveFilter addTarget:vignetteFilter];
    
    [(GPUImageFilterGroup *)newFilter setInitialFilters:[NSArray arrayWithObject:cropFilter]];
    [(GPUImageFilterGroup *)newFilter setTerminalFilter:vignetteFilter];
    
    [self.sourcePicture addTarget:imageFilter];
    
    [newFilter prepareForImageCapture];
    
    return newFilter;
}

#pragma mark -
#pragma mark Actions

- (void)saveSnapToRoll {
    [self.videoCamera capturePhotoAsImageProcessedUpToFilter:self.filter withCompletionHandler:^(UIImage *processedImage, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self sendToTheTarget:processedImage];
        });
    }];
}

- (void)timerCountDown:(NSNumber *)number
{
    int i = number.intValue;
    
    if (i == -1) {
        self.timerButton.hidden = YES;
        return;
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.timerButton setTitle:[[NSString alloc] initWithFormat:NSLocalizedString(@"%d sec", nil), i] forState:UIControlStateNormal];
        [self.timerButton setNeedsDisplay];
        self.timerButton.hidden = NO;
        
        if (i == 0) {
            [self saveSnapToRoll];
            [self performSelector:@selector(timerCountDown:) withObject:[NSNumber numberWithInt:i - 1] afterDelay:0.25];
        } else {
            [self performSelector:@selector(timerCountDown:) withObject:[NSNumber numberWithInt:i - 1] afterDelay:1.0];
        }
    });
}

- (IBAction)takeSnap:(id)sender {
    if (self.originalImage != nil) {
        [self sendToTheTarget:self.stillFilterView.image];
    } else if (self.timerMode == 0) {
        [self saveSnapToRoll];
    } else {
        [self timerCountDown:[NSNumber numberWithInt:self.timerMode]];
    }
}

- (IBAction)changeFilter:(id)sender {
    [self hideMenus];
    
    self.curMenuKind = 0;
    
    [self scrollMenuShow:NO forScroll:self.frameScrollView];
    CGRect rect = self.filterScrollView.frame;
    [self scrollMenuShow:(rect.origin.y == self.kMenuHideY) forScroll:self.filterScrollView];
}

- (IBAction)changeFrame:(id)sender {
    [self hideMenus];
    
    self.curMenuKind = 1;
    
    [self scrollMenuShow:NO forScroll:self.filterScrollView];
    CGRect rect = self.frameScrollView.frame;
    [self scrollMenuShow:(rect.origin.y == self.kMenuHideY) forScroll:self.frameScrollView];
}

- (void)setFlashMenuStatus {
    if (self.cameraPosition == AVCaptureDevicePositionFront) {
        self.flashButton.enabled = NO;
    } else {
        self.flashButton.enabled = [self hasFlash];
    }
}

- (IBAction)flipCamera:(id)sender {
    self.flashView.hidden = YES;
    self.timerView.hidden = YES;
    
    [self.videoCamera rotateCamera];
    if (self.cameraPosition == AVCaptureDevicePositionBack)
        self.cameraPosition = AVCaptureDevicePositionFront;
    else
        self.cameraPosition = AVCaptureDevicePositionBack;
    
    [self setFlashMenuStatus];
}

- (IBAction)changeFlashMode:(id)sender {
    self.timerView.hidden = YES;
    self.flashView.hidden = !self.flashView.hidden;
}

- (IBAction)flashNoFlash:(id)sender {
    self.flashMode = AVCaptureFlashModeOff;
    [self setFlash:self.flashMode];
    self.flashButton.image = self.imageNoFlash;
    self.flashView.hidden = YES;
}

- (IBAction)flashForceFlash:(id)sender {
    self.flashMode = AVCaptureFlashModeOn;
    [self setFlash:self.flashMode];
    self.flashButton.image = self.imageFlash;
    self.flashView.hidden = YES;
}

- (IBAction)flashAutoFlash:(id)sender {
    self.flashMode = AVCaptureFlashModeAuto;
    [self setFlash:self.flashMode];
    self.flashButton.image = self.imageAutoFlash;
    self.flashView.hidden = YES;
}

- (IBAction)selectFromRoll:(id)sender {
    if (self.originalImage != nil) {
        self.filmRollButton.image = [UIImage imageNamed:@"filmroll.png"];
        self.flipCameraButton.enabled = self.savedFlipMode;
        self.flashButton.enabled = self.savedFlashMode;
        self.timerBarButton.enabled = YES;
        
        self.originalImage = nil;
        self.stillFilterView.image = nil;
        [self setCameraFilter:self.filterNo];
        [self.videoCamera resumeCameraCapture];
        return;
    }
    
    UIImagePickerController *imagePickerController = [[UIImagePickerController alloc] init];
    
    [imagePickerController setSourceType:UIImagePickerControllerSourceTypePhotoLibrary];
    [imagePickerController setAllowsEditing:YES];
    [self presentViewController:imagePickerController animated:YES completion:^{
        
    }];
}

- (IBAction)changeTimerMode:(id)sender {
    self.flashView.hidden = YES;
    self.timerView.hidden = !self.timerView.hidden;
}

- (IBAction)changeVignette:(id)sender {
    self.vignetteMode = !self.vignetteMode;
    [self setCameraFilter:self.filterNo];
}

- (IBAction)applyTimerMode:(id)sender {
    self.timerView.hidden = YES;
    self.timerMode = ((UIView *)sender).tag;
    [self setTimerImage];
}

- (IBAction)cancelTimer:(id)sender {
    [self.timerButton setTitle:NSLocalizedString(@"Canceled", nil) forState:UIControlStateNormal];
    [self.timerButton setNeedsDisplay];
    
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    self.timerButton.hidden = YES;
}
@end
