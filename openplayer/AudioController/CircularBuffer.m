//
//  CircularBuffer.m
//  openplayer
//
//  Created by Radu Motisan on 16/06/14.
//  Copyright (c) 2014 AudioNowDigital. All rights reserved.
//

#import "CircularBuffer.h"

@implementation Node
@end

@implementation CircularBuffer

- (id) init {
    self = [super init];
    if (self) {
        for (int i = 0; i < MAX_CIRCULAR_SIZE; i++) {
          if (i == 0) {
              first = [[Node alloc]init];
              first.val = 0;
              first.next = 0;
              //first->val = 0;
              //first->next = 0;
              last = first;
          } else {
              Node *p = [[Node alloc]init];
              //p->val = 0;
              //p->next = 0;
              //last->next = p;
              p.val = 0;
              p.next = 0;
              last.next = p;
              last = p;
          }
        }
        //last->next = first;
        last.next = first;
        read = first;
        write = first;
        return self;
    }
    return nil;
}

-(void) deinit {
    Node *p = first;
    while (p != nil) {
        Node *c = p;
        //p = p->next;
        p = p.next;
        //delete c;
        //[c dealloc];
    }
}

-(void) push:(short *)buf amount:(int)amount {
    for (int i = 0; i < amount; i++) {
        //write->val = buf[i];
        //write = write->next;
        write.val = buf[i];
        write = write.next;
    }
}

// we can optimize this by seeing where we are in regards to the original list "last" elem.
-(int) checkFilled {
    //return write - head;
    Node *c = first;
   // NSLog(@"Node:%d %d", c, write);
    int i = 0;
    while (c != write) {
        //c = c->next;
        c = c.next;
        i++;
    }
   // NSLog(@" found it, %d", i);
    return i;
}

-(int)checkFillPercent {
    //return checkFilled() * 100 / MAX_CIRCULAR_SIZE;
    /*int filled = [self checkFilled];
    NSLog(@"ret %d", filled);
    int p = 100 * filled / MAX_CIRCULAR_SIZE;
    return p;*/
    return 100 * [self checkFilled] / MAX_CIRCULAR_SIZE;
}

// populate given buffer and return number of elements actually written
-(int) pull:(short *)buf amount:(int)amount {
    int tocopy = min(amount, [self checkFilled]);
    for (int i = 0; i < tocopy ; i++) {
        //buf[i] = first->val;
        //first = first->next;
        buf[i] = first.val;
        first = first.next;
    }
    return tocopy;
}



@end
