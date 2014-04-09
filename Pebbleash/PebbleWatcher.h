/*
 * The MIT License (MIT)
 *
 * Copyright (c) 2014 Billy Millare
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy of
 * this software and associated documentation files (the "Software"), to deal in
 * the Software without restriction, including without limitation the rights to
 * use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
 * the Software, and to permit persons to whom the Software is furnished to do so,
 * subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
 * FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
 * COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
 * IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
 * CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

/*
 * PebbleWatcher.h
 *
 *  Created on: Jan 24, 2014
 *      Author: Billy
 */

#import <Foundation/Foundation.h>
#import <limits.h>

#define InvalidRSSI (LONG_MIN)

typedef enum {
    PebbleWatcherOkay,
    PebbleWatcherErrorUnauthorized,
    PebbleWatcherErrorUnsupported
} PebbleWatcherError;

typedef enum {
    PebbleWatcherStateOff,          // switched-off
    PebbleWatcherStateUnknown,      // transition from off
    PebbleWatcherStateError,        // unauthorized to use bluetooth or device does not support bluetooth low energy
    PebbleWatcherStateIdle,         // bluetooth is currently off
    PebbleWatcherStateSearching,    // searching for a Pebble
    PebbleWatcherStateConnecting,   // connecting to a Pebble
    PebbleWatcherStateConnected     // connected to a Pebble
} PebbleWatcherState;

@class PebbleWatcher;
@protocol PebbleWatcherDelegate <NSObject>
- (void)pebbleWatcher:(PebbleWatcher *)pebbleWatcher didChangeState:(PebbleWatcherState)state error:(PebbleWatcherError)error;
- (void)pebbleWatcher:(PebbleWatcher *)pebbleWatcher didUpdateRSSI:(NSInteger)RSSI;
@end

@interface PebbleWatcher : NSObject
@property (readonly) PebbleWatcherState state;
@property (assign) id<PebbleWatcherDelegate> delegate;
@property (readonly) NSInteger RSSI;
- (id)initWithDelegate:(id<PebbleWatcherDelegate>)delegate;
- (void)start;
- (void)stop;
@end
