//
//  SendPhotoViewController.m
//  EasyPhoto
//
//  Created by Sungju Kwon on 26/10/2013.
//  Copyright (c) 2013 Sungju Kwon. All rights reserved.
//

#import "SendPhotoViewController.h"

@interface SendPhotoViewController ()

@end

@implementation SendPhotoViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    self.imageView.image = self.photoImage;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)closeView:(id)sender {
    [self dismissViewControllerAnimated:YES completion:^{
    }];
}
@end
