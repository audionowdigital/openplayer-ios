//
//  SecondController.h
//  Open Player
//
//  Created by Catalin BORA on 29/05/14.
//  Copyright (c) 2014 Audio Now Digital. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SecondController : UIViewController
@property (weak, nonatomic) IBOutlet UILabel *bufferSizeLabel;
@property (weak, nonatomic) IBOutlet UILabel *maxSizeLabel;
@property (weak, nonatomic) IBOutlet UITextField *seekValue;
@property (weak, nonatomic) IBOutlet UIProgressView *progreesBar;
@property double index;

@end
