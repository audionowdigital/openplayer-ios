//
//  CircularBuffer.h
//  openplayer
//
//  Created by Radu Motisan on 13/06/14.
//  Copyright (c) 2014 AudioNowDigital. All rights reserved.
//

#ifndef __openplayer__CircularBuffer__
#define __openplayer__CircularBuffer__


#define MAX_CIRCULAR_SIZE 1024*1024

class CircularBuffer {

    struct node {
        short val;
        node *next;
    };
    node *first, *last, *read, *write;
    
    void init() {
        for (int i = 0; i < MAX_CIRCULAR_SIZE; i++) {
            if (i == 0) {
                first = new node;
                first->val = 0;
                first->next = 0;
                last = first;
            } else {
                node *p = new node;
                p->val = 0;
                p->next = 0;
                last->next = p;
                last = p;
            }
        }
        tail->next = head;
        read = head;
        write = head;
    }
    
    void deinit() {
        p = first;
        while (p != 0) {
            node *c = p;
            p = p->next;
            delete c;
        }
    }
    
    void push(short *buf, int amount) {
        for (int i = 0; i < amount; i++) {
            write->val = buf[i];
            write = write->next;
        }
    }
    
    // we can optimize this by seeing where we are in regards to the original list "last" elem.
    int checkFilled() {
        //return write - head;
        node *c = first;
        int i = 0;
        while (c!=write) {
            c = c->next;
            i++;
        }
        return i;
    }
    
    int checkFillPercent() {
        return checkFilled() * 100 / MAX_CIRCULAR_SIZE;
    }
    
    // populate given buffer and return number of elements actually written
    int pull(short *buf, int amount) {
        int tocopy = min(amount, checkFilled);
        for (int i = 0; i < tocopy ; i++) {
            buf[i] = head->val;
            head = head->next;
        }
        return tocopy;
    }
    
};

#endif /* defined(__openplayer__CircularBuffer__) */
