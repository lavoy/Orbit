//
//  ORBFileWrapper.m
//  Orbit
//
//  Created by Levin, Joel A on 3/24/13.
//  Copyright (c) 2013 Andy LaVoy. All rights reserved.
//

#import "ORBFileWrapper.h"

static NSByteCountFormatter *byteCountFormatter = nil;
static NSDateFormatter *dateFormatter = nil;
static NSCache *fileTypeIconCache = nil;


@interface ORBFileWrapper ()

@property (strong) NSString *formattedFileSize;
@property (strong) NSString *formattedCreatedAtDate;
@property (strong) NSAttributedString *attributedFormattedSizeAndCreated;

@end


@implementation ORBFileWrapper

+ (ORBFileWrapper *)wrapperForFile:(ANKFile *)file {
	ORBFileWrapper *wrapper = [[ORBFileWrapper alloc] init];
	wrapper.file = file;
	return wrapper;
}


+ (NSPredicate *)filterPredicateForQuery:(NSString *)query {
	return [NSPredicate predicateWithFormat:@"name contains[c] %@", query];
}

- (NSString *)privateImageName {
    return self.isPublic ? @"group" : @"lock";
}


- (NSString *)privateImageHighlightedName {
	return self.isPublic ? @"group-white" : @"lock-white";
}


- (NSURL *)URL {
    return self.file.permanentURL ?: self.file.URL;
}


- (NSURL *)sharableURL {
    return [self shortURLWithExtension] ?: [self URL];
}


- (NSURL *)shortURLWithExtension {
    if (self.file.shortURL) {
        NSString *pathExtension = [self.name.pathExtension lowercaseString];
        if ([pathExtension length]) {
            return [NSURL URLWithString:[NSString stringWithFormat:@"%@.%@", [self.file.shortURL absoluteString], pathExtension]];
        } else {
            return self.file.shortURL;
        }
    } else {
        return nil;
    }
}


- (NSString *)formattedSizeAndCreatedAt {
    // 12 MB, modified 1/2/13 4:50 PM
    return [NSString stringWithFormat:@"%@ — %@", [self formattedSize], [self formattedCreatedAt]];
}


- (NSString *)formattedCreatedAt {
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"M/d/YY h:mm a"];
	});
	
	if (!self.formattedCreatedAtDate) {
		self.formattedCreatedAtDate = [dateFormatter stringFromDate:self.file.createdAt];
	}
	
	return self.formattedCreatedAtDate;
}


- (NSString *)formattedSize {
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		byteCountFormatter = [[NSByteCountFormatter alloc] init];
	});
	
	if (!self.formattedFileSize) {
		self.formattedFileSize = [byteCountFormatter stringFromByteCount:self.file.sizeBytes];
	}
	
	return self.formattedFileSize;
}


- (NSString *)name {
	return self.isUploading ? [self.localURL lastPathComponent] : self.file.name;
}


- (BOOL)isPublic {
	return self.isUploading ? self.isUploadingAsPublic : self.file.isPublic;
}

// QLPreviewItem on OSX, regular method on iOS

- (NSURL *)previewItemURL {
	NSURL *URL = self.URL;
	
    if (![ORBPreferences preferences].fullSizeGalleryImagesPref) {
        if (self.file.mediumImageThumbnailFile) {
            URL = self.file.mediumImageThumbnailFile.permanentURL ?: self.file.mediumImageThumbnailFile.URL;
        }
    }
	
	return URL;
}

#ifdef __IPHONE_OS_VERSION_MIN_REQUIRED

- (UIImage *)iconImage {
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		fileTypeIconCache = [[NSCache alloc] init];
	});
	
    NSString *pathExtension = [self.name.pathExtension lowercaseString];
	UIImage *fileIcon = [fileTypeIconCache objectForKey:pathExtension];
	
	if (!fileIcon && pathExtension) {
        NSString *dummyPath = [@"~/foo" stringByAppendingPathExtension:pathExtension]; // doesn't exist
        NSURL *URL = [NSURL fileURLWithPath:dummyPath];
        UIDocumentInteractionController *dic = [UIDocumentInteractionController interactionControllerWithURL:URL];
        NSArray *systemIconImages = dic.icons;
        
        fileIcon = [systemIconImages lastObject];   // the largest icon is last
        
		[fileTypeIconCache setObject:fileIcon forKey:pathExtension];
	}
    
    return fileIcon;
}

- (NSURL *)thumbnailURL {
	NSURL *URL = nil;
	
	if (self.file.smallImageThumbnailFile) {
		URL = self.file.smallImageThumbnailFile.permanentURL ?: self.file.smallImageThumbnailFile.URL;
	}
	
	return URL;
}

- (NSAttributedString *)attributedFormattedSizeAndCreatedAt {
	if (!self.attributedFormattedSizeAndCreated) {
		NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:[self formattedSizeAndCreatedAt]];
        NSInteger formattedSizeLength = [[self formattedSize] length];
		[attributedString addAttributes:@{NSFontAttributeName: [UIFont fontWithName:kORBFontMedium size:14.0], NSForegroundColorAttributeName: [UIColor grayColor]} range:NSMakeRange(0, formattedSizeLength)];
		[attributedString addAttributes:@{NSFontAttributeName: [UIFont fontWithName:kORBFontRegular size:14.0], NSForegroundColorAttributeName: [UIColor colorWithWhite:0.6 alpha:1.0]} range:NSMakeRange(formattedSizeLength + 1, [attributedString length] - (formattedSizeLength + 1))];
		self.attributedFormattedSizeAndCreated = attributedString;
	}
	return self.attributedFormattedSizeAndCreated;
}

#else

+ (NSSize)iconSize {
	return NSMakeSize(16.0, 16.0);
}


- (NSImage *)iconImage {
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		fileTypeIconCache = [[NSCache alloc] init];
	});
	
    NSString *pathExtension = self.name.pathExtension;
	NSImage *fileIcon = [fileTypeIconCache objectForKey:pathExtension];
	
	if (!fileIcon) {
		fileIcon = [[NSWorkspace sharedWorkspace] iconForFileType:pathExtension];
		[fileIcon setSize:[[self class] iconSize]];
		[fileTypeIconCache setObject:fileIcon forKey:pathExtension];
	}
    
    return fileIcon;
}

#pragma mark - QLPreviewItem

- (NSString *)previewItemTitle {
    return self.name;
}

#endif

@end
