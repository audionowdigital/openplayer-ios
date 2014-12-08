//
//  BarsViewController.h
//  openplayer
//
//  Created by Catalin-Andrei BORA on 12/4/14.
//  Copyright (c) 2014 AudioNowDigital. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface BarsViewController : UIView

- (id)initWithNumberOfBars:(int)numberOfBars;
- (void)updateBarsForArrayPointer:(short *)barArrayPointer;

@end
