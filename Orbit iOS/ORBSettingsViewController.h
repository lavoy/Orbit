//
//  ORBSettingsViewController.h
//  Orbit
//
//  Created by Andy LaVoy on 4/27/13.
//  Copyright (c) 2013 Log Cabin. All rights reserved.
//

#import "ORBTableViewController.h"

@interface ORBSettingsViewController : ORBTableViewController

@property (nonatomic, strong, readonly) UILabel *footerLabel;

- (id)initWithDataSource:(ORBDataSource *)dataSource;

@end
