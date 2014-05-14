//
//  ORBPreferences.m
//  Orbit
//
//  Created by Joel Levin on 5/4/13.
//  Copyright (c) 2013 Log Cabin. All rights reserved.
//

#import "ORBPreferences.h"
#import <objc/runtime.h>
#import <ADNKit/NSArray+ANKAdditions.h>
#import "ORBExclusionRule.h"

#ifndef __IPHONE_OS_VERSION_MIN_REQUIRED

    #import "MASShortcut.h"
    #import "MASShortcut+UserDefaults.h"

#endif


static NSString *const kORBShouldMakeNewFilesPublicKey						= @"ShouldMakeNewFilesPublicKey";
static NSString *const kORBShouldCopyPublicUploadedURLKey					= @"ShouldCopyPublicUploadedURLKey";
static NSString *const kORBShouldAutouploadScreenshotsKey					= @"ShouldAutouploadScreenshotsKey";
static NSString *const kORBShouldDeleteScreenshotsKey						= @"ShouldAutodeleteScreenshotsKey";
static NSString *const kORBShouldUploadClipboardContentKey					= @"ShouldUploadClipboardContentKey";
static NSString *const kORBShouldUploadRichTextClipboardContentAsPlainKey	= @"ShouldUploadRichTextClipboardContentAsPlainKey";
static NSString *const kORBShouldSendAnonymousUsageStatsKey					= @"ShouldSendAnonymousUsageStatsKey";
static NSString *const kORBExclusionRuleIdentifiersKey						= @"ExclusionRuleIdentifiersKey";
static NSString *const kORBFullSizeGalleryImagesKey                         = @"FullSizeGalleryImagesKey";


@interface ORBPreferences ()

@property (nonatomic, strong) NSArray *exclusionIdentifierPrefs;
@property (nonatomic, strong) NSArray *allRules;
@property (nonatomic, strong) NSDictionary *rulesMap;
@property (nonatomic, assign) BOOL isUpdatingBatch;

- (NSDictionary *)propertyToUserDefaultsKeyMapping;

@end


@implementation ORBPreferences

+ (instancetype)preferences {
	static ORBPreferences *sharedInstance = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		sharedInstance = [[ORBPreferences alloc] init];
	});
	return sharedInstance;
}


- (id)init {
	if ((self = [super init])) {
		NSDictionary *defaultDefaults = @{kORBShouldMakeNewFilesPublicKey: @YES, kORBShouldCopyPublicUploadedURLKey: @YES, kORBShouldAutouploadScreenshotsKey: @NO, kORBShouldDeleteScreenshotsKey: @NO, kORBShouldUploadClipboardContentKey: @YES, kORBShouldUploadRichTextClipboardContentAsPlainKey: @NO, kORBShouldSendAnonymousUsageStatsKey: @YES, kORBExclusionRuleIdentifiersKey: @[], @"SUHasLaunchedBefore": @YES, @"SUEnableAutomaticChecks": @YES, kORBFullSizeGalleryImagesKey: @NO};
		[[NSUserDefaults standardUserDefaults] registerDefaults:defaultDefaults];
		
#ifndef __IPHONE_OS_VERSION_MIN_REQUIRED
        
		MASShortcut *defaultUploadShortcut = [MASShortcut shortcutWithKeyCode:kVK_ANSI_O modifierFlags:NSCommandKeyMask | NSAlternateKeyMask];
		[MASShortcut setGlobalShortcut:defaultUploadShortcut forUserDefaultsKey:kORBUploadFilesShortcutKey];
		
		MASShortcut *defaultClipboardShortcut = [MASShortcut shortcutWithKeyCode:kVK_ANSI_O modifierFlags:NSCommandKeyMask | NSAlternateKeyMask | NSControlKeyMask];
		[MASShortcut setGlobalShortcut:defaultClipboardShortcut forUserDefaultsKey:kORBUploadClipboardShortcutKey];
		
		MASShortcut *defaultToggleOrbitShortcut = [MASShortcut shortcutWithKeyCode:kVK_ANSI_O modifierFlags:NSCommandKeyMask | NSAlternateKeyMask | NSShiftKeyMask];
		[MASShortcut setGlobalShortcut:defaultToggleOrbitShortcut forUserDefaultsKey:kORBToggleOrbitWindowShortcutKey];
        
#endif
		
		unsigned int propertyCount = 0;
		objc_property_t *propertiesList = class_copyPropertyList([self class], &propertyCount);
		for (unsigned int i = 0; i < propertyCount; i++) {
			objc_property_t property = propertiesList[i];
			NSString *propertyName = [NSString stringWithUTF8String:property_getName(property)];
			if ([propertyName hasSuffix:@"Pref"] || [propertyName hasSuffix:@"Prefs"]) {
				NSString *userDefaultsKey = [self propertyToUserDefaultsKeyMapping][propertyName];
				[self setValue:[[NSUserDefaults standardUserDefaults] objectForKey:userDefaultsKey] forKey:propertyName];
				[self addObserver:self forKeyPath:propertyName options:NSKeyValueObservingOptionNew context:nil];
			}
		}
		free(propertiesList);
	}
	return self;
}


