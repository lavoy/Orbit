//
//  ORBExclusionRule.h
//  Orbit
//
//  Created by Joel Levin on 5/13/13.
//  Copyright (c) 2013 Log Cabin. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface ORBExclusionRule : NSObject

@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *identifier;
@property (nonatomic, strong) NSArray *clientIDs;
@property (nonatomic, assign) BOOL isWhitelist;
@property (nonatomic, assign) BOOL isSmart;
@property (nonatomic, assign) BOOL isEnabled;

- (id)initWithDictionary:(NSDictionary *)dictionary;
- (BOOL)shouldExcludeFile:(ANKFile *)file;

- (NSString *)imageString;
- (NSString *)highlightedImageString;

@end
