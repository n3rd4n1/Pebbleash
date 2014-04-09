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
 * PebbleashViewController.m
 *
 *  Created on: Jan 24, 2014
 *      Author: Billy
 */

#import "PebbleashViewController.h"
#import <QuartzCore/QuartzCore.h>
#import <CoreLocation/CoreLocation.h>
#import "AlertControl.h"
#import "PebbleWatcher.h"
#import "ApplicationStatus.h"
#import "Switch.h"

#define UserDefaultsAlertMessagesKey        @"AlertMessages"
#define UserDefaultsPebbleColorKey          @"PebbleColor"
#define UserDefaultsAlertTriggerLevelKey    @"AlertTriggerLevel"

enum {
    RedPebble,
    BlackPebble,
    GreyPebble,
    OrangePebble,
    WhitePebble,
    InvalidPebbleColor
};

@interface PebbleashViewController () <CLLocationManagerDelegate, UITextViewDelegate, UIScrollViewDelegate, PebbleWatcherDelegate>
{
    NSInteger pebbleColor;
    NSTimer *pebbleBacklightOffTimer;
    NSTimer *pebbleTimeUpdateTimer;
    CLLocationManager *locationManager;
    PebbleWatcher *pebbleWatcher;
    UILocalNotification *localNotification;
    BOOL alertMessageTextViewIsEditing;
    BOOL alertMessageTextViewIsAnimating;
    NSMutableArray *alertMessages;
    NSInteger previousRSSI;
    NSInteger numberOfConsecutiveTriggers;
    
    IBOutlet UIButton *aboutShowButton;
    IBOutlet UIView *containerView;
    IBOutlet UIImageView *pebbleImageView;
    IBOutlet Switch *pebbleWatcherSwitch;
    IBOutlet UIButton *pebbleLocateButton;
    IBOutlet UIView *pebbleBacklightView;
    IBOutlet UIView *pebbleWatchfaceContainer;
    IBOutlet UIView *pebbleWatchface1View;
    IBOutlet UILabel *pebbleWatchface1HourLabel;
    IBOutlet UILabel *pebbleWatchface1Minute1Label;
    IBOutlet UILabel *pebbleWatchface1Minute2Label;
    IBOutlet UIView *pebbleWatchface2View;
    IBOutlet UILabel *pebbleWatchface2HourLabel;
    IBOutlet UILabel *pebbleWatchface2MinuteLabel;
    IBOutlet AlertControl *alertControl;
    IBOutlet UITextView *alertMessageTextView;
    IBOutlet UIView *alertMessageTextViewBackground;
    IBOutlet UIImageView *defaultImageView;
}

@property (assign) BOOL locationManagerIsActive;
@property (retain) NSDate *lastAlertDate;
@end

@implementation PebbleashViewController
@synthesize locationManagerIsActive;
@synthesize lastAlertDate;

- (void)dealloc
{
    [pebbleBacklightOffTimer invalidate];
    [pebbleTimeUpdateTimer invalidate];
    [locationManager release];
    [pebbleWatcher release];
    [localNotification release];
    [alertMessages release];
    self.lastAlertDate = nil;
    
    [aboutShowButton release];
    [containerView release];
    [pebbleImageView release];
    [pebbleWatcherSwitch release];
    [pebbleLocateButton release];
    [pebbleBacklightView release];
    [pebbleWatchfaceContainer release];
    [pebbleWatchface1View release];
    [pebbleWatchface1HourLabel release];
    [pebbleWatchface1Minute1Label release];
    [pebbleWatchface1Minute2Label release];
    [pebbleWatchface2View release];
    [pebbleWatchface2HourLabel release];
    [pebbleWatchface2MinuteLabel release];
    [alertControl release];
    [alertMessageTextView release];
    [alertMessageTextViewBackground release];
    [defaultImageView release];

    [super dealloc];
}

