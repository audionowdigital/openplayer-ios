//
//  Tools.h
//  openplayer
//
//  Created by Florin Moisa on 27/06/14.
//  Copyright (c) 2014 AudioNowDigital. All rights reserved.
//

#import <Foundation/Foundation.h>

#define DLog(fmt, ...) if (LOGS_ENABLED) { NSLog(fmt, ##__VA_ARGS__); }

BOOL LOGS_ENABLED;

@interface Tools : NSObject

@end
