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
 * Switch.m
 *
 *  Created on: Feb 2, 2014
 *      Author: Billy
 */

#import "Switch.h"
#import <QuartzCore/QuartzCore.h>

#define OffColor            [UIColor colorWithWhite:0.55 alpha:1]
#define ButtonPressedColor  [UIColor colorWithWhite:0.2 alpha:1]
#define ButtonReleasedColor (on ? [UIColor colorWithWhite:0.3 alpha:1] : [UIColor lightGrayColor])

@interface Switch ()
{
    IBOutlet UIView *indicator;
    IBOutlet UIView *pushButton;
    BOOL toggle;
    BOOL indicatorIsOn;
}

@property (assign) NSTimer *indicatorBlinkTimer;
@end

@implementation Switch
@synthesize on;
@synthesize indicatorLevel;
@synthesize alert;
@synthesize indicatorBlinkTimer;

- (void)dealloc
{
    [indicator release];
    [pushButton release];
    self.indicatorBlinkTimer = nil;
    [super dealloc];
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    
    if(self != nil)
    {
        [[NSBundle mainBundle] loadNibNamed:@"Switch" owner:self options:nil];
        super.clipsToBounds = NO;
        indicator.frame = super.bounds;
        [self addSubview:indicator];
        
        on = NO;
        indicatorLevel = 0;
        alert = NO;
    }
    
    return self;
}

- (void)awakeFromNib
{
    CGRect frame = super.bounds;
    super.backgroundColor = [UIColor clearColor];
    
    indicator.layer.cornerRadius = MIN(frame.size.width, frame.size.height) / 2;
    indicator.layer.shadowColor = [UIColor clearColor].CGColor;
    indicator.layer.shadowPath = [UIBezierPath bezierPathWithRoundedRect:indicator.bounds cornerRadius:indicator.layer.cornerRadius].CGPath;
    indicator.layer.shadowRadius = 2;
    indicator.layer.shadowOpacity = 1;
    indicator.layer.shadowOffset = CGSizeZero;
    
    frame.origin = CGPointMake(5, 5);
    frame.size.width -= 10;
    frame.size.height -= 10;
    pushButton.frame = frame;
    pushButton.layer.cornerRadius = indicator.layer.cornerRadius - 5;
    pushButton.layer.borderWidth = 2;
    pushButton.layer.borderColor = [UIColor colorWithWhite:0.4 alpha:1].CGColor;
    pushButton.layer.shadowColor = [UIColor blackColor].CGColor;
    pushButton.layer.shadowPath = [UIBezierPath bezierPathWithRoundedRect:pushButton.bounds cornerRadius:pushButton.layer.cornerRadius].CGPath;
    pushButton.layer.shadowRadius = 5;
    pushButton.layer.shadowOpacity = 1;
    pushButton.layer.shadowOffset = CGSizeZero;
    
    [super awakeFromNib];
}

- (void)changeIndicatorColor:(BOOL)on_
{
    indicatorIsOn = on_;
    
    [UIView animateWithDuration:0.1 delay:0 options:UIViewAnimationOptionAllowUserInteraction animations:^{
        if(on_)
        {
            CGFloat red;
            CGFloat green;
            
            if(indicatorLevel > 0.5)
            {
                red = (1 - indicatorLevel) / 0.5;
                green = 1;
            }
            else
            {
                red = 1;
                green = indicatorLevel / 0.5;
            }
            
            indicator.backgroundColor = [UIColor colorWithRed:red green:green blue:0 alpha:1];
            indicator.layer.shadowColor = indicator.backgroundColor.CGColor;
        }
        else
        {
            indicator.backgroundColor = OffColor;
            indicator.layer.shadowColor = [UIColor clearColor].CGColor;
        }
    } completion:nil];
}

- (CGFloat)indicatorLevel
{
    return indicatorLevel;
}

- (void)setIndicatorLevel:(CGFloat)indicatorLevel_
{
    if(indicatorLevel_ < 0)
        indicatorLevel_ = 0;
    else if(indicatorLevel_ > 1)
        indicatorLevel_ = 1;

    if(indicatorLevel_ != indicatorLevel)
    {
        indicatorLevel = indicatorLevel_;
        [self changeIndicatorColor:on];
    }
}

- (BOOL)on
{
    return on;
}

- (void)setOn:(BOOL)on_
{
    if(on_ != on)
    {
        on = on_;
        pushButton.backgroundColor = ButtonReleasedColor;
        [self changeIndicatorColor:on];
        [self setAlert_:(on && alert)];
    }
}

- (BOOL)alert
{
    return alert;
}

- (void)setAlert_:(BOOL)alert_
{
    alert = alert_;
    self.indicatorBlinkTimer = alert ? (NSTimer *)0xf00 : nil;
}

- (void)setAlert:(BOOL)alert_
{
    if(on && alert_ != alert)
    {
        [self setAlert_:alert_];
    
        if(!alert)
            [self changeIndicatorColor:YES];
    }
}

- (void)blinkIndicator:(id)sender
{
    [self changeIndicatorColor:!indicatorIsOn];
}

- (NSTimer *)indicatorBlinkTimer
{
    return indicatorBlinkTimer;
}

- (void)setIndicatorBlinkTimer:(NSTimer *)blinkTimer_
{
    [indicatorBlinkTimer invalidate];
    
    if(blinkTimer_ == nil)
        indicatorBlinkTimer = nil;
    else
    {
        indicatorBlinkTimer = [NSTimer timerWithTimeInterval:0.8 target:self selector:@selector(blinkIndicator:) userInfo:nil repeats:YES];
        [[NSRunLoop mainRunLoop] addTimer:indicatorBlinkTimer forMode:NSRunLoopCommonModes];
    }
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    toggle = YES;
    pushButton.backgroundColor = ButtonPressedColor;
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    toggle = CGRectContainsPoint(self.bounds, [event.allTouches.allObjects.lastObject locationInView:self]);
    pushButton.backgroundColor = toggle ? ButtonPressedColor : ButtonReleasedColor;
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self touchesEnded:touches withEvent:event];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    if(toggle)
    {
        self.on = !on;
        [super sendActionsForControlEvents:UIControlEventValueChanged];
    }
}

@end
