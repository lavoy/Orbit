//
//  ORBPassportLaunchView.m
//  Orbit
//
//  Created by Andy LaVoy on 8/8/13.
//  Copyright (c) 2013 Log Cabin. All rights reserved.
//

#import "ORBPassportLaunchView.h"

@implementation ORBPassportLaunchView

- (CGRect)hiddenStateFrameInView:(UIView *)view {
	CGRect hiddenStateFrame = [super hiddenStateFrameInView:view];
	hiddenStateFrame.origin.y = [self viewHeightExcludingContentInset:view];
	return hiddenStateFrame;
}

- (CGRect)visibleStateFrameInView:(UIView *)view {
	CGRect visibleStateFrame = [super visibleStateFrameInView:view];
	visibleStateFrame.origin.y = [self viewHeightExcludingContentInset:view] - 105.0;
	if (ORBIsPad) {
		visibleStateFrame.origin.y -= 20.0;
	}
	return visibleStateFrame;
}

- (CGRect)pollingStateFrameInView:(UIView *)view {
	CGRect pollingStateFrame = [super pollingStateFrameInView:view];
	pollingStateFrame.origin.y = [self viewHeightExcludingContentInset:view] - pollingStateFrame.size.height;
	if (ORBIsPad) {
		pollingStateFrame.origin.y -= 20.0;
	}
	return pollingStateFrame;
}

- (CGFloat)viewHeightExcludingContentInset:(UIView *)view {
    if ([view isKindOfClass:[UIScrollView class]]) {
        UIScrollView *scrollView = (UIScrollView *) view;
        return scrollView.boundsHeight - scrollView.contentInset.top;
    } else {
        return view.boundsHeight;
    }
}

@end
