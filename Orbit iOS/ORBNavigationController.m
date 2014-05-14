//
//  ORBNavigationController.m
//  Orbit
//
//  Created by Andy LaVoy on 10/11/13.
//  Copyright (c) 2013 Log Cabin. All rights reserved.
//

#import "ORBNavigationController.h"
#import "ORBNavigationBar.h"

@interface ORBNavigationController ()

@end

@implementation ORBNavigationController

- (id)initWithRootViewController:(UIViewController *)rootViewController
{
    self = [super initWithNavigationBarClass:[ORBNavigationBar class] toolbarClass:[UIToolbar class]];
    if (self && rootViewController) {
        self.viewControllers = @[rootViewController];
    }
    return self;
}

@end
