//
//  BarsViewController.m
//  openplayer
//
//  Created by Catalin-Andrei BORA on 12/4/14.
//  Copyright (c) 2014 AudioNowDigital. All rights reserved.
//

#import "BarsViewController.h"
#include <Accelerate/Accelerate.h>

#define kWidth 15
#define kPadding 1
#define kHeight 70
#define kNumberOfBars 32
#define LOG_N 5

#define kRandomlyChosenMaxValue 15000

@implementation BarsViewController
{
    NSArray* barArray;
    double pointSize;
    FFTSetup fftSetup;
}

- (id)initWithNumberOfBars:(int)numberOfBars
{
    self = [super init];
    if (self) {
        
        self.frame = CGRectMake(0, 0, kPadding*kNumberOfBars/2+(kWidth*kNumberOfBars/2), kHeight);
        
        NSMutableArray* tempBarArray = [[NSMutableArray alloc]initWithCapacity:kNumberOfBars/2];
        
        for(int i=0;i<kNumberOfBars/2;i++){
            
            UIImageView* bar = [[UIImageView alloc]initWithFrame:CGRectMake(i*kWidth+i*kPadding, 0, kWidth, 1)];
            bar.backgroundColor = [UIColor blackColor];
            [self addSubview:bar];
            [tempBarArray addObject:bar];
            
        }
        
        barArray = [[NSArray alloc]initWithArray:tempBarArray];
        
        CGAffineTransform transform = CGAffineTransformMakeRotation(M_PI_2*2);
        self.transform = transform;
        
        fftSetup = vDSP_create_fftsetup(LOG_N, kFFTRadix2);
        
        pointSize = (float)kHeight / (float)kRandomlyChosenMaxValue;
        
    }
    return self;
}

-(void)updateBarsForArrayPointer:(short *)barArrayPointer {

    float *normalisedValues = [self applyFFTForArray:barArrayPointer andNumberOfValues:(kNumberOfBars*2)];
    
    dispatch_async(dispatch_get_main_queue(), ^{

        int i = 1;
        for(UIImageView* bar in barArray){
            CGRect rect = bar.frame;
            
            float normValue = normalisedValues[i] * pointSize;
//            NSLog(@" %d -  value:%f ",i, normValue);
            rect.size.height = normValue;
            
            if (normValue > kHeight) {
                rect.size.height = kHeight;
            }
            bar.frame = rect;
            i++;
        }
        free(normalisedValues);
    });
}

-(float *)applyFFTForArray:(short *)array andNumberOfValues:(int)N{

    // Buffers for real (time-domain) input and output signals.
    float *inputBuffer = calloc(N, sizeof(float));
    
    // Initialize the input buffer with a values from buffer
    for (int i=0; i<N; i++) {
        inputBuffer[i] = (float)array[i];
    }
    
    DSPSplitComplex tempSplitComplex;
    tempSplitComplex.realp = calloc(N/2, sizeof(float));
    tempSplitComplex.imagp = calloc(N/2, sizeof(float));
    
    // For polar coordinates
    float *mag = calloc(N/2, sizeof(float));
//    float *phase = calloc(N/2, sizeof(float));
    
    // ----------------------------------------------------------------
    // Forward FFT
    
    // Scramble-pack the real data into complex buffer in just the way that's
    // required by the real-to-complex FFT function that follows.
    vDSP_ctoz((DSPComplex*)inputBuffer, 2, &tempSplitComplex, 1, N/2);
    
    // Do real->complex forward FFT
    vDSP_fft_zrip(fftSetup, &tempSplitComplex, 1, LOG_N, kFFTDirection_Forward);
    
    // Print the complex spectrum. Note that since it's the FFT of a real signal,
    // the spectrum is conjugate symmetric, that is the negative frequency components
    // are complex conjugates of the positive frequencies. The real->complex FFT
    // therefore only gives us the positive half of the spectrum from bin 0 ("DC")
    // to bin N/2 (Nyquist frequency, i.e. half the sample rate). Typically with
    // audio code, you don't need to worry much about the DC and Nyquist values, as
    // they'll be very close to zero if you're doing everything else correctly.
    //
    // Bins 0 and N/2 both necessarily have zero phase, so in the packed format
    // only the real values are output, and these are stuffed into the real/imag components
    // of the first complex value (even though they are both in fact real values). Try
    // replacing BIN above with N/2 to see how sinusoid at Nyquist appears in the spectrum.
//    printf("\nSpectrum:\n");
//    for (int k = 0; k < N/2; k++)
//    {
//        printf("%3d\t%6.2f\t%6.2f\n", k, tempSplitComplex.realp[k], tempSplitComplex.imagp[k]);
//    }
    
    // ----------------------------------------------------------------
    // Convert from complex/rectangular (real, imaginary) coordinates
    // to polar (magnitude and phase) coordinates.
    
    // Compute magnitude and phase. Can also be done using vDSP_polar.
    // Note that when printing out the values below, we ignore bin zero, as the
    // real/complex values for bin zero in tempSplitComplex actually both correspond
    // to real spectrum values for bins 0 (DC) and N/2 (Nyquist) respectively.
    vDSP_zvabs(&tempSplitComplex, 1, mag, 1, N/2);
    //vDSP_zvphas(&tempSplitComplex, 1, phase, 1, N/2);
    
//    printf("\nMag / Phase:\n");
//    for (int k = 1; k < N/2; k++)
//    {
//        printf("%3d\t%6.2f\t%6.2f\n", k, mag[k], phase[k]);
//    }
    
    free(inputBuffer);
    free(tempSplitComplex.imagp);
    free(tempSplitComplex.realp);

    return mag;
}


@end
