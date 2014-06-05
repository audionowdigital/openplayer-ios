//
//  MainViewController.m
//  openplayer
//
//  Created by Florin Moisa on 03/06/14.
//  Copyright (c) 2014 AudioNowDigital. All rights reserved.
//

#import "MainViewController.h"


@interface MainViewController ()

@end

@implementation MainViewController

-(id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self initialize];
    }
    return self;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        [self initialize];
    }
    return self;
}

- (void)initialize
{
    player = [[Player alloc] initWithPlayerHandler:self typeOfPlayer:PLAYER_OPUS];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
//    @"http://ai-radio.org:8000/radio.opus";
//    @"http://www.markosoft.ro/opus/02_Archangel.opus"
//    @"http://www.markosoft.ro/opus/countdown.opus"
    
    NSString *urlString = @"http://ai-radio.org:8000/radio.opus";
    
    self.urlLabel.text = urlString;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)initBtnPressed:(id)sender {

    [player setDataSource:[NSURL URLWithString:self.urlLabel.text]];
}

- (IBAction)playBtnPressed:(id)sender {
    
    [player play];
}

- (IBAction)pauseBtnPressed:(id)sender {
    
    [player pause];
}

- (IBAction)stopBtnPressed:(id)sender {
    
    [player stop];
}


-(void)onPlayerEvent:(PlayerEvent)event withParams:(NSDictionary *)params {
    NSLog(@"Player event received in client.");
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
