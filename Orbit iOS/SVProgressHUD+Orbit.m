//
//  SVProgressHUD+Orbit.m
//  Orbit
//
//  Created by Andy LaVoy on 5/1/13.
//  Copyright (c) 2013 Log Cabin. All rights reserved.
//

#import "SVProgressHUD+Orbit.h"

@implementation SVProgressHUD (Orbit)

+ (void)showAutodismissingSuccessWithStatus:(NSString *)string {
    [self showSuccessWithStatus:string];
    
    double delayInSeconds = 1.5;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [self dismiss];
    });
}

@end
