//
//  ORBExclusionsViewController.h
//  Orbit
//
//  Created by Andy LaVoy on 7/6/13.
//  Copyright (c) 2013 Log Cabin. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface ORBExclusionsViewController : UITableViewController

@property (nonatomic, copy) void (^exclusionsDidChangeHandler)(void);

@end