- (void)viewWillAppear:(BOOL)animated
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    CGRect frame;
    
    alertMessageTextViewIsEditing = NO;
    alertMessageTextViewIsAnimating = NO;
    
    alertMessages = [[NSMutableArray alloc] initWithCapacity:10];
    [alertMessages addObjectsFromArray:[userDefaults arrayForKey:UserDefaultsAlertMessagesKey]];
    
    if(alertMessages.count < 1)
        [alertMessages addObjectsFromArray:@[ @"Peeeeeeeeeeebble!", @"Hey! Where are you going?", @"Leave me, you shall not!", @"Please don't leave me!" ]];
    
    alertMessageTextView.text = alertMessages.lastObject;
    
    pebbleWatcherSwitch.on = NO;
    
    pebbleLocateButton.transform = CGAffineTransformMakeRotation(-M_PI_2);
    frame = pebbleLocateButton.superview.bounds;
    frame.origin.x = 10;
    pebbleLocateButton.frame = frame;
    
    [self setPebbleColor:[userDefaults integerForKey:UserDefaultsPebbleColorKey]];
    
    alertControl.triggerLevel = [userDefaults floatForKey:UserDefaultsAlertTriggerLevelKey];
    
    locationManager = [CLLocationManager new];
    locationManager.distanceFilter = 3000;
    locationManager.desiredAccuracy = kCLLocationAccuracyThreeKilometers;
    locationManager.delegate = self;
    locationManager.activityType = CLActivityTypeFitness;
    locationManager.pausesLocationUpdatesAutomatically = YES;
    [locationManager startUpdatingLocation];
    [locationManager stopUpdatingLocation];
    self.locationManagerIsActive = NO;
    
    pebbleWatcher = [[PebbleWatcher alloc] initWithDelegate:self];
    
    localNotification = [UILocalNotification new];
    
    defaultImageView.image = [UIImage imageNamed:((defaultImageView.bounds.size.height == 568) ? @"Default-568h" : @"Default")];
}

- (void)viewDidAppear:(BOOL)animated
{
    [NSThread sleepForTimeInterval:1];
    
    [UIView transitionFromView:defaultImageView toView:defaultImageView duration:1.2 options:UIViewAnimationOptionTransitionFlipFromRight completion:^(BOOL finished) {
        [defaultImageView removeFromSuperview];
        [self turnOnPebbleBacklight:nil];
        [self updatePebbleTime:nil];
    }];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.4 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^(void){
        aboutShowButton.hidden = NO;
    
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.4 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^(void){
            aboutShowButton.hidden = YES;
        });
    });
}

- (void)sleep
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setObject:alertMessages forKey:UserDefaultsAlertMessagesKey];
    [userDefaults setInteger:pebbleColor forKey:UserDefaultsPebbleColorKey];
    [userDefaults setFloat:alertControl.triggerLevel forKey:UserDefaultsAlertTriggerLevelKey];

    self.locationManagerIsActive = locationManagerIsActive;
}

- (void)wake
{
    self.locationManagerIsActive = locationManagerIsActive;
}

// About

- (IBAction)showAbout:(UIButton *)sender
{
    if(!sender.hidden)
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://github.com/n3rd4n1"]];
}

// Location

- (BOOL)locationManagerIsActive
{
    return locationManagerIsActive;
}

- (void)setLocationManagerIsActive:(BOOL)locationManagerIsActive_
{
    pebbleWatcherSwitch.alert = !(locationManagerIsActive = locationManagerIsActive_);

    if(!locationManagerIsActive || pebbleWatcher.state == PebbleWatcherStateOff)
        SetDisabled();
    else if(pebbleWatcher.state == PebbleWatcherStateConnected)
        SetConnected();
    else
        SetDisconnected();
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
    self.locationManagerIsActive = YES;
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    self.locationManagerIsActive = NO;
}

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
    if(status == kCLAuthorizationStatusDenied || status == kCLAuthorizationStatusRestricted)
        self.locationManagerIsActive = NO;
}

- (void)locationManagerDidPauseLocationUpdates:(CLLocationManager *)manager
{
    [manager stopUpdatingLocation];
    [manager startUpdatingLocation];
}

// Pebble Color

static const unsigned int pebbleColors[] = {
    0x801721, // red
    0x181818, // black
    0x808080, // grey
    0xe34a2c, // orange
    0xe0e0e0  // white
};

#define ColorComponent(color, component)    ((CGFloat)((pebbleColors[color] >> (component * 8)) & 0xff) / 0xff)
#define PebbleColor(color)                  [UIColor colorWithRed:ColorComponent(color, 2) green:ColorComponent(color, 1) blue:ColorComponent(color, 0) alpha:1]

