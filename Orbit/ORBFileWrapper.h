//
//  ORBFileWrapper.h
//  Orbit
//
//  Created by Levin, Joel A on 3/24/13.
//  Copyright (c) 2013 Andy LaVoy. All rights reserved.
//

#import <Foundation/Foundation.h>


#ifdef __IPHONE_OS_VERSION_MIN_REQUIRED

@interface ORBFileWrapper : NSObject

#else

#import <Quartz/Quartz.h>

@interface ORBFileWrapper : NSObject <QLPreviewItem>

#endif


@property (strong) ANKFile *file;
@property (assign) BOOL isUploading;
@property (assign) BOOL isUploadingAsPublic;
@property (assign) BOOL isDownloading;
@property (assign) CGFloat progress;
@property (strong) NSURL *localURL;
@property (weak) AFHTTPRequestOperation *currentRequest;

+ (ORBFileWrapper *)wrapperForFile:(ANKFile *)file;
+ (NSPredicate *)filterPredicateForQuery:(NSString *)query;

- (NSString *)privateImageName;
- (NSString *)privateImageHighlightedName;
- (NSURL *)URL;
- (NSURL *)sharableURL;
- (NSString *)formattedSizeAndCreatedAt;
- (NSString *)formattedSize;
- (NSString *)formattedCreatedAt;
- (NSString *)name;
- (BOOL)isPublic;

#ifdef __IPHONE_OS_VERSION_MIN_REQUIRED

- (UIImage *)iconImage;
- (NSURL *)thumbnailURL;
- (NSURL *)previewItemURL;
- (NSAttributedString *)attributedFormattedSizeAndCreatedAt;

#else

+ (NSSize)iconSize;
- (NSImage *)iconImage;

#endif

@end
