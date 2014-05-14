//
//  NSMenuItem+Orbit.h
//  Orbit
//
//  Created by Joel Levin on 3/22/13.
//  Copyright (c) 2013 Andy LaVoy. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NSMenuItem (Orbit)

+ (NSMenuItem *)itemWithTitle:(NSString *)title target:(id)target action:(SEL)action keyEquivalent:(NSString *)key tag:(NSInteger)tag;

@end
