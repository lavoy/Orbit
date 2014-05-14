//
//  ORBPreferences.h
//  Orbit
//
//  Created by Joel Levin on 5/4/13.
//  Copyright (c) 2013 Log Cabin. All rights reserved.
//

#import <Foundation/Foundation.h>


@class ORBExclusionRule;

@interface ORBPreferences : NSObject

// make sure these end in 'Pref', and any additions do as well or things will break.
@property (nonatomic, assign) BOOL newFilesArePublicPref;
@property (nonatomic, assign) BOOL autoCopyPublicUploadedURLPref;
@property (nonatomic, assign) BOOL autoUploadScreenshotsPref;
@property (nonatomic, assign) BOOL deleteScreenshotsAfterUploadPref;
@property (nonatomic, assign) BOOL uploadClipboardContentPref;
@property (nonatomic, assign) BOOL uploadRichTextClipboardContentAsPlainPref;
@property (nonatomic, assign) BOOL sendAnonymousUsageStatsPref;
@property (nonatomic, assign) BOOL fullSizeGalleryImagesPref;

+ (instancetype)preferences;

- (NSArray *)allExclusionRules;
- (NSArray *)enabledExclusionRules;
- (ORBExclusionRule *)exclusionRuleWithIdentifier:(NSString *)identifier;
- (BOOL)shouldExcludeUsingRuleWithIdentifier:(NSString *)identifier;
- (void)setShouldExclude:(BOOL)shouldExclude usingRuleWithIdentifier:(NSString *)identifier;

- (NSString *)exclusionMapLocalFilePath;
- (void)resetExclusionRules;

@end
