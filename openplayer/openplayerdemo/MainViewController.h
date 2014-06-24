//
//  MainViewController.h
//  openplayer
//
//  Created by Florin Moisa on 03/06/14.
//  Copyright (c) 2014 AudioNowDigital. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OpenPlayer.h"

@interface MainViewController : UIViewController <IPlayerHandler, NSStreamDelegate>
{
     OpenPlayer *player;
    
    NSInputStream *inputStream;
    NSOutputStream *outputStream;
}

@property (weak, nonatomic) IBOutlet UILabel *urlLabel1;
@property (weak, nonatomic) IBOutlet UILabel *urlLabel2;
@property (weak, nonatomic) IBOutlet UILabel *infoLabel;
@property (weak, nonatomic) IBOutlet UIButton *playBtn;
@property (weak, nonatomic) IBOutlet UIButton *pauseBtn;
@property (weak, nonatomic) IBOutlet UIButton *stopBtn;

@property (weak, nonatomic) IBOutlet UISlider *seekBar;
@property (weak, nonatomic) IBOutlet UILabel *timeLabel;

@end
