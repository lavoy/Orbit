//
//  Blocks+Orbit
//  Orbit
//
//  Created by Andy LaVoy on 5/2/13.
//  Copyright (c) 2013 Log Cabin. All rights reserved.
//

#import "Blocks+Orbit.h"

void dispatch_after_seconds(int64_t delta, dispatch_queue_t queue, dispatch_block_t block)
{
    int64_t delayInSeconds = delta;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), block);
}
