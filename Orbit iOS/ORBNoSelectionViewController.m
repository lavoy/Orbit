//
//  ORBNoSelectionViewController.m
//  Orbit
//
//  Created by Joel Levin on 8/10/13.
//  Copyright (c) 2013 Log Cabin. All rights reserved.
//

#import "ORBNoSelectionViewController.h"
#import "ORBGradientLayerView.h"
#import <QuartzCore/QuartzCore.h>


@interface ORBNoSelectionViewController ()

@end


@implementation ORBNoSelectionViewController

- (void)sendLeftBarButtonActionToTarget {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    UIBarButtonItem *bbi = self.navigationItem.leftBarButtonItem;
    [bbi.target performSelector:bbi.action withObject:self.navigationItem];
#pragma clang diagnostic pop
}

@end
