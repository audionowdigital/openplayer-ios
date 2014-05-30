//
//  libopus_Tests.m
//  libopus Tests
//
//  Created by Tyrone Trevorrow on 31/12/13.
//  Copyright (c) 2013 Xiph.org/Sudeium. All rights reserved.
//

#import <XCTest/XCTest.h>

int test_opus_api_main(int _argc, char **_argv);
int test_opus_decode_main(int _argc, char**_argv);
int test_opus_encode_main(int _argc, char **_argv);
int test_opus_padding_main(void);

@interface libopus_Tests : XCTestCase

@end

@implementation libopus_Tests

- (void) testOpusAPI
{
    char* argv[] = {"test_opus_api"};
    test_opus_api_main(1, argv);
}

- (void) testOpusDecode
{
    char* argv[] = {"test_opus_decode"};
    test_opus_decode_main(1, argv);
}

- (void) testOpusEncode
{
    char* argv[] = {"test_opus_encode"};
    test_opus_encode_main(1, argv);
}

- (void) testOpusPadding
{
    test_opus_padding_main();
}

@end
