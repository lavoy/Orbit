//
//  ORBPopUpButton.m
//  Orbit
//
//  Created by Joel Levin on 3/23/13.
//  Copyright (c) 2013 Andy LaVoy. All rights reserved.
//

#import "ORBPopUpButton.h"


@implementation ORBPopUpButton

- (void)mouseDown:(NSEvent *)theEvent {
	if (self.willShowMenu) {
		self.menu = self.willShowMenu();
	}
	[super mouseDown:theEvent];
}


@end
