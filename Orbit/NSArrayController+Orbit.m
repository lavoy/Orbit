//
//  NSArrayController+Orbit.m
//  NetBox
//
//  Created by Andy LaVoy on 3/30/13.
//  Copyright (c) 2013 Andy LaVoy. All rights reserved.
//

#import "NSArrayController+Orbit.h"


@implementation NSArrayController (Orbit)

- (void)replaceObject:(id)iOldObject withObject:(id)iNewObject {
    NSUInteger objectIndex = [self.arrangedObjects indexOfObject:iOldObject];
    [self removeObject:iOldObject];
    [self insertObject:iNewObject atArrangedObjectIndex:objectIndex];
}


@end
