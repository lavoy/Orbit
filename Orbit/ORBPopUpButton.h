//
//  ORBPopUpButton.h
//  Orbit
//
//  Created by Joel Levin on 3/23/13.
//  Copyright (c) 2013 Andy LaVoy. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface ORBPopUpButton : NSPopUpButton

@property (copy) NSMenu *(^willShowMenu)(void);

@end