- (void)setPebbleColor:(NSInteger)color
{
    static const char *colorName[] = {
        "red",
        "black",
        "grey",
        "orange",
        "white"
    };
    
    pebbleImageView.image = [UIImage imageNamed:[NSString stringWithFormat:@"pebble-%s.png", colorName[color]]];
    
    UIColor *color_ = PebbleColor(color);
    [pebbleLocateButton setTitleColor:[color_ colorWithAlphaComponent:0.9] forState:UIControlStateNormal];
    [pebbleLocateButton setTitleColor:[color_ colorWithAlphaComponent:0.5] forState:UIControlStateHighlighted];

    pebbleColor = color;
}

- (IBAction)changePebbleColor:(id)sender
{
    if(++pebbleColor == InvalidPebbleColor)
        pebbleColor = RedPebble;
    
    [self setPebbleColor:pebbleColor];
}

// Pebble Backlight

- (void)turnOffPebbleBacklight:(id)sender
{
    pebbleBacklightOffTimer = nil;
    
    [UIView animateWithDuration:0.8 animations:^{
        pebbleBacklightView.alpha = 0.85;
    }];
}

- (IBAction)turnOnPebbleBacklight:(id)sender
{
    [pebbleBacklightOffTimer invalidate];
    pebbleBacklightOffTimer = [NSTimer timerWithTimeInterval:4 target:self selector:@selector(turnOffPebbleBacklight:) userInfo:nil repeats:NO];
    [[NSRunLoop mainRunLoop] addTimer:pebbleBacklightOffTimer forMode:NSRunLoopCommonModes];
    
    [UIView animateWithDuration:0.3 animations:^{
        pebbleBacklightView.alpha = 0;
    }];
}

- (void)motionBegan:(UIEventSubtype)motion withEvent:(UIEvent *)event
{
    if(motion == UIEventSubtypeMotionShake)
        [self turnOnPebbleBacklight:nil];
}

// Pebble Watchface

- (NSString *)wordFromTime:(NSInteger)time
{
    static const char *timeWords[] = {
        "o'clock",
        "one",
        "two",
        "three",
        "four",
        "five",
        "six",
        "seven",
        "eight",
        "nine",
        "ten",
        
        "eleven",
        "twelve",
        "thirteen",
        "four teen",
        "fifteen",
        "six teen",
        "seven teen",
        "eight teen",
        "nine teen",
        
        "twenty",
        "thirty",
        "forty",
        "fifty"
    };
    
    NSMutableString *word = [NSMutableString string];
    
    if(time > 19)
    {
        word.string = [NSString stringWithUTF8String:timeWords[time / 10 + 18]];
    
        if((time %= 10) == 0)
            return word;
        
        [word appendString:@" "];
    }
    
    [word appendString:[NSString stringWithUTF8String:timeWords[time]]];
    return word;
}

- (void)updatePebbleWatchface1:(NSArray *)time
{
    NSMutableArray *words = [NSMutableArray arrayWithObject:[self wordFromTime:[time.firstObject integerValue]]];
    [words addObjectsFromArray:[[self wordFromTime:[[time objectAtIndex:1] integerValue]] componentsSeparatedByString:@" "]];

    if(words.count < 3)
        [words addObject:@""];
    
    NSString *word;
    int i = 0;
    CGFloat xTranslation = pebbleWatchface1View.frame.size.width;
    NSTimeInterval delay = 0;
    
    for(UILabel *label in pebbleWatchface1View.subviews)
    {
        word = [words objectAtIndex:i++];

        if(![label.text isEqualToString:word])
        {
            [UIView animateWithDuration:([label.text isEqualToString:@""] ? 0.05 : 0.4) delay:delay options:0 animations:^{
                label.transform = CGAffineTransformMakeTranslation(-xTranslation, 0);
            } completion:^(BOOL finished) {
                label.transform = CGAffineTransformMakeTranslation(xTranslation, 0);
                label.text = word;
                
                [UIView animateWithDuration:0.4 delay:0 options:0 animations:^{
                    label.transform = CGAffineTransformIdentity;
                } completion:nil];
            }];
            
            delay += 0.2;
        }
    }
}

- (void)updatePebbleWatchface2:(NSArray *)time
{
    pebbleWatchface2HourLabel.text = time.firstObject;
    pebbleWatchface2MinuteLabel.text = [time objectAtIndex:1];
}

