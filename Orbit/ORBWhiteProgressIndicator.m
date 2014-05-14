//
//  ORBWhiteProgressIndicator.m
//  Orbit
//
//  Created by Joel Levin on 3/23/13.
//  Copyright (c) 2013 Andy LaVoy. All rights reserved.
//

#import "ORBWhiteProgressIndicator.h"


@implementation ORBWhiteProgressIndicator

- (void)drawRect:(NSRect)rect {
	NSColor *strokeColor = self.style == ORBWhiteProgressIndicatorStyleForLightBackground ? [NSColor colorWithCalibratedWhite:0.6 alpha:1.0] : [NSColor whiteColor];
	CGFloat cornerRadius = floor(self.bounds.size.height / 2.0);
	NSBezierPath *backgroundPath = [NSBezierPath bezierPathWithRoundedRect:self.bounds xRadius:cornerRadius yRadius:cornerRadius];
	NSBezierPath *strokePath = [NSBezierPath bezierPathWithRoundedRect:NSInsetRect(self.bounds, 0.5, 0.5) xRadius:cornerRadius yRadius:cornerRadius];
	[backgroundPath addClip];
	
	if (self.style == ORBWhiteProgressIndicatorStyleForLightBackground) {
		NSGradient *backgroundGradient = [[NSGradient alloc] initWithStartingColor:[NSColor colorWithCalibratedWhite:0.75 alpha:1.0] endingColor:[NSColor colorWithCalibratedWhite:0.85 alpha:1.0]];
		[backgroundGradient drawInRect:self.bounds angle:-90.0];
	}
	
	CGFloat valuePercentage = self.doubleValue / self.maxValue;
	CGFloat barWidth = floor(self.bounds.size.width * valuePercentage);
	
	NSGradient *foregroundGradient = [[NSGradient alloc] initWithStartingColor:[NSColor whiteColor] endingColor:[NSColor colorWithCalibratedWhite:0.95 alpha:1.0]];
	[foregroundGradient drawInRect:NSMakeRect(0.0, 0.0, barWidth, self.bounds.size.height) angle:90.0];
	
	[strokeColor set];
	[NSBezierPath fillRect:NSMakeRect(barWidth, 0.0, 1.0, self.bounds.size.height)];
	
	[strokePath stroke];
}


- (void)startAnimation:(id)sender {
	// intentionally left blank - do not delete
}


- (void)stopAnimation:(id)sender {
	// intentionally left black - do not delete
}


@end