- (NSDictionary *)propertyToUserDefaultsKeyMapping {
	static NSDictionary *mapping = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		mapping = @{@"newFilesArePublicPref": kORBShouldMakeNewFilesPublicKey, @"autoCopyPublicUploadedURLPref": kORBShouldCopyPublicUploadedURLKey, @"autoUploadScreenshotsPref": kORBShouldAutouploadScreenshotsKey, @"deleteScreenshotsAfterUploadPref": kORBShouldDeleteScreenshotsKey, @"uploadClipboardContentPref": kORBShouldUploadClipboardContentKey, @"uploadRichTextClipboardContentAsPlainPref": kORBShouldUploadRichTextClipboardContentAsPlainKey, @"sendAnonymousUsageStatsPref": kORBShouldSendAnonymousUsageStatsKey, @"exclusionIdentifierPrefs": kORBExclusionRuleIdentifiersKey, @"fullSizeGalleryImagesPref" : kORBFullSizeGalleryImagesKey};
	});
	return mapping;
}


- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	if (self.isUpdatingBatch) {
		return;
	}
	
	id valueObject = [self valueForKeyPath:keyPath];
	NSString *userDefaultsKey = self.propertyToUserDefaultsKeyMapping[keyPath];
	[[NSUserDefaults standardUserDefaults] setObject:valueObject forKey:userDefaultsKey];
	[[NSUserDefaults standardUserDefaults] synchronize];
}

#pragma mark -
#pragma mark File Exclusion

- (NSArray *)allExclusionRules {
    if (!self.allRules) {
		NSMutableDictionary *objectMap = [NSMutableDictionary dictionary];
        
        NSString *filePath = [self exclusionMapLocalFilePath];
        NSData *fileData = [NSData dataWithContentsOfFile:filePath];
        
        if (fileData) {
            NSDictionary *rawMap = [NSJSONSerialization JSONObjectWithData:fileData options:0 error:nil];
            NSArray *rawRules = rawMap[@"Rules"];
            
            self.allRules = [rawRules ank_map:^id(NSDictionary *ruleDictionary) {
                ORBExclusionRule *rule = [[ORBExclusionRule alloc] initWithDictionary:ruleDictionary];
                objectMap[rule.identifier] = rule;
                return rule;
            }];
            
            self.allRules = [self.allRules sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"isSmart" ascending:NO], [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES selector:@selector(caseInsensitiveCompare:)]]];
        }
    }
    
	return self.allRules;
}


- (NSArray *)enabledExclusionRules {
	return [self.allExclusionRules ank_filter:^BOOL(ORBExclusionRule *rule) {
		return rule.isEnabled;
	}];
}


- (ORBExclusionRule *)exclusionRuleWithIdentifier:(NSString *)identifier {
	return self.rulesMap[identifier];
}


- (BOOL)shouldExcludeUsingRuleWithIdentifier:(NSString *)identifier {
	return [self.exclusionIdentifierPrefs containsObject:identifier];
}


- (void)setShouldExclude:(BOOL)shouldExclude usingRuleWithIdentifier:(NSString *)identifier {
	NSMutableArray *mutablePrefs = [self.exclusionIdentifierPrefs mutableCopy];
	BOOL currentlyExcluded = [self shouldExcludeUsingRuleWithIdentifier:identifier];
	
	if (shouldExclude && !currentlyExcluded) {
		[mutablePrefs addObject:identifier];
	} else if (!shouldExclude && currentlyExcluded) {
		[mutablePrefs removeObject:identifier];
	}
	
	self.exclusionIdentifierPrefs = mutablePrefs;
}

#pragma mark - Server Storage of Rules

- (NSString *)exclusionMapLocalFilePath {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *dir = [paths objectAtIndex:0];
    return [dir stringByAppendingPathComponent:@"ExclusionMap.json"];
}


- (void)resetExclusionRules {
    self.allRules = nil;
}


@end
