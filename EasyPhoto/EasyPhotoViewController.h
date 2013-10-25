//
//  EasyPhotoViewController.h
//  EasyPhoto
//
//  Created by Sungju Kwon on 25/10/2013.
//  Copyright (c) 2013 Sungju Kwon. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <AssetsLibrary/AssetsLibrary.h>

#import "GPUImage.h"

@interface EasyPhotoViewController : UIViewController
@property (weak, nonatomic) IBOutlet GPUImageView *filterView;
@property (weak, nonatomic) IBOutlet UIImageView *stillFilterView;
@property (weak, nonatomic) IBOutlet UIImageView *frameView;
@property (weak, nonatomic) IBOutlet UIImageView *focusImageView;
@property (weak, nonatomic) IBOutlet UIImageView *toolBar;
@property (weak, nonatomic) IBOutlet UIView *flashView;
@property (weak, nonatomic) IBOutlet UIView *timerView;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *flipCameraButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *flashButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *filmRollButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *timerBarButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *vignetteButton;
@property (weak, nonatomic) IBOutlet UIButton *timerButton;


@end
