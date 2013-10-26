//
//  SendPhotoViewController.h
//  EasyPhoto
//
//  Created by Sungju Kwon on 26/10/2013.
//  Copyright (c) 2013 Sungju Kwon. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SendPhotoViewController : UIViewController

@property (nonatomic) UIImage *photoImage;
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
- (IBAction)closeView:(id)sender;

@end
