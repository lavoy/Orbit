//
//  ORBNavigationBar.m
//  Orbit
//
//  Created by Andy LaVoy on 10/11/13.
//  Copyright (c) 2013 Log Cabin. All rights reserved.
//

#import "ORBNavigationBar.h"

@interface ORBNavigationBar ()

@property (nonatomic, strong) UIView *underlayView;

@end

@implementation ORBNavigationBar

- (void)removeDarkUnderlayView
{
    [_underlayView removeFromSuperview];
}

- (void)addDarkUnderlayView
{
    [self didAddSubview:nil];
}

- (void)didAddSubview:(UIView *)subview
{
    [super didAddSubview:subview];
    
    if (SYSTEM_VERSION_LESS_THAN(@"7.0.3") && subview != _underlayView)
    {
        UIView *underlayView = self.underlayView;
        [underlayView removeFromSuperview];
        [self insertSubview:underlayView atIndex:1];
    }
}

- (UIView *)underlayView
{
    if (SYSTEM_VERSION_LESS_THAN(@"7.0.3") && _underlayView == nil)
    {
        const CGFloat statusBarHeight = 20;    //  Make this dynamic in your own code...
        const CGSize selfSize = self.frameSize;
        
        _underlayView = [[UIView alloc] initWithFrame:CGRectMake(0, -statusBarHeight, selfSize.width, selfSize.height + statusBarHeight)];
        [_underlayView setAutoresizingMask:(UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight)];
        [_underlayView setBackgroundColor:[UIColor blackColor]];
        [_underlayView setAlpha:0.45f];
        [_underlayView setUserInteractionEnabled:NO];
    }
    
    return _underlayView;
}

@end
