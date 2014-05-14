//
//  NSMenuItem+Orbit.m
//  Orbit
//
//  Created by Joel Levin on 3/22/13.
//  Copyright (c) 2013 Andy LaVoy. All rights reserved.
//

#import "NSMenuItem+Orbit.h"


@implementation NSMenuItem (Orbit)

+ (NSMenuItem *)itemWithTitle:(NSString *)title target:(id)target action:(SEL)action keyEquivalent:(NSString *)key tag:(NSInteger)tag {
	NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:title action:action keyEquivalent:key];
	item.target = target;
	item.tag = tag;
	return item;
}

@end
