//
//  StreamConnection.m
//  Open Player
//
//  Created by Catalin BORA on 29/05/14.
//  Copyright (c) 2014 Audio Now Digital. All rights reserved.
//

#import "StreamConnection.h"

@interface StreamConnection()
@property (atomic,strong) NSMutableData *internalBuffer;
@property (nonatomic,strong) NSURLConnection *connection;
@end

@implementation StreamConnection

-(void)podcastSize:(long long)value{
    if (_podcastSize == -1) {
        _podcastSize = value;
    }
}
// the queue
dispatch_queue_t queue;

-(id)initWithURL:(NSURL *)url error:(NSError **)error {

    self = [super init];
    if( self )
    {
        // create a simple GET request from the url
        NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
        [request setHTTPMethod:@"GET"];
        
        if(!request){
            NSString *domain = @"com.audio.now.requestError";
            NSString *desc = NSLocalizedString(@"Unable to create GET request", @"");
            NSDictionary *userInfo = @{ NSLocalizedDescriptionKey : desc };
            
             *error = [NSError errorWithDomain:domain
                                          code:-101
                                      userInfo:userInfo];
            return nil;
        }
        // init for the internal buffer
        self.internalBuffer = [[NSMutableData alloc] init];
        
        if(!self.internalBuffer) {
            NSString *domain = @"com.audio.now.internalBufferError";
            NSString *desc = NSLocalizedString(@"Unable to create internal buffer", @"");
            NSDictionary *userInfo = @{ NSLocalizedDescriptionKey : desc };
            
            *error = [NSError errorWithDomain:domain
                                         code:-102
                                     userInfo:userInfo];
            return nil;
        }
        
        // create an asincron connection from the request
        self.connection = [NSURLConnection connectionWithRequest:request delegate:self];
        
        if (!self.connection) {
            NSString *domain = @"com.audio.now.connectionError";
            NSString *desc = NSLocalizedString(@"Unable to create connection", @"");
            NSDictionary *userInfo = @{ NSLocalizedDescriptionKey : desc };
            
            *error = [NSError errorWithDomain:domain
                                         code:-103
                                     userInfo:userInfo];
            return nil;
        }
        
        // start the queue
        queue = dispatch_queue_create("com.audio.now.streaming", NULL);
        
        // start the connection
        [self.connection start];
        
        // set the podcast size to -1 = not initialized
        self.podcastSize = -1;
        
        return self;
        
    } else {
        return nil;
    }
    
    return nil;
}

-(NSData *)readAllBytesWithError:(NSError **)error{
    
    if (self.internalBuffer.length == 0) {
        NSString *domain = @"com.audio.now.emptyBuffer";
        NSString *desc = NSLocalizedString(@"Internal buffer is empty", @"");
        NSDictionary *userInfo = @{ NSLocalizedDescriptionKey : desc };
        
        *error = [NSError errorWithDomain:domain
                                     code:-101
                                 userInfo:userInfo];
        return nil;
    } else {
        
        __block NSData *returnBytes;
        dispatch_sync(queue, ^{
            // copy the internal buffer
            returnBytes = [self.internalBuffer copy];
            // empty the internal buffer
            self.internalBuffer.length = 0;
        });
       
        // return the copy of the buffer
        return returnBytes;
    }
    
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response{
    self.podcastSize = [response expectedContentLength];
}

-(void) connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    // add data to the internal buffer
    // do this in a syncronized queue
    dispatch_sync(queue, ^{
        [self.internalBuffer appendData:data];
    });
}

-(void)stopStream{
    //stop the stream
    [self.connection cancel];
}

@end
