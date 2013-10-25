//
//  EasyPhotoViewController.m
//  EasyPhoto
//
//  Created by Sungju Kwon on 25/10/2013.
//  Copyright (c) 2013 Sungju Kwon. All rights reserved.
//

#import "EasyPhotoViewController.h"

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

#define kMenuShowY  350
#define kMenuHideY  420
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
    
    self.filterScrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(kMenuX, kMenuHideY, kMenuWidth, kMenuHeight)];
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
    
    self.frameScrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(kMenuX, kMenuHideY, kMenuWidth, kMenuHeight)];
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
    [self.flashView viewWithTag:0].layer.cornerRadius = 8;
    
    self.imageNoFlash = [UIImage imageNamed:@"t_noflash.png"];
    self.imageAutoFlash = [UIImage imageNamed:@"t_autoflash.png"];
    self.imageFlash = [UIImage imageNamed:@"t_flash.png"];
    self.flashMode = AVCaptureFlashModeOff;
    
    self.imageTimerNo = [UIImage imageNamed:@"timerno.png"];
    self.imageTimer2 = [UIImage imageNamed:@"timer2.png"];
    self.imageTimer5 = [UIImage imageNamed:@"timer5.png"];
    self.imageTimer10 = [UIImage imageNamed:@"timer10.png"];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark -
#pragma mark Camera Setup
- (void)setupCamera {
    self.videoCamera = [[GPUImageStillCamera alloc]
                        initWithSessionPreset:AVCaptureSessionPresetHigh cameraPosition:self.cameraPosition];
    
    self.videoCamera.outputImageOrientation = UIInterfaceOrientationPortrait;
    
    /*
    [self loadConfig];
    [self setCameraFilter:self.filterNo];
    */
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

- (void)filterSelected:(UIButton *)button {
    int oldFilterNo = self.filterNo;
    self.filterNo = button.tag - 1;
    /*
    [self selectScrollMenu:self.filterScrollView fromFilter:oldFilterNo + 1 toFilter:self.filterNo + 1];
    [self setCameraFilter:self.filterNo];
     */
}

- (void)frameSelected:(UIButton *)button {
    int oldFrameNo = self.frameNo;
    self.frameNo = button.tag - 1;
    /*
    [self selectScrollMenu:self.frameScrollView fromFilter:oldFrameNo + 1 toFilter:self.frameNo + 1];
    [self setCameraFrame:self.frameNo];
     */
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


- (void)tapToAutoFocus:(UIGestureRecognizer *)gestureRecognizer
{
    /*
    [self hideMenus];
    [self scrollMenuShow:NO forScroll:self.frameScrollView];
    [self scrollMenuShow:NO forScroll:self.filterScrollView];
    
    CGPoint focusPoint = [gestureRecognizer locationInView:self.view];
    CGRect newLocation = self.focusImageView.frame;
    newLocation.origin.x = focusPoint.x - (newLocation.size.width / 2);
    newLocation.origin.y = focusPoint.y - (newLocation.size.height / 2);
    
    self.focusImageView.frame = newLocation;
    [self.focusImageView setHidden:NO];
    
    CGPoint tapPoint = [gestureRecognizer locationInView:self.frameView];
    CGPoint convertedFocusPoint = [self convertToPointOfInterestFromViewCoordinates:tapPoint];
    [self autoFocusAtPoint:convertedFocusPoint];
    
    [self performSelector:@selector(hideFocusImageView:) withObject:nil afterDelay:0.5];
     */
}

- (void)hideFocusImageView:(id)data {
    [self.focusImageView setHidden:YES];
}

@end
