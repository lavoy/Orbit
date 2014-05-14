//
//  ORBExclusionRule.m
//  Orbit
//
//  Created by Joel Levin on 5/13/13.
//  Copyright (c) 2013 Log Cabin. All rights reserved.
//

#import "ORBExclusionRule.h"


@implementation ORBExclusionRule

- (id)initWithDictionary:(NSDictionary *)dictionary {
	if ((self = [super init])) {
		self.name = dictionary[@"name"];
		self.identifier = dictionary[@"identifier"];
		self.clientIDs = dictionary[@"clientIDs"];
		self.isWhitelist = [dictionary[@"isWhitelist"] boolValue];
		self.isSmart = [dictionary[@"isSmart"] boolValue];
	}
	return self;
}


- (BOOL)shouldExcludeFile:(ANKFile *)file {
	BOOL shouldExclude = NO;
	
	if (self.clientIDs.count > 0) {
		for (NSString *clientID in self.clientIDs) {
			if ((!self.isWhitelist && [file.source.clientID isEqualToString:clientID]) || (self.isWhitelist && ![file.source.clientID isEqualToString:clientID])) {
				shouldExclude = YES;
				break;
			}
		}
	}
	
	return shouldExclude;
}


- (BOOL)isEnabled {
	return [[ORBPreferences preferences] shouldExcludeUsingRuleWithIdentifier:self.identifier];
}


- (void)setIsEnabled:(BOOL)enabled {
	[[ORBPreferences preferences] setShouldExclude:enabled usingRuleWithIdentifier:self.identifier];
}


- (NSString *)imageString {
#ifdef __IPHONE_OS_VERSION_MIN_REQUIRED
    return self.isSmart ? @"smartbadge-ios" : @"appbadge-ios";
#else
    return self.isSmart ? @"smartbadge" : @"appbadge";
#endif
}


- (NSString *)highlightedImageString {
    return self.isSmart ? @"smartbadge-down" : @"appbadge-down";
}


@end
