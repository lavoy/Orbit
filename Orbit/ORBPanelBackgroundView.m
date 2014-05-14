//
//  BackgroundView.m
//  NetBox
//
//  Created by Andy LaVoy on 3/30/13.
//  Copyright (c) 2013 Andy LaVoy. All rights reserved.
//

#import "ORBPanelBackgroundView.h"

static CGFloat   const kCornerRadius  = 10.0;

@implementation ORBPanelBackgroundView

- (void)drawRect:(NSRect)dirtyRect {
    NSRect contentRect = self.bounds;//NSInsetRect([self bounds], kLineThickness, kLineThickness);
    NSBezierPath *path = [NSBezierPath bezierPath];
    
    [path moveToPoint:NSMakePoint(_arrowX, NSMaxY(contentRect))];
    [path lineToPoint:NSMakePoint(_arrowX + kArrowWidth / 2, NSMaxY(contentRect) - kArrowHeight)];
    [path lineToPoint:NSMakePoint(NSMaxX(contentRect) - kCornerRadius, NSMaxY(contentRect) - kArrowHeight)];
    
    NSPoint topRightCorner = NSMakePoint(NSMaxX(contentRect), NSMaxY(contentRect) - kArrowHeight);
    [path curveToPoint:NSMakePoint(NSMaxX(contentRect), NSMaxY(contentRect) - kArrowHeight - kCornerRadius) controlPoint1:topRightCorner controlPoint2:topRightCorner];
    
    [path lineToPoint:NSMakePoint(NSMaxX(contentRect), NSMinY(contentRect) + kCornerRadius)];
    
    NSPoint bottomRightCorner = NSMakePoint(NSMaxX(contentRect), NSMinY(contentRect));
    [path curveToPoint:NSMakePoint(NSMaxX(contentRect) - kCornerRadius, NSMinY(contentRect)) controlPoint1:bottomRightCorner controlPoint2:bottomRightCorner];
    
    [path lineToPoint:NSMakePoint(NSMinX(contentRect) + kCornerRadius, NSMinY(contentRect))];

    [path curveToPoint:NSMakePoint(NSMinX(contentRect), NSMinY(contentRect) + kCornerRadius) controlPoint1:contentRect.origin controlPoint2:contentRect.origin];
    
    [path lineToPoint:NSMakePoint(NSMinX(contentRect), NSMaxY(contentRect) - kArrowHeight - kCornerRadius)];
    
    NSPoint topLeftCorner = NSMakePoint(NSMinX(contentRect), NSMaxY(contentRect) - kArrowHeight);
    [path curveToPoint:NSMakePoint(NSMinX(contentRect) + kCornerRadius, NSMaxY(contentRect) - kArrowHeight) controlPoint1:topLeftCorner controlPoint2:topLeftCorner];
    
    [path lineToPoint:NSMakePoint(_arrowX - kArrowWidth / 2, NSMaxY(contentRect) - kArrowHeight)];
    [path closePath];
    
	NSGradient *gradient = [[NSGradient alloc] initWithStartingColor:[NSColor whiteColor] endingColor:[NSColor colorWithCalibratedWhite:0.95 alpha:1.0]];
	[gradient drawInBezierPath:path angle:-90];
    
    [NSGraphicsContext saveGraphicsState];
    
    NSBezierPath *clip = [NSBezierPath bezierPathWithRect:[self bounds]];
    [clip appendBezierPath:path];
    [clip addClip];
    
    [NSGraphicsContext restoreGraphicsState];
}

#pragma mark -
#pragma mark Public accessors

- (void)setArrowX:(NSInteger)arrowX {
    _arrowX = arrowX;
    [self setNeedsDisplay:YES];
}

@end
