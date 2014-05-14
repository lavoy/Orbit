//
//  ORBPanelFooterView.m
//  Orbit
//
//  Created by Levin, Joel A on 3/20/13.
//  Copyright (c) 2013 Andy LaVoy. All rights reserved.
//

#import "ORBPanelFooterView.h"


@interface ORBPanelFooterView ()

- (void)commonInitialization;

@end


@implementation ORBPanelFooterView

- (id)initWithFrame:(NSRect)frameRect {
	if ((self = [super initWithFrame:frameRect])) {
		[self commonInitialization];
	}
	return self;
}


- (id)initWithCoder:(NSCoder *)aDecoder {
	if ((self = [super initWithCoder:aDecoder])) {
		[self commonInitialization];
	}
	return self;
}


- (void)commonInitialization {
	self.usesLightGradient = NO;
	self.drawsRoundedCorners = YES;
	self.borderedEdge = CGRectMinYEdge; // top
}


- (void)drawRect:(NSRect)dirtyRect {
	CGFloat cornerRadius = 10.0;
	
	BOOL drawsBorderInset = YES;
	NSRect borderFrame = NSMakeRect(0.0, self.bounds.size.height - 1.0, self.bounds.size.width, 1.0);
	NSRect borderInsetFrame = NSMakeRect(0.0, self.bounds.size.height - 2.0, self.bounds.size.width, 1.0);
	NSColor *borderColor = [NSColor colorWithCalibratedWhite:0.75 alpha:1.0];
	NSColor *gradientStartColor = [NSColor colorWithCalibratedWhite:0.95 alpha:1.0];
	NSColor *gradientEndingColor = [NSColor colorWithCalibratedWhite:0.75 alpha:1.0];
	
	if (self.borderedEdge == CGRectMaxYEdge) {
		borderFrame.origin.y = 0.0;
		drawsBorderInset = NO;
	}
	
	if (self.usesLightGradient) {
		gradientStartColor = [NSColor whiteColor];
		gradientEndingColor = [NSColor colorWithCalibratedWhite:0.9 alpha:1.0];
	}
	
	NSGradient *gradient = [[NSGradient alloc] initWithStartingColor:gradientStartColor endingColor:gradientEndingColor];
	
	if (self.drawsRoundedCorners) {
		NSBezierPath *path = [NSBezierPath bezierPath];
		[path moveToPoint:NSMakePoint(0.0, self.bounds.size.height)];
		[path lineToPoint:NSMakePoint(self.bounds.size.width, self.bounds.size.height)];
		[path lineToPoint:NSMakePoint(self.bounds.size.width, cornerRadius)];
		[path curveToPoint:NSMakePoint(self.bounds.size.width - cornerRadius, 0.0) controlPoint1:NSMakePoint(self.bounds.size.width, 0.0) controlPoint2:NSMakePoint(self.bounds.size.width, 0.0)];
		[path lineToPoint:NSMakePoint(cornerRadius, 0.0)];
		[path curveToPoint:NSMakePoint(0.0, cornerRadius) controlPoint1:NSZeroPoint controlPoint2:NSZeroPoint];
		[path closePath];
		
		[gradient drawInBezierPath:path angle:-90.0];
	} else {
		[gradient drawInRect:self.bounds angle:-90.0];
	}
	
	[borderColor set];
	[NSBezierPath fillRect:borderFrame];
	
	if (drawsBorderInset) {
		[[NSColor colorWithCalibratedWhite:0.95 alpha:1.0] set];
		[NSBezierPath fillRect:borderInsetFrame];
	}
}

@end