- (void)updatePebbleTime:(id)sender
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter new] autorelease];
    dateFormatter.dateFormat = @"h:mm:s";
    dateFormatter.timeZone = [NSTimeZone systemTimeZone];
    NSArray *time = [[dateFormatter stringFromDate:[NSDate date]] componentsSeparatedByString:@":"];
 
    pebbleTimeUpdateTimer = [NSTimer timerWithTimeInterval:(60 - [time.lastObject integerValue]) target:self selector:@selector(updatePebbleTime:) userInfo:nil repeats:NO];
    [[NSRunLoop mainRunLoop] addTimer:pebbleTimeUpdateTimer forMode:NSRunLoopCommonModes];
    
    [self updatePebbleWatchface1:time];
    [self updatePebbleWatchface2:time];
}

- (IBAction)changePebbleWatchface:(UISwipeGestureRecognizer *)sender
{
    sender.view.userInteractionEnabled = NO;
    [self turnOnPebbleBacklight:nil];
    
    UIView *watchface = pebbleWatchfaceContainer.subviews.firstObject;
    watchface.transform = CGAffineTransformMakeTranslation(0, (sender.direction == UISwipeGestureRecognizerDirectionUp) ? watchface.bounds.size.height : -watchface.bounds.size.height);
    [pebbleWatchfaceContainer addSubview:watchface];
    
    [UIView animateWithDuration:0.2 delay:0 options:UIViewAnimationOptionCurveLinear animations:^{
        watchface.transform = CGAffineTransformIdentity;
    } completion:^(BOOL finished) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC / 3), dispatch_get_main_queue(), ^{
            sender.view.userInteractionEnabled = YES;
        });
    }];
}

// Alert Message

- (IBAction)hideKeyboard:(id)sender
{
    [self.view endEditing:YES];
}

- (BOOL)textViewShouldBeginEditing:(UITextView *)textView
{
    if(alertMessageTextViewIsAnimating)
        return NO;
    
    alertMessageTextViewIsEditing = YES;
    alertMessageTextViewBackground.hidden = NO;
    
    [UIView animateWithDuration:0.2 animations:^{
        textView.transform = CGAffineTransformMakeTranslation(-3, 3);
        textView.backgroundColor = [UIColor colorWithWhite:0.05 alpha:1];
        alertMessageTextViewBackground.alpha = 0.90;
    }];
    
    return YES;
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    if(![text canBeConvertedToEncoding:NSASCIIStringEncoding])
        return NO;
    
    NSString *newReplacementText = [text stringByReplacingOccurrencesOfString:@"\n" withString:@" "];
    
    if([newReplacementText isEqualToString:text])
        return YES;
    
    if(text.length == 1)
        [self hideKeyboard:nil];
    else
    {
        textView.text = [textView.text stringByReplacingCharactersInRange:range withString:newReplacementText];
        textView.selectedRange = NSMakeRange(range.location + newReplacementText.length, 0);
    }
    
    return NO;
}

- (BOOL)textViewShouldEndEditing:(UITextView *)textView
{
    if([textView.text isEqualToString:@""])
        textView.text = @"...";
    
    [alertMessages removeObject:textView.text];
    [alertMessages addObject:textView.text];
    
    if(alertMessages.count > 10)
        [alertMessages removeObjectAtIndex:0];

    [textView scrollRangeToVisible:NSMakeRange(0, 0)];
    
    [UIView animateWithDuration:0.2 animations:^{
        textView.transform = CGAffineTransformIdentity;
        textView.backgroundColor = [UIColor blackColor];
        alertMessageTextViewBackground.alpha = 0;
    } completion:^(BOOL finished) {
        alertMessageTextViewBackground.hidden = YES;
    }];
    
    alertMessageTextViewIsEditing = NO;
    return YES;
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if(!alertMessageTextViewIsEditing)
    {
        UITextView *textView = (UITextView *)scrollView;
        CGFloat alpha = 1 - (abs(scrollView.contentOffset.y) / (scrollView.bounds.size.height * 0.4));
        
        if(!alertMessageTextViewIsAnimating)
        {
            if(scrollView.contentOffset.y > 0 && (scrollView.contentSize.height > scrollView.bounds.size.height))
                alpha = 1 - ((scrollView.bounds.size.height - (scrollView.contentSize.height - scrollView.contentOffset.y)) / (scrollView.bounds.size.height * 0.4));
            
            if(alpha < 0.2)
            {
                alertMessageTextViewIsAnimating = YES;
                
                if(scrollView.contentOffset.y < 0)
                {
                    textView.text = alertMessages.firstObject;
                    [alertMessages removeObjectAtIndex:0];
                    [alertMessages addObject:textView.text];
                }
                else
                {
                    [alertMessages insertObject:alertMessages.lastObject atIndex:0];
                    [alertMessages removeLastObject];
                    textView.text = alertMessages.lastObject;
                }
                
                CGPoint contentOffset = CGPointMake(0, (scrollView.contentOffset.y < 0) ? (textView.contentSize.height + 5) : -(textView.bounds.size.height + 5));
                
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC / 600), dispatch_get_main_queue(), ^{
                    scrollView.panGestureRecognizer.enabled = NO;
                    scrollView.contentOffset = contentOffset;
                    [scrollView setContentOffset:CGPointZero animated:YES];
                });
            }
        }
        
        textView.textColor = [textView.textColor colorWithAlphaComponent:alpha];
    }
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView
{
    scrollView.panGestureRecognizer.enabled = YES;
    alertMessageTextViewIsAnimating = NO;
}

