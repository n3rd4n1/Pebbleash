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
 * AlertControl.m
 *
 *  Created on: Jan 24, 2014
 *      Author: Billy
 */

#import "AlertControl.h"
#import <QuartzCore/QuartzCore.h>

@interface AlertControl ()
{
    CGFloat yOrigin;
    
    IBOutlet UIView *parentView;
    IBOutlet UIView *levelIndicatorContainer;
    IBOutlet UIView *currentLevelIndicatorContainer;
    IBOutlet UIView *currentLevelColorIndicatorView;
    IBOutlet UIView *currentLevelIndicatorView;
    IBOutlet UIView *triggerLevelSliderContainer;
    IBOutlet UIView *triggerLevelSliderView;
}

@end

@implementation AlertControl
@synthesize currentLevel;
@synthesize triggerLevel;
@synthesize triggered;

- (void)dealloc
{
    [parentView release];
    [levelIndicatorContainer release];
    [currentLevelIndicatorContainer release];
    [currentLevelColorIndicatorView release];
    [currentLevelIndicatorView release];
    [triggerLevelSliderContainer release];
    [triggerLevelSliderView release];
    [super dealloc];
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    
    if(self != nil)
    {
        [[NSBundle mainBundle] loadNibNamed:@"AlertControl" owner:self options:nil];
        parentView.frame = super.bounds;
        [self addSubview:parentView];
        self.backgroundColor = [UIColor clearColor];
        self.clipsToBounds = YES;
        levelIndicatorContainer.layer.cornerRadius = 2;
        currentLevelIndicatorContainer.layer.borderWidth = 1;
        currentLevelIndicatorContainer.layer.borderColor = [UIColor colorWithWhite:0.1 alpha:1].CGColor;
        triggerLevelSliderView.layer.cornerRadius = 7;
        triggerLevelSliderView.layer.borderColor = [UIColor darkGrayColor].CGColor;
        triggerLevelSliderView.layer.borderWidth = 1;
    }
    
    return self;
}

- (void)awakeFromNib
{
    CGRect frame = currentLevelIndicatorView.frame;
    frame.size.height = self.frame.size.height;
    frame.origin.y = currentLevelIndicatorContainer.frame.size.height;
    currentLevelIndicatorView.frame = frame;
    currentLevel = 0;
    self.triggerLevel = 0.5;
    [super awakeFromNib];
}

- (CGFloat)triggerLevel
{
    return triggerLevel;
}

- (void)setTriggerLevel:(CGFloat)triggerLevel_
{
    if(triggerLevel_ < 0)
        triggerLevel = 0;
    else if(triggerLevel_ > 1)
        triggerLevel = 1;
    else
        triggerLevel = triggerLevel_;
    
    [self updateCurrentLevelIndicatorColor];
    
    CGRect frame = triggerLevelSliderContainer.frame;
    frame.origin.y = currentLevelIndicatorContainer.frame.origin.y + (currentLevelIndicatorContainer.frame.size.height * (1 - triggerLevel) - frame.size.height / 2);
    triggerLevelSliderContainer.frame = frame;
}

- (void)updateCurrentLevelIndicatorColor
{
    CGFloat difference = triggerLevel - currentLevel;
    CGFloat red;
    CGFloat green;
    
    if(difference > 0.5)
    {
        red = (1 - difference) / 0.5;
        green = 1;
    }
    else
    {
        red = 1;
        green = difference / 0.5;
    }
    
    currentLevelColorIndicatorView.backgroundColor = [UIColor colorWithRed:red green:green blue:0 alpha:1];
    currentLevelIndicatorView.backgroundColor = currentLevelColorIndicatorView.backgroundColor;
}

- (IBAction)changeTriggerLevelSliderPosition:(UIPanGestureRecognizer *)sender
{
    CGRect frame = sender.view.frame;
    
    switch(sender.state)
    {
        case UIGestureRecognizerStateBegan:
            yOrigin = frame.origin.y;
            break;
            
        case UIGestureRecognizerStateChanged:
        {
            CGAffineTransform transform = CGAffineTransformMakeTranslation(0, [sender translationInView:sender.view].y);
            CGFloat newYOrigin = yOrigin + transform.ty;
            CGFloat yMin = currentLevelIndicatorContainer.frame.origin.y - frame.size.height / 2;
            CGFloat yMax = yMin + currentLevelIndicatorContainer.frame.size.height;
            
            if(newYOrigin < yMin)
            {
                transform.ty += (yMin - newYOrigin);
                triggerLevel = 1;
            }
            else if(newYOrigin > yMax)
            {
                transform.ty += (yMax - newYOrigin);
                triggerLevel = 0;
            }
            else
                triggerLevel = 1 - ((newYOrigin - yMin) / currentLevelIndicatorContainer.frame.size.height);
            
            sender.view.transform = transform;
            [self updateCurrentLevelIndicatorColor];
            break;
        }
            
        default:
            frame.origin.y += sender.view.transform.ty;
            sender.view.frame = frame;
            sender.view.transform = CGAffineTransformIdentity;
            break;
    }
}

- (CGFloat)currentLevel
{
    return currentLevel;
}

- (void)setCurrentLevel:(CGFloat)currentLevel_
{
    currentLevel = (currentLevel_ < 0) ? 0 : ((currentLevel_ > 1) ? 1 : currentLevel_);
    
    [UIView animateWithDuration:1 delay:0 options:UIViewAnimationOptionCurveLinear animations:^{
        currentLevelIndicatorView.transform = CGAffineTransformMakeTranslation(0, -(currentLevel * currentLevelIndicatorContainer.frame.size.height));
        [self updateCurrentLevelIndicatorColor];
    } completion:^(BOOL finished) {
        if([self triggered])
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                [UIView animateWithDuration:0.2 delay:0 options:UIViewAnimationOptionAllowUserInteraction animations:^{
                    triggerLevelSliderView.transform = CGAffineTransformMakeScale(1.4, 1.4);
                } completion:^(BOOL finished) {
                    [UIView animateWithDuration:0.1 delay:0 options:UIViewAnimationOptionAllowUserInteraction animations:^{
                        triggerLevelSliderView.transform = CGAffineTransformIdentity;
                    } completion:nil];
                }];
            });
        }
    }];
}

- (BOOL)triggered
{
    return (currentLevel > triggerLevel);
}

@end
