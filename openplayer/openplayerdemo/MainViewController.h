//
//  MainViewController.h
//  openplayer
//
//  Created by Florin Moisa on 03/06/14.
//  Copyright (c) 2014 AudioNowDigital. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ANDOpenPlayer.h"

@interface MainViewController : UIViewController <IPlayerHandler>
{
    ANDOpenPlayer *player;
}

@property (strong, nonatomic) IBOutlet UILabel *urlLabel;
@property (strong, nonatomic) IBOutlet UILabel *infoLabel;
@property (weak, nonatomic) IBOutlet UIButton *initializeBtn;
@property (weak, nonatomic) IBOutlet UIButton *playBtn;
@property (weak, nonatomic) IBOutlet UIButton *pauseBtn;
@property (weak, nonatomic) IBOutlet UIButton *stopBtn;

@property (weak, nonatomic) IBOutlet UISlider *seekBar;

@end