- (void)sendAlertMessage:(NSString *)message
{
    localNotification.alertBody = message;
    [[UIApplication sharedApplication] presentLocalNotificationNow:localNotification];
}

// Pebble Locator

- (IBAction)locatePebble:(id)sender
{
    [self sendAlertMessage:@"Pebble!"];
}

// Pebble Watcher

- (IBAction)turnOnPebbleWatcher:(Switch *)sender
{
    if(sender.on)
    {
        [locationManager startUpdatingLocation];
        [pebbleWatcher start];
    }
    else
        [pebbleWatcher stop];
}

- (void)pebbleWatcher:(PebbleWatcher *)pebbleWatcher_ didChangeState:(PebbleWatcherState)state error:(PebbleWatcherError)error
{
    if(state == PebbleWatcherStateConnected)
    {
        previousRSSI = InvalidRSSI;
        numberOfConsecutiveTriggers = 0;
        self.lastAlertDate = nil;
        pebbleLocateButton.enabled = YES;
        pebbleWatcherSwitch.indicatorLevel = 1;
        SetConnected();
    }
    else
    {
        alertControl.currentLevel = 0;
        pebbleLocateButton.enabled = NO;
        SetDisconnected();
        
        switch(state)
        {
            case PebbleWatcherStateError:
                [pebbleWatcher_ stop];
                [[[[UIAlertView alloc] initWithTitle:nil message:((error == PebbleWatcherErrorUnauthorized) ? @"Unauthorized to Use Bluetooth Low Energy" : @"No Bluetooth Low Energy Support") delegate:nil cancelButtonTitle:@"Close" otherButtonTitles:nil, nil] autorelease] show];
                break;
                
            case PebbleWatcherStateIdle:
                pebbleWatcherSwitch.indicatorLevel = 0;
                break;
                
            case PebbleWatcherStateSearching:
                pebbleWatcherSwitch.indicatorLevel = 0.3;
                break;
                
            case PebbleWatcherStateConnecting:
                pebbleWatcherSwitch.indicatorLevel = 0.6;
                break;
                
            case PebbleWatcherStateOff:
            default:
                pebbleWatcherSwitch.on = NO;
                [locationManager stopUpdatingLocation];
                self.locationManagerIsActive = NO;
                break;
        }
    }
}

- (void)pebbleWatcher:(PebbleWatcher *)pebbleWatcher didUpdateRSSI:(NSInteger)RSSI
{
    if(previousRSSI == InvalidRSSI)
        previousRSSI = RSSI;
    
    alertControl.currentLevel = ((CGFloat)(previousRSSI + RSSI) / 2 + 50) / -40;
    
    if(alertControl.triggered)
    {
        if(++numberOfConsecutiveTriggers == 1 && (lastAlertDate == nil || [lastAlertDate timeIntervalSinceNow] < -10))
        {
            self.lastAlertDate = [NSDate date];
            [self sendAlertMessage:alertMessageTextView.text];
        }
    }
    else
        numberOfConsecutiveTriggers = 0;
    
    previousRSSI = RSSI;
}

@end
