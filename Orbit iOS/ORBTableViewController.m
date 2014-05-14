//
//  ORBTableViewController.m
//  Orbit
//
//  Created by Andy LaVoy on 10/14/13.
//  Copyright (c) 2013 Log Cabin. All rights reserved.
//

#import "ORBTableViewController.h"

@interface ORBTableViewController ()

@property (nonatomic, copy) NSIndexPath *poppingIndexPath;

@end

@implementation ORBTableViewController

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.poppingIndexPath = [self.tableView indexPathForSelectedRow];
    if (self.poppingIndexPath) {
        [self.tableView deselectRowAtIndexPath:self.poppingIndexPath animated:YES];
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    self.poppingIndexPath = nil;
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    
    if (self.poppingIndexPath) {
        [self.tableView selectRowAtIndexPath:self.poppingIndexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
    }
}

@end
