//
//  IosAudioExampleAppDelegate.m
//  IosAudioExample
//
//  Created by Pete Goodliffe on 17/11/2010.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "IosAudioExampleAppDelegate.h"
#import "IosAudioExampleViewController.h"

@implementation IosAudioExampleAppDelegate

@synthesize window;
@synthesize viewController;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [self.window addSubview:viewController.view];
    [self.window makeKeyAndVisible];

	return YES;
}

- (void)dealloc
{
    [viewController release];
    [window release];
    [super dealloc];
}


@end
