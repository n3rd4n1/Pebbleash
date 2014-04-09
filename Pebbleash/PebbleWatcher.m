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
 * PebbleWatcher.m
 *
 *  Created on: Jan 24, 2014
 *      Author: Billy
 */

#import "PebbleWatcher.h"
#import <CoreBluetooth/CoreBluetooth.h>

#define PebbleServiceUUID   @"180A"

@interface PebbleWatcher () <CBCentralManagerDelegate, CBPeripheralDelegate>
{
    CBCentralManager *centralManager;
}

@property (assign) PebbleWatcherState state;
@property (retain) CBPeripheral *pebble;
@property (retain) NSTimer *connectRetryTimer;
@property (assign) NSInteger RSSI;
@end

@implementation PebbleWatcher
@synthesize state;
@synthesize delegate;
@synthesize pebble;
@synthesize connectRetryTimer;
@synthesize RSSI;

- (void)dealloc
{
    [centralManager dealloc];
    self.state = PebbleWatcherStateOff;
    [super dealloc];
}

- (id)initWithDelegate:(id<PebbleWatcherDelegate>)delegate_
{
    self = [super init];
    
    if(self != nil)
    {
        state = PebbleWatcherStateUnknown;
        self.state = PebbleWatcherStateOff;
        delegate = delegate_;
        centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
    }
    
    return self;
}

- (PebbleWatcherState)state
{
    return state;
}

- (void)setState:(PebbleWatcherState)state_
{
    if(state == PebbleWatcherStateOff)
        return;
    
    self.connectRetryTimer = nil;
    PebbleWatcherError error = PebbleWatcherOkay;
    
    if(state_ == PebbleWatcherStateIdle)
    {
        switch(centralManager.state)
        {
            case CBCentralManagerStateUnsupported:
                error = PebbleWatcherErrorUnsupported;
                
            case CBCentralManagerStateUnauthorized:
                if(centralManager.state == CBCentralManagerStateUnauthorized)
                    error = PebbleWatcherErrorUnauthorized;
                
                state = PebbleWatcherStateError;
                break;

            case CBCentralManagerStatePoweredOn:
                state = PebbleWatcherStateSearching;
                [self connect:nil];
                
                if(state != PebbleWatcherStateSearching)
                    return;
                
                break;
                
            default:
                state = PebbleWatcherStateIdle;
                break;
        }
    }
    else
    {
        state = state_;
    
        if(state == PebbleWatcherStateOff)
            self.pebble = nil;
    }
    
    if([delegate respondsToSelector:@selector(pebbleWatcher:didChangeState:error:)])
        [delegate pebbleWatcher:self didChangeState:state error:error];
}

- (NSTimer *)connectRetryTimer
{
    return connectRetryTimer;
}

- (void)setConnectRetryTimer:(NSTimer *)connectRetryTimer_
{
    [connectRetryTimer invalidate];
    
    if((connectRetryTimer = [connectRetryTimer_ retain]) != nil)
        [[NSRunLoop currentRunLoop] addTimer:connectRetryTimer forMode:NSRunLoopCommonModes];
}

- (CBPeripheral *)pebble
{
    return pebble;
}

- (void)setPebble:(CBPeripheral *)pebble_
{
    if(pebble != nil)
    {
        [centralManager cancelPeripheralConnection:pebble];
        [pebble release];
    }
    
    if((pebble = [pebble_ retain]) != nil)
    {
        [[NSUserDefaults standardUserDefaults] setObject:pebble.identifier.UUIDString forKey:@"Pebble"];
        pebble.delegate = self;
        self.state = PebbleWatcherStateConnecting;
        [centralManager connectPeripheral:pebble options:nil];
    }
}

- (void)connect:(id)sender
{
    self.connectRetryTimer = nil;
    
    if(state == PebbleWatcherStateSearching && centralManager.state == CBCentralManagerStatePoweredOn)
    {
        NSMutableArray *connectedPeripherals = [NSMutableArray array];
        
        for(CBPeripheral *peripheral in [NSArray arrayWithArray:[centralManager retrieveConnectedPeripheralsWithServices:@[ [CBUUID UUIDWithString:PebbleServiceUUID] ]]])
        {
            if([peripheral.name rangeOfString:@"Pebble" options:NSCaseInsensitiveSearch].location != NSNotFound)
                [connectedPeripherals addObject:peripheral];
        }
        
        if(connectedPeripherals.count < 1)
        {
            NSString *identifier = [[NSUserDefaults standardUserDefaults] objectForKey:@"Pebble"];
            
            if(identifier.length > 0)
                [connectedPeripherals addObjectsFromArray:[centralManager retrievePeripheralsWithIdentifiers:@[ [[[NSUUID alloc] initWithUUIDString:identifier] autorelease] ]]];
        }
        
        if(connectedPeripherals.count > 0)
            self.pebble = connectedPeripherals.lastObject;
        else
            self.connectRetryTimer = [NSTimer timerWithTimeInterval:1 target:self selector:@selector(connect:) userInfo:nil repeats:NO];
    }
}

- (void)start
{
    @synchronized(self)
    {
        if(state == PebbleWatcherStateOff)
        {
            state = PebbleWatcherStateUnknown;
            self.state = PebbleWatcherStateIdle;
        }
    }
}

- (void)stop
{
    @synchronized(self)
    {
        self.state = PebbleWatcherStateOff;
    }
}

- (NSInteger)RSSI
{
    return ((state == PebbleWatcherStateConnected) ? RSSI : InvalidRSSI);
}

- (void)setRSSI:(NSInteger)RSSI_
{
    RSSI = RSSI_;
}

// CBCentralManager

- (void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    self.state = PebbleWatcherStateIdle;
}

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{
    if([peripheral isEqual:pebble])
    {
        RSSI = InvalidRSSI;
        self.state = PebbleWatcherStateConnected;
        [peripheral readRSSI];
    }
    else
        [central cancelPeripheralConnection:peripheral];
}

- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    self.state = PebbleWatcherStateIdle;
}

- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    self.state = PebbleWatcherStateIdle;
}

// CBPeripheral

- (void)peripheralDidUpdateRSSI:(CBPeripheral *)peripheral error:(NSError *)error
{
    if(state == PebbleWatcherStateConnected)
    {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC), dispatch_get_main_queue(), ^(void) {
            if(state == PebbleWatcherStateConnected)
                [pebble readRSSI];
        });
        
        if(error == nil)
        {
            RSSI = pebble.RSSI.integerValue;
            
            if([delegate respondsToSelector:@selector(pebbleWatcher:didUpdateRSSI:)])
                [delegate pebbleWatcher:self didUpdateRSSI:RSSI];
        }
    }
}

@end
