//
//  Music.m
//  openplayer
//
//  Created by Florin Moisa on 30/05/14.
//  Copyright (c) 2014 AudioNowDigital. All rights reserved.
//

#import "Music.h"
#import "ToneGen.h"

@interface Music()
@property (nonatomic, readonly) ToneGen *toneGen;
@property (nonatomic, assign) int octive;
@property (nonatomic, assign) int tempo;
@property (nonatomic, assign) int length;

@property (nonatomic, strong) NSData *music;
@property (nonatomic, assign) int dataPos;
@property (nonatomic, assign) BOOL isPlaying;

- (void)playNote;
@end

@implementation Music
@synthesize toneGen = _toneGen;

- (ToneGen*)toneGen
{
    if (_toneGen == nil)
    {
        _toneGen = [[ToneGen alloc] init];
        _toneGen.delegate = self;
    }
    return _toneGen;
}
@synthesize octive = _octive;
- (void)setOctive:(int)octive
{
    // Sinity Check
    if (octive < 0)
        octive = 0;
    if (octive > 6)
        octive = 6;
    _octive = octive;
}
@synthesize tempo = _tempo;
- (void)setTempo:(int)tempo
{
    // Sinity Check
    if (tempo < 30)
        tempo = 30;
    if (tempo > 255)
        tempo = 255;
    _tempo = tempo;
}
@synthesize length = _length;
- (void)setLength:(int)length
{
    // Sinity Check
    if (length < 1)
        length = 1;
    if (length > 64)
        length = 64;
    _length = length;
}
@synthesize music = _music;
@synthesize dataPos = _dataPos;
@synthesize isPlaying = _isPlaying;


- (id)init
{
    self = [super init];
    if (self)
    {
        self.octive = 4;
        self.tempo = 120;
        self.length = 1;
        return self;
    }
    return nil;
}

- (void) play:(NSString *)music
{
    NSLog(@"%@", music);
    self.music = [[music stringByReplacingOccurrencesOfString:@"+" withString:@"#"]
                  dataUsingEncoding: NSASCIIStringEncoding];
    self.dataPos = 0;
    self.isPlaying = YES;
    [self playNote];
}

- (void)stop
{
    self.isPlaying = NO;
}

- (void)playNote
{
    if (!self.isPlaying)
        return;
    
    if (self.dataPos > self.music.length || self.music.length == 0) {
        self.isPlaying = NO;
        return;
    }
    
    unsigned char *data = (unsigned char*)[self.music bytes];
    unsigned int code = (unsigned int)data[self.dataPos];
    self.dataPos++;
    
    switch (code) {
        case 65: // A
        case 66: // B
        case 67: // C
        case 68: // D
        case 69: // E
        case 70: // F
        case 71: // G
        {
            // Peak at the next char to look for sharp or flat
            bool sharp = NO;
            bool flat = NO;
            if (self.dataPos < self.music.length) {
                unsigned int peak = (unsigned int)data[self.dataPos];
                if (peak == 35) // #
                {
                    self.dataPos++;
                    sharp = YES;
                }
                else if (peak == 45)  // -
                {
                    self.dataPos++;
                    flat = YES;
                }
            }
            
            // Peak ahead for a length changes
            bool look = YES;
            int count = 0;
            int newLength = 0;
            while (self.dataPos < self.music.length && look) {
                unsigned int peak = (unsigned int)data[self.dataPos];
                if (peak >= 48 && peak <= 57)
                {
                    peak -= 48;
                    int n = (count * 10);
                    if (n == 0) { n = 1; }
                    newLength += peak * n;
                    self.dataPos++;
                } else {
                    look = NO;
                }
            }
            
            // Pick the note length
            int length = self.length;
            if (newLength != 0)
            {
                NSLog(@"InlineLength: %d", newLength);
                length = newLength;
            }
            
            
            // Create the note string
            NSString *note = [NSString stringWithFormat:@"%c", code];
            if (sharp)
                note = [note stringByAppendingFormat:@"#"];
            else if (flat)
                note = [note stringByAppendingFormat:@"-"];
            
            // Set the tone generator freq
            [self setFreq:[self getNoteNumber:note]];
            
            // Play the note
            [self.toneGen play:(self.tempo / length)];
        }
            break;
            
        case 76: // L (length)
        {
            bool look = YES;
            int newLength = 0;
            while (self.dataPos < self.music.length && look) {
                unsigned int peak = (unsigned int)data[self.dataPos];
                if (peak >= 48 && peak <= 57)
                {
                    peak -= 48;
                    newLength = newLength * 10 + peak;
                    self.dataPos++;
                } else {
                    look = NO;
                }
            }
            self.length = newLength;
            NSLog(@"Length: %d", self.length);
            [self playNote];
        }
            break;
            
        case 79: // O (octive)
        {
            bool look = YES;
            int newOctive = 0;
            while (self.dataPos < self.music.length && look) {
                unsigned int peak = (unsigned int)data[self.dataPos];
                if (peak >= 48 && peak <= 57)
                {
                    peak -= 48;
                    newOctive = newOctive * 10 + peak;
                    self.dataPos++;
                } else {
                    look = NO;
                }
            }
            self.octive = newOctive;
            NSLog(@"Octive: %d", self.self.octive);
            [self playNote];
        }
            break;
            
        case 84: // T (tempo)
        {
            bool look = YES;
            int newTempo = 0;
            while (self.dataPos < self.music.length && look) {
                unsigned int peak = (unsigned int)data[self.dataPos];
                if (peak >= 48 && peak <= 57)
                {
                    peak -= 48;
                    newTempo = newTempo * 10 + peak;
                    self.dataPos++;
                } else {
                    look = NO;
                }
            }
            self.tempo = newTempo;
            NSLog(@"Tempo: %d", self.self.tempo);
            [self playNote];
        }
            break;
            
        default:
            [self playNote];
            break;
    }
}


- (int)getNoteNumber:(NSString*)note
{
    note = [note uppercaseString];
    NSLog(@"%@", note);
    
    if ([note isEqualToString:@"A"])
        return 0;
    else if ([note isEqualToString:@"A#"] || [note isEqualToString:@"B-"])
        return 1;
    else if ([note isEqualToString:@"B"] || [note isEqualToString:@"C-"])
        return 2;
    else if ([note isEqualToString:@"C"] || [note isEqualToString:@"B#"])
        return 3;
    else if ([note isEqualToString:@"C#"] || [note isEqualToString:@"D-"])
        return 4;
    else if ([note isEqualToString:@"D"])
        return 5;
    else if ([note isEqualToString:@"D#"] || [note isEqualToString:@"E-"])
        return 6;
    else if ([note isEqualToString:@"E"] || [note isEqualToString:@"F-"])
        return 7;
    else if ([note isEqualToString:@"F"] || [note isEqualToString:@"E#"])
        return 8;
    else if ([note isEqualToString:@"F#"] || [note isEqualToString:@"G-"])
        return 9;
    else if ([note isEqualToString:@"G"])
        return 10;
    else if ([note isEqualToString:@"G#"])
        return 11;
    
    return 0;
}

- (void)setFreq:(int)note
{
    float a = powf(2, self.octive);
    float b = powf(1.059463, note);
    float freq = roundf((275.0 * a * b) / 10);
    self.toneGen.frequency = freq;
}

- (void)toneStop
{
    [self playNote];
}

@end
