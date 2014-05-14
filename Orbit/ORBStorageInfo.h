//
//  ORBStorageInfo.h
//  Orbit
//
//  Created by Andy LaVoy on 4/27/13.
//  Copyright (c) 2013 Log Cabin. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ORBStorageInfo : NSObject

@property (assign) CGFloat lastStoragePercentage;
@property (strong) NSString *lastStorageUsed;
@property (strong) NSString *lastStorageAvailable;

- (NSString *)storageSpaceString;

+ (BOOL)shouldShowStorageAsPercentage;
+ (void)toggleStorageFormat;

@end
