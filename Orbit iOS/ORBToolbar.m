//
//  ORBToolbar.m
//  Orbit
//
//  Created by Andy LaVoy on 10/11/13.
//  Copyright (c) 2013 Log Cabin. All rights reserved.
//

#import "ORBToolbar.h"

@interface ORBToolbar ()

@property (nonatomic, strong) UIView *underlayView;

@end

@implementation ORBToolbar

- (void)didAddSubview:(UIView *)subview
{
    [super didAddSubview:subview];
    
    if (SYSTEM_VERSION_LESS_THAN(@"7.0.3")) {
        if(subview != _underlayView)
        {
            UIView *underlayView = self.underlayView;
            [underlayView removeFromSuperview];
            [self insertSubview:underlayView atIndex:1];
        }
    }
}

- (UIView *)underlayView
{
    if(SYSTEM_VERSION_LESS_THAN(@"7.0.3") && _underlayView == nil) {
        const CGSize selfSize = self.frameSize;
        
        _underlayView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, selfSize.width, selfSize.height)];
        [_underlayView setAutoresizingMask:(UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight)];
        [_underlayView setBackgroundColor:[UIColor blackColor]];
        [_underlayView setAlpha:0.36f];
        [_underlayView setUserInteractionEnabled:NO];
    }
    
    return _underlayView;
}

@end
