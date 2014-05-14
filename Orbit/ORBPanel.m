//
//  Panel.m
//  NetBox
//
//  Created by Andy LaVoy on 3/30/13.
//  Copyright (c) 2013 Andy LaVoy. All rights reserved.
//

#import "ORBPanel.h"


@implementation ORBPanel

- (id)initWithContentRect:(NSRect)contentRect styleMask:(NSUInteger)aStyle backing:(NSBackingStoreType)bufferingType defer:(BOOL)flag {
	if ((self = [super initWithContentRect:contentRect styleMask:NSBorderlessWindowMask backing:bufferingType defer:flag])) {
		[self setOpaque:NO];
		[self setBackgroundColor:[NSColor clearColor]];
	}
	return self;
}


- (BOOL)canBecomeKeyWindow {
    return YES;
}


- (BOOL)canBecomeMainWindow {
	return YES;
}


- (void)sendEvent:(NSEvent *)theEvent {
	BOOL shouldBlock = NO;
	
	if (self.eventDidOccur) {
		self.eventDidOccur(self.firstResponder, theEvent, &shouldBlock);
	}
	
	if (!shouldBlock) {
		[super sendEvent:theEvent];
	}
}


@end
