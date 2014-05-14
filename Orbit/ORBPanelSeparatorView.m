//
//  ORBPanelSeparatorView.m
//  Orbit
//
//  Created by Levin, Joel A on 3/20/13.
//  Copyright (c) 2013 Andy LaVoy. All rights reserved.
//

#import "ORBPanelSeparatorView.h"


@implementation ORBPanelSeparatorView

- (void)drawRect:(NSRect)rect {
	[[NSColor colorWithCalibratedWhite:0.75 alpha:1.0] set];
	[NSBezierPath fillRect:NSMakeRect(0.0, 1.0, self.bounds.size.width, 1.0)];
	
	[[NSColor colorWithCalibratedWhite:0.95 alpha:1.0] set];
	[NSBezierPath fillRect:NSMakeRect(0.0, 0.0, self.bounds.size.width, 1.0)];
}


@end
