//
//  IosAudioExampleAppDelegate.h
//  IosAudioExample
//
//  Created by Pete Goodliffe on 17/11/2010.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class IosAudioExampleViewController;

@interface IosAudioExampleAppDelegate : NSObject <UIApplicationDelegate>
{
    UIWindow *window;
    IosAudioExampleViewController *viewController;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet IosAudioExampleViewController *viewController;

@end

