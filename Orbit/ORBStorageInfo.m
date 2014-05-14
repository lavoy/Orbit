//
//  ORBStorageInfo.m
//  Orbit
//
//  Created by Andy LaVoy on 4/27/13.
//  Copyright (c) 2013 Log Cabin. All rights reserved.
//

#import "ORBStorageInfo.h"


static NSString *const kORBShowStorageUsageAsPercentage = @"showStorageUsageAsPercentage";

@implementation ORBStorageInfo

- (NSString *)storageSpaceString {
    NSString *storageString = nil;
    if (self.lastStorageAvailable > 0) {
        if ([ORBStorageInfo shouldShowStorageAsPercentage]) {
            storageString = [NSString stringWithFormat:@"%.1f%% of %@ used", self.lastStoragePercentage, self.lastStorageAvailable];
        } else {
            storageString = [NSString stringWithFormat:@"%@ of %@ used", self.lastStorageUsed, self.lastStorageAvailable];
        }
    }
    return storageString;
}

+ (BOOL)shouldShowStorageAsPercentage {
	return [[NSUserDefaults standardUserDefaults] boolForKey:kORBShowStorageUsageAsPercentage];
}

+ (void)toggleStorageFormat {
    [[NSUserDefaults standardUserDefaults] setBool:![self shouldShowStorageAsPercentage] forKey:kORBShowStorageUsageAsPercentage];
}

@end
