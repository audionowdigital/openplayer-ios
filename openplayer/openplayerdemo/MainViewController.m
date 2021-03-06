
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
    player = [[OpenPlayer alloc] initWithPlayerHandler:self typeOfPlayer:PLAYER_OPUS enableLogs:YES];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.

    NSString *dirPath = NSTemporaryDirectory();
    if (![[NSFileManager defaultManager] fileExistsAtPath:dirPath]){
        [[NSFileManager defaultManager] createDirectoryAtPath:dirPath withIntermediateDirectories:NO attributes:nil error:nil];
    }
    
//    file:///Users/fmoisa/Library/Application%20Support/iPhone%20Simulator/7.1/Applications/12F67313-D441-41FD-A502-6133C5802ED4/tmp/archangel.mp3
    
    NSString *file_path = @"file:///Users/fmoisa/Library/Application%20Support/iPhone%20Simulator/7.1/Applications/12F67313-D441-41FD-A502-6133C5802ED4/tmp/archangel.mp3";//[NSString stringWithFormat:@"file://%@archangel.mp3", dirPath];
    
    NSString *url1String =
    
    // vorbis live : don't forget to change player type to vorbis
    // @"http://revolutionradio.ru/live.ogg";                           // crash?
    // @"http://arvorig-fm.online.stalig.net/live-ori.ogg";             // crash link?
    // @"http://revolutionradio.ru:8000/live.ogg";                      // vorbis
    // @"http://icecast1.pulsradio.com:80/mxHD.ogg";
    // @http://ogg.ai-radio.org:8000/radio.ogg";

    // vorbis recording
//     @"http://www.markosoft.ro/test.ogg";
    
    
    // opus live : don't forget to change player type to opus
//     @"http://ai-radio.org:8000/radio.opus";                          // stereo ok
//     @"http://ice01.va.audionow.com:8000/PowerFMJamaicaopus.ogg";
//     @"http://repeater.xiph.org:8000/temporalfugue.opus";             // mono stream!!
    // @"http://repeater.xiph.org:8000/clock.opus";                     // stereo ok
//     @"http://ice01.va.audionow.com:8000/radioamericaopus.ogg";       // stereo opus ok.
    // @"http://icecast.timlradio.co.uk/ar64.opus";                     // not ok
    // @"http://icecast.timlradio.co.uk/ac96.opus";                     // not ok
//     @"http://radioserver1.delfa.net:80/256.opus";
//    @"http://ice01.va.audionow.com:8000/badopus.ogg";                   // bad Opus
    
//    @"http://178.79.149.242/uploads/16Hz-20kHz-Exp-1f-10sec.opus";

    // opus recording
//     @"http://www.markosoft.ro/opus/countdown.opus";
     @"http://www.markosoft.ro/opus/02_Archangel.opus";
//     @"http://www.pocketmagic.net/tmp3/Astral_Projection_-_06_-_People_Can_Fly_Delirious_.opus";
//     @"http://www.pocketmagic.net/tmp3/02_Archangel.opus";
//     @"http://www.pocketmagic.net/tmp3/05_All_Nightmare_Long.opus";
//     @"http://www.pocketmagic.net:80/tmp3/countdown.opus";
//    @"http://www24.online-convert.com/download-file/6d3fcf0c4581d8229bc7756a9d91bfef/converted-b9f3a021.opus";
    
   
    NSString *url2String =
//    @"http://markosoft.ro/test.ogg";
//     @"http://www.markosoft.ro/opus/02_Archangel.opus";
//    @"http://revolutionradio.ru:8000/live.ogg";
    @"http://178.79.149.242/uploads/16Hz-20kHz-Exp-1f-10sec.opus";
//    @"http://www.markosoft.ro/opus/02_Archangel.opus";


    self.urlLabel1.text = url1String;
    self.urlLabel2.text = url2String;
    self.infoLabel.text = @"Waiting for info";
    
   //[self initNetworkCommunication:url1String];
    
    //init bars controller
    self.barsController = [[BarsViewController alloc] initWithNumberOfBars:32];
    
    //position eq in the middle of the view
    CGRect frame = self.barsController.frame;
    frame.origin.x = (self.view.frame.size.width - self.barsController.frame.size.width)/2;
    frame.origin.y = (self.view.frame.size.height - self.barsController.frame.size.height) - 20;
    self.barsController.frame = frame;
    
    [self.view addSubview:self.barsController];
    
}

