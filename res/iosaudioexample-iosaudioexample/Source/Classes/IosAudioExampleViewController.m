//
//  IosAudioExampleViewController.m
//  IosAudioExample
//
//  Created by Pete Goodliffe on 17/11/2010.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "IosAudioExampleViewController.h"

@interface UIApplication (ThingsWeAreNotAllowedToUse)
-(void) terminateWithSuccess;
@end

@implementation IosAudioExampleViewController

- (IBAction) pleaseMakeItStop:(id)sender
{
    // This is not an official API. You didn't see me...
    [[UIApplication sharedApplication] terminateWithSuccess];
}

@end
