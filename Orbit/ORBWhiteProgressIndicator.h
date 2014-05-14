//
//  ORBWhiteProgressIndicator.h
//  Orbit
//
//  Created by Joel Levin on 3/23/13.
//  Copyright (c) 2013 Andy LaVoy. All rights reserved.
//

#import <Cocoa/Cocoa.h>


typedef NS_ENUM(NSUInteger, ORBORBWhiteProgressIndicatorStyle) {
	ORBWhiteProgressIndicatorStyleForLightBackground = 0,
	ORBWhiteProgressIndicatorStyleForDarkBackground
};


@interface ORBWhiteProgressIndicator : NSProgressIndicator

@property (assign) ORBORBWhiteProgressIndicatorStyle style;

@end