-  (void)initNetworkCommunication:(NSString*)urlStr1 {
    NSString *urlStr = @"http://www.markosoft.ro:80/opus/02_Archangel.opus";
    if (![urlStr isEqualToString:@""]) {
        NSURL *website = [NSURL URLWithString:urlStr];
        if (!website) {
            NSLog(@"%@ is not a valid URL");
            return;
            
        } else NSLog(@"%@ host, port: %@, path: %@", [website host], [website port], [website path]);
        
        CFReadStreamRef readStream;
        CFWriteStreamRef writeStream;
        CFStreamCreatePairWithSocketToHost(NULL, (__bridge CFStringRef)[website host], 80, &readStream, &writeStream);
        
        inputStream = (__bridge_transfer NSInputStream *)readStream;
        outputStream = (__bridge_transfer NSOutputStream *)writeStream;
        //[inputStream setDelegate:self];
        //[outputStream setDelegate:self];
        [inputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        [outputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        [inputStream open];
        [outputStream open];
        
        // wait for output stream to connect : TODO: implement Timeout and failure!
        double startTime = [NSDate timeIntervalSinceReferenceDate] * 1000.0;
        [NSThread sleepForTimeInterval:0.2];
        double stopTime = [NSDate timeIntervalSinceReferenceDate] * 1000.0;
        
        NSLog(@"dif: %d", (int)(stopTime - startTime));
        
        while ([outputStream streamStatus] != NSStreamStatusOpen) {
             [NSThread sleepForTimeInterval:0.1];
        }
        NSLog(@"connected");
        
        // do a HTTP Get on the resource we want
        NSString * str = [NSString stringWithFormat:@"GET %@ HTTP/1.0\r\n\r\n", [website path]];
        NSLog(@"Do get for: %@", str);
        const uint8_t * rawstring = (const uint8_t *)[str UTF8String];
        [outputStream write:rawstring maxLength:strlen(rawstring)];
        //[outputStream close];
        
        // wait for input stream to connect: probably already connected : TODO: implement Timeout and failure!
        while ([inputStream streamStatus] != NSStreamStatusOpen) {
            [NSThread sleepForTimeInterval:0.1];
        }
        
        // read header
        
        
        NSMutableString *strResult = [NSMutableString string];
        
        NSInteger result;
        int eoh = 0;
        uint8_t ch;
        while((result = [inputStream read:&ch maxLength:1]) != 0) {
            if(result > 0) {
                [strResult appendFormat:@"%c", ch];
                if (ch == '\r' || ch == '\n') eoh ++;
                else if (eoh > 0) eoh --;
                
                if (eoh == 4) {
                    NSLog(@"Res:%@", strResult);
                    exit(1);
                }
                
            } else {
                NSLog(@"Error %@", [inputStream streamError]);
            }
        }
        // test header data
      //  NSString *t1 = [strResult rangeOfString:@"\r\n"];
        
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)initBtn1Pressed:(id)sender {
    [player setDataSource:[NSURL URLWithString:self.urlLabel1.text] withSize:154];
}

- (IBAction)initBtn2Pressed:(id)sender {
    [player setDataSource:[NSURL URLWithString:self.urlLabel2.text]];
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

-(void)onPlayerEvent:(PlayerEvent)event {

}

// We just got the track info
-(void)onPlayerEvent:(PlayerEvent)event withParams:(NSDictionary *)params {

    NSLog(@"CLIENT: Player event received: %d", event);
    if (event == READING_HEADER) {
        NSLog(@"+++ READING_HEADER - player starting point");
    }
    if (event == READY_TO_PLAY) {
        NSLog(@"+++ READY_TO_PLAY - just press PLAY");
    }
    if (event == PLAY_UPDATE) {
        int progress =  [[params objectForKey:@"param"] intValue];
        NSLog(@"+++ PLAY_UPDATE track progress: %d", progress);
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            self.timeLabel.text =
            [NSString stringWithFormat:@"%d sec", progress];
            
            self.seekBar.maximumValue = 1;
            self.seekBar.minimumValue = 0;
            
            self.seekBar.value = (float) progress / 154;
        });
    }
    if (event == PLAY_BAR_UPDATE) {
        short * barStartPointers = (short *)[[params valueForKey:@"barStartPointers"] pointerValue];
        [self.barsController updateBarsForArrayPointer:barStartPointers];
    }
    if (event == TRACK_INFO) {
        NSString *vendor =  (NSString *)[params objectForKey:@"vendor"];
        NSString *title = (NSString *)[params objectForKey:@"title"];
        NSString *artist = (NSString *)[params objectForKey:@"artist"];
        NSString *album = (NSString *)[params objectForKey:@"album"];
        NSString *date = (NSString *)[params objectForKey:@"date"];
        NSString *track = (NSString *)[params objectForKey:@"track"];

        NSLog(@"+++ TRACK_INFO vendor:%@ title:%@ artist:%@ album:%@ date:%@ track:%@",
                                vendor, title, artist, album, date, track);
        // only the main thread can make changes to the User Interface
        dispatch_async(dispatch_get_main_queue(), ^{
            self.infoLabel.text =
            [NSString stringWithFormat:@"vendor:%@ title:%@ artist:%@ album:%@ date:%@ track:%@", vendor , title , artist , album , date , track];
        });
    }
    if (event == PLAYING_FAILED) {
        NSLog(@"+++ PLAYING_FAILED Playing stopped with error.");
    }
    if (event == PLAYING_FINISHED) {
        NSLog(@"+++ PLAYING_FINISHED Playing stopped with success.");
    }

}

- (IBAction)endScrubbing:(id)sender {
    [player seekToPercent:[(UISlider *)sender value]];
}



@end
