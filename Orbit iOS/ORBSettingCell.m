//
//  ORBSettingCell.m
//  Orbit
//
//  Created by Andy LaVoy on 5/26/13.
//  Copyright (c) 2013 Log Cabin. All rights reserved.
//

#import "ORBSettingCell.h"

@implementation ORBSettingCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
		self.textLabel.font = [UIFont fontWithName:kORBFontMedium size:16.0];
		self.detailTextLabel.font = [UIFont fontWithName:kORBFontRegular size:16.0];
    }
    return self;
}

@end
