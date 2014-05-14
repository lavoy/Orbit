//
//  Panel.h
//  NetBox
//
//  Created by Andy LaVoy on 3/30/13.
//  Copyright (c) 2013 Andy LaVoy. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface ORBPanel : NSPanel

@property (copy) void (^eventDidOccur)(NSResponder *responder, NSEvent *event, BOOL *shouldBlock);

@end
