//
//  NBDataSource.m
//  NetBox
//
//  Created by Andy LaVoy on 3/30/13.
//  Copyright (c) 2013 Andy LaVoy. All rights reserved.
//

#import "ORBDataSource.h"
#import "SSKeychain.h"
#import <ADNKit/NSArray+ANKAdditions.h>
#import <ADNKit/ANKAPIResponseMeta.h>
#import "ORBUtilities.h"
#import "ORBExclusionRule.h"

#ifdef __IPHONE_OS_VERSION_MIN_REQUIRED

#import "ORBAuthViewController.h"

#endif

@interface ORBDataSource ()

@property (nonatomic, strong) NSMutableArray *allFilesArray;
@property (nonatomic, strong) NSArray *searchResultsArray;
@property (nonatomic, strong) NSString *lastSearchQuery;
@property (assign) NSUInteger maxFileSize;
@property (assign) NSUInteger requestsCount;
@property (assign) BOOL isRunningBatchRequests;
@property (assign) BOOL didFetchExclusions;
@property (nonatomic, strong) NSString *minFileID;
@property (nonatomic, strong) NSMutableArray *pageCounts;

@property (nonatomic, strong) NSArray *imageExtensions;

- (void)refreshSearchResults;
- (NSArray *)filesArray;
- (void)requestPreflight;
- (BOOL)requestPostflightValidatingMeta:(ANKAPIResponseMeta *)iMeta;
- (ANKClient *)paginatedClient;

@end

#ifdef __IPHONE_OS_VERSION_MIN_REQUIRED
static NSString *const kORBClientId                     = @"GcRWE4CqHeaSqAZU77r4gE36VMgnxKug";
static NSString *const kORBPasswordGrantSecret          = @"frKehv6JdDH6LjxwhXQUs44CC6zP2AMA";
static NSString *const kORBKeychainServiceName			= @"Orbit for iOS";
#else
static NSString *const kORBClientId                     = @"a9FbMb4FGEFc2DL7Ke7Jr9qhHPq3qXHg";
static NSString *const kORBPasswordGrantSecret          = @"ujq4WRwGMX5cUmP8MS2Vpe7TZ6sGy8JX";
static NSString *const kORBKeychainServiceName			= @"Orbit";
#endif

static ANKAuthScope    kAuthScope                       = ANKAuthScopeBasic | ANKAuthScopeFiles;


@implementation ORBDataSource

- (id)init {
	if ((self = [super init])) {
		self.canRefreshFiles = YES;
		self.allFilesArray = [NSMutableArray array];
		self.pageCounts = [NSMutableArray array];
		self.client = [[ANKClient alloc] init];
		self.client.pagination = [ANKPaginationSettings settingsWithCount:kORBFilePageBatchSize];
        self.imageExtensions = @[@"png", @"jpeg", @"jpg", @"gif"];
	}
	return self;
}


- (NSArray *)filesArray {
	return (self.isFiltering ? self.searchResultsArray : self.allFilesArray);
}


- (NSArray *)imageFilesArray {
    return [[self filesArray] ank_filter:^BOOL(ORBFileWrapper *fileWrapper) {
        return [self isFileAnImage:fileWrapper];
    }];
}


#pragma mark - ORBFileWrapper Access


- (NSInteger)numberOfFiles {
    return [self.filesArray count];
}


- (NSInteger)numberOfImageFiles {
    return [[self imageFilesArray] count];
}


- (ORBFileWrapper *)fileAtIndex:(NSUInteger)index {
    ORBFileWrapper *file = nil;
    if ([self.filesArray count] > index) {
        file = self.filesArray[index];
    }
    return file;
}


- (ORBFileWrapper *)imageFileAtIndex:(NSUInteger)index {
    NSArray *imageFiles = [self imageFilesArray];
    ORBFileWrapper *file = nil;
    if ([imageFiles count] > index) {
        file = imageFiles[index];
    }
    return file;
}


- (void)mapImageFiles:(id (^)(id object))mapBlock {
    [[self imageFilesArray] ank_map:mapBlock];
}


- (ORBFileWrapper *)fileWithID:(NSString *)fileID {
	NSArray *filterResults = [self.allFilesArray filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"file.fileID = %@", fileID]];
	return filterResults.count > 0 ? filterResults[0] : nil;
}


- (NSArray *)filesAtIndeces:(NSIndexSet *)iIndexSet {
    NSMutableArray *files = [NSMutableArray array];
    [iIndexSet enumerateIndexesUsingBlock:^(NSUInteger index, BOOL *stop) {
        [files addObject:[self fileAtIndex:index]];
    }];
    return files;
}


- (NSArray *)draggableFilesAtIndeces:(NSIndexSet *)iIndexSet {
	return [[self filesAtIndeces:iIndexSet] ank_filter:^BOOL(ORBFileWrapper *file) {
		return !file.isUploading && !file.isDownloading;
	}];
}


- (NSUInteger)indexOfFile:(ORBFileWrapper *)fileWrapper {
	return [self.filesArray indexOfObject:fileWrapper];
}


- (NSUInteger)indexOfImageFile:(ORBFileWrapper *)fileWrapper {
	return [[self imageFilesArray] indexOfObject:fileWrapper];
}


- (BOOL)isFileAnImage:(ORBFileWrapper *)fileWrapper {
    if (fileWrapper.isUploading) {
        return NO;
    } else {
        return [self.imageExtensions containsObject:[[[fileWrapper name] pathExtension] lowercaseString]];
    }
}


- (void)requestPreflight {
	if (self.isRunningBatchRequests) return;
	
	@synchronized (self) {
		self.requestsCount++;
		self.isRunningRequest = YES;
	}
}


- (BOOL)requestPostflightValidatingMeta:(ANKAPIResponseMeta *)iMeta {
	if (self.isRunningBatchRequests) return [self validateMeta:iMeta];
	
	@synchronized (self) {
		self.requestsCount--;
		self.isRunningRequest = self.requestsCount > 0;
	}
    
    return [self validateMeta:iMeta];
}


- (BOOL)validateMeta:(ANKAPIResponseMeta *)iMeta {
    BOOL isValid = YES;
    
    if (iMeta) {
        switch ([iMeta errorType]) {
            case ANKErrorTypeInvalidToken:
            case ANKErrorTypeNotAuthorized:
            case ANKErrorTypeTokenExpired:
                isValid = NO;
                break;
                
            default:
                break;
        }
    }
    
    if (!isValid) {
        NSLog(@"logging user out for invalid meta");
        [[ORBAppDelegate sharedAppDelegate] logout:nil];
    }
    
    return isValid;
}


- (void)filterForSearchQuery:(NSString *)searchQuery {
	self.isFiltering = YES;
    if (searchQuery.length > 0) {
        self.searchResultsArray = [self.allFilesArray filteredArrayUsingPredicate:[ORBFileWrapper filterPredicateForQuery:searchQuery]];
    } else {
        self.searchResultsArray = self.allFilesArray;
    }
	self.lastSearchQuery = searchQuery;
}


- (void)stopFiltering {
	self.isFiltering = NO;
	self.searchResultsArray = nil;
	self.lastSearchQuery = nil;
}


- (void)refreshSearchResults {
	if (self.isFiltering) {
		[self filterForSearchQuery:self.lastSearchQuery];
	}
}


- (void)dropPagesAfterPage:(NSUInteger)page {
	@synchronized (self.allFilesArray) {
		if (self.extraPagesLoaded > 0) {
			NSUInteger filesCount = 0;
			for (NSUInteger pageIndex = page + 1; pageIndex < self.extraPagesLoaded + 1; pageIndex++) {
				filesCount += [self.pageCounts[pageIndex] unsignedIntegerValue];
			}
            NSUInteger dropLocation = self.allFilesArray.count - filesCount;
            if (dropLocation < self.allFilesArray.count) {  // w/ overflow this isn't guaranteed to happen
                [self.allFilesArray removeObjectsInRange:NSMakeRange(dropLocation, filesCount)];
                [self refreshSearchResults];
                self.extraPagesLoaded = page;
                [self.pageCounts removeObjectsInRange:NSMakeRange(page + 1, self.pageCounts.count - (page + 1))];
                ORBFileWrapper *file = [self.allFilesArray lastObject];
                self.minFileID = file.file.fileID;
                self.moreFilesAvailable = YES;
            }
		}
	}
}


- (ANKClient *)paginatedClient {
	return [self.client clientWithPagination:[ANKPaginationSettings settingsWithSinceID:nil beforeID:self.minFileID count:kORBFilePageBatchSize]];
}


#pragma mark - Public Endpoints

- (void)authenticateWithUsername:(NSString *)username
                        password:(NSString *)password
                         success:(ORBSuccessBlock)successBlock
                         failure:(ORBFailureBlock)failureBlock {
	[self requestPreflight];
    
    // authenticate, calling the handler block when complete
    [self.client authenticateUsername:username password:password clientID:kORBClientId passwordGrantSecret:kORBPasswordGrantSecret authScopes:kAuthScope completionHandler:^(BOOL success, NSError *error) {
		[self requestPostflightValidatingMeta:nil];
        if (success) {
            [SSKeychain setPassword:self.client.accessToken forService:kORBKeychainServiceName account:self.client.authenticatedUser.username];
            
            if (successBlock) {
                successBlock();
            }
        } else if (failureBlock) {
            failureBlock(error);
        }
    }];
}


- (void)logInWithCompletion:(void (^)(BOOL, NSError *))completionBlock {
	NSArray *accountNames = [SSKeychain accountsForService:kORBKeychainServiceName];
	NSString *username = [[accountNames lastObject] objectForKey:@"acct"];
	NSString *tokenFromKeychain = [SSKeychain passwordForService:kORBKeychainServiceName account:username];
	if (tokenFromKeychain) {
		[self requestPreflight];
		[self.client logInWithAccessToken:tokenFromKeychain completion:^(BOOL succeeded, ANKAPIResponseMeta *meta, NSError *error) {
			[self requestPostflightValidatingMeta:meta];
			if (completionBlock) {
				completionBlock(succeeded, error);
			}
		}];
	} else {
		if (completionBlock) {
			completionBlock(NO, nil);
		}
	}
}


- (void)logOut {
	if (![SSKeychain deletePasswordForService:kORBKeychainServiceName account:self.client.authenticatedUser.username]) {
		// if the keychain item wasn't found, try again with 1.0-style account names
		[SSKeychain deletePasswordForService:kORBKeychainServiceName account:[NSString stringWithFormat:@"@%@", self.client.authenticatedUser.username]];
	}
	[self.client logOut];
	[self stopFiltering];
	[self.allFilesArray removeAllObjects];
}


- (void)fetchFilesWithSuccess:(ORBSuccessBlock)successBlock {
	self.canRefreshFiles = NO;
	
	if (self.extraPagesLoaded > 0) {
		self.isRunningBatchRequests = YES;
		self.isRunningRequest = YES;
	}
	
	[self fetchFilesWithClient:self.client success:^(NSArray *files) {
		NSMutableArray *allLoadedFiles = [NSMutableArray arrayWithArray:files];
		self.pageCounts[0] = @(files.count);
		
		if (self.extraPagesLoaded > 0) {
			__block NSUInteger pagesRefreshed = 0;
			
			dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
			dispatch_queue_t queue = dispatch_queue_create("paginationQueue", DISPATCH_QUEUE_SERIAL);
			
			dispatch_async(queue, ^{
				while (pagesRefreshed < self.extraPagesLoaded && self.moreFilesAvailable) {
					[self fetchFilesWithClient:[self paginatedClient] success:^(NSArray *files) {
						self.pageCounts[pagesRefreshed + 1] = @(files.count);
						pagesRefreshed++;
						//NSLog(@"loaded page %li of %li", pagesRefreshed, self.extraPagesLoaded);
						[allLoadedFiles addObjectsFromArray:files];
						dispatch_semaphore_signal(semaphore);
					}];
					
					dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
				}
				
				dispatch_async(dispatch_get_main_queue(), ^{
					self.allFilesArray = allLoadedFiles;
					self.canRefreshFiles = YES;
					self.isRunningRequest = NO;
					if (successBlock) {
						successBlock();
					}
				});
			});			
		} else {
#ifdef __IPHONE_OS_VERSION_MIN_REQUIRED
            if (self.client.networkReachabilityStatus != AFNetworkReachabilityStatusNotReachable) {
                self.allFilesArray = allLoadedFiles;
            }
#else
			self.allFilesArray = allLoadedFiles;
#endif
			self.canRefreshFiles = YES;
			if (successBlock) {
				successBlock();
			}
		}
	}];
	
}


- (void)fetchFilesWithClient:(ANKClient *)client success:(ORBFilesSuccessBlock)successBlock {
	if ([NSThread currentThread] != [NSThread mainThread]) {
		[self performSelectorOnMainThread:@selector(requestPreflight) withObject:nil waitUntilDone:YES];
	} else {
		[self requestPreflight];
	}
	
	NSMutableArray *loadedFiles = [NSMutableArray array];
    
    [client fetchCurrentUserFilesWithCompletion:^(NSArray *files, ANKAPIResponseMeta *meta, NSError *error) {
		__block BOOL isValid = YES;
		
		if ([NSThread currentThread] != [NSThread mainThread]) {
			dispatch_sync(dispatch_get_main_queue(), ^{
				isValid = [self requestPostflightValidatingMeta:meta];
			});
		} else {
			isValid = [self requestPostflightValidatingMeta:meta];
		}
		
        if (isValid) {
			self.minFileID = meta.minID;
			self.moreFilesAvailable = meta.moreDataAvailable;
				
			NSArray *enabledRules = [[ORBPreferences preferences] enabledExclusionRules];
			files = [files ank_filter:^BOOL(ANKFile *file) {
				BOOL shouldInclude = YES;
				for (ORBExclusionRule *rule in enabledRules) {
					shouldInclude = ![rule shouldExcludeFile:file];
					if (!shouldInclude) {
						break;
					}
				}
				return shouldInclude;
			}];
			
			[loadedFiles addObjectsFromArray:[files ank_map:^id(ANKFile *file) {
				return [ORBFileWrapper wrapperForFile:file];
			}]];
			[self refreshSearchResults];
			
			if (successBlock) {
				successBlock(loadedFiles);
			}
            
            [self fetchFileExclusionsIfNecessary];
        }
		self.canRefreshFiles = YES;
    }];
}


- (void)fetchNextFilesBatchWithSuccess:(ORBSuccessBlock)successBlock {
	ANKClient *paginatedClient = [self paginatedClient];
	self.canRefreshFiles = NO;
	
	[self fetchFilesWithClient:paginatedClient success:^(NSArray *files) {
		self.pageCounts[self.extraPagesLoaded + 1] = @(files.count);
		self.extraPagesLoaded++;
		[self.allFilesArray addObjectsFromArray:files];
		if (successBlock) {
			successBlock();
		}
		self.canRefreshFiles = YES;
	}];
}


- (void)fetchStorageFreeSpaceForStorageInfo:(ORBStorageInfo *)storageInfo completion:(ORBSuccessBlock)completionBlock {
	[self requestPreflight];
    [self.client fetchTokenStatusForCurrentUserWithCompletion:^(id responseObject, ANKAPIResponseMeta *meta, NSError *error) {
        if ([self requestPostflightValidatingMeta:meta]) {
            if ([responseObject isKindOfClass:[ANKTokenStatus class]]) {
                ANKTokenStatus *tokenStatus = responseObject;
				
				self.maxFileSize = tokenStatus.limits.fileSizeLimit;
                
                NSByteCountFormatter *formatter = [[NSByteCountFormatter alloc] init];
                ANKStorage *storage = tokenStatus.storage;
                
                if (storageInfo) {
                    storageInfo.lastStorageAvailable = [formatter stringFromByteCount:storage.available + storage.used];
                    storageInfo.lastStorageUsed = [formatter stringFromByteCount:storage.used];
                    storageInfo.lastStoragePercentage = (CGFloat)((CGFloat)storage.used / ((CGFloat)storage.available + (CGFloat)storage.used)) * 100.0;
                }
                
                if (completionBlock) {
                    completionBlock();
                }
            }
        }
    }];
}


- (void)deleteServerFile:(ORBFileWrapper *)fileToDelete
                 success:(ORBSuccessBlock)successBlock
                 failure:(ORBFailureBlock)failureBlock {
    if (fileToDelete) {
		[self requestPreflight];
        [self.client deleteFile:fileToDelete.file completion:^(id responseObject, ANKAPIResponseMeta *meta, NSError *error) {
            if ([self requestPostflightValidatingMeta:meta]) {
                if (responseObject) {
                    @synchronized(self.allFilesArray) {
                        [self.allFilesArray removeObject:fileToDelete];
                    }
					[self refreshSearchResults];
                    
                    if (successBlock) {
                        successBlock();
                    }
                } else if (failureBlock) {
                    if (meta.errorMessage) {
                        error = [self errorWithLocalizedDescription:[NSString stringWithFormat:@"App.net Error: %@", meta.errorMessage]];
                    }
                    
                    failureBlock(error);
                }
            }
        }];
    }
}


- (void)updateServerFile:(ORBFileWrapper *)fileToUpdate
                asPublic:(BOOL)isPublic
                 success:(ORBSuccessBlock)successBlock
                 failure:(ORBFailureBlock)failureBlock {
    if (fileToUpdate) {
		[self requestPreflight];
        [self.client updateFileWithID:fileToUpdate.file.fileID name:fileToUpdate.name isPublic:isPublic completion:^(id responseObject, ANKAPIResponseMeta *meta, NSError *error) {
            if ([self requestPostflightValidatingMeta:meta]) {
                if ([responseObject isKindOfClass:[ANKFile class]]) {
                    ORBFileWrapper *responseFile = [ORBFileWrapper wrapperForFile:responseObject];
                    
                    @synchronized(self.allFilesArray) {
                        [self.allFilesArray replaceObjectAtIndex:[self.allFilesArray indexOfObject:fileToUpdate] withObject:responseFile];
                    }
					
					[self refreshSearchResults];
                    
                    if (successBlock) {
                        successBlock();
                    }
                } else if (failureBlock) {
                    failureBlock(error);
                }
            }
        }];
    }
}


- (void)createServerFileFromWrapper:(ORBFileWrapper *)fileWrapper
                           progress:(void (^)(CGFloat iProgress))progressBlock
                         completion:(void (^)(ORBFileWrapper *uploadedFile, NSError *error))completionBlock {
	NSUInteger fileSize = 0;
    if ([self isFileSmallEnoughToUpload:fileWrapper.localURL outputFileSize:&fileSize]) {
        NSDictionary *metadata = @{@"type": @"net.orbit.file", @"public" : @(fileWrapper.isPublic)};
		
		[self requestPreflight];
		
		if (progressBlock) {
			progressBlock(0.0);
		}
        
        fileWrapper.currentRequest = [self.client createFileWithContentsOfURL:fileWrapper.localURL metadata:metadata progress:^(NSUInteger bytesWritten, long long totalBytesWritten, long long totalBytesExpectedToWrite) {
            if (progressBlock) {
                CGFloat percentage = (CGFloat) totalBytesWritten / (CGFloat) totalBytesExpectedToWrite;
                progressBlock(percentage);
            }
        } completion:^(ANKFile *file, ANKAPIResponseMeta *meta, NSError *error) {
            if ([self requestPostflightValidatingMeta:meta]) {
                if (progressBlock) {
                    progressBlock(1.0);
                }
                
                ORBFileWrapper *uploadedFile = nil;
                
                if ([file isKindOfClass:[ANKFile class]]) {
                    uploadedFile = [ORBFileWrapper wrapperForFile:file];
                    
                    @synchronized(self.allFilesArray) {
						NSUInteger fileWrapperIndex = [self.allFilesArray indexOfObject:fileWrapper];
						if (fileWrapperIndex != NSNotFound) {
							[self.allFilesArray replaceObjectAtIndex:fileWrapperIndex withObject:uploadedFile];
							[self refreshSearchResults];
						}
                    }
                }
                
                if (completionBlock) {
                    completionBlock(uploadedFile, error);
                }
            }
        }];
    } else if (completionBlock) {
        NSByteCountFormatter *formatter = [[NSByteCountFormatter alloc] init];
        NSString *errorString = [NSString stringWithFormat:@"App.net only allows files smaller than %@ to be uploaded. %@ is larger than that limit (%@) and cannot be uploaded.", [formatter stringFromByteCount:self.maxFileSize], [fileWrapper.localURL lastPathComponent], [formatter stringFromByteCount:fileSize]];
        
        completionBlock(nil, [self errorWithLocalizedDescription:errorString]);
    }
}


- (void)renameFile:(ORBFileWrapper *)file toName:(NSString *)renamedName success:(ORBSuccessBlock)successBlock failure:(ORBFailureBlock)failureBlock {
	[self requestPreflight];
	[self.client updateFileWithID:file.file.fileID name:renamedName isPublic:file.isPublic completion:^(id responseObject, ANKAPIResponseMeta *meta, NSError *error) {
		[self requestPostflightValidatingMeta:meta];
		if (!error) {
			file.file.name = renamedName;
		}
		
        if (responseObject) {
            if (successBlock) {
                successBlock();
            }
        } else if (failureBlock) {
            failureBlock(error);
        }
	}];
}


- (void)fetchFileExclusionsIfNecessary {
    if (!self.didFetchExclusions) {
        self.didFetchExclusions = YES;
        
        NSMutableURLRequest *request = [self.client requestWithMethod:@"GET" path:@"http://orbitapp.net/api/ExclusionMap.json" parameters:nil];
        AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
        
        NSString *path = [[ORBPreferences preferences] exclusionMapLocalFilePath];
        operation.outputStream = [NSOutputStream outputStreamToFileAtPath:path append:NO];
        
        [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
            [[ORBPreferences preferences] resetExclusionRules];
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            self.didFetchExclusions = NO;
        }];
        
        [self.client enqueueHTTPRequestOperation:operation];
    }
}

#pragma mark - Private Methods

- (BOOL)isFileSmallEnoughToUpload:(NSURL *)fileURL outputFileSize:(NSUInteger *)fileSize {
    BOOL isSmallEnough = YES;
    
    NSDictionary *fileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:fileURL.path error:nil];
    
    if (fileAttributes && self.maxFileSize > 0) {
        NSUInteger aFileSize = [[fileAttributes objectForKey:NSFileSize] unsignedIntegerValue];
        isSmallEnough = aFileSize <= self.maxFileSize;
		if (fileSize) {
			*fileSize = aFileSize;
		}
    }
    
    return isSmallEnough;
}


- (ORBFileWrapper *)insertWrapperForCreatingFileFromURL:(NSURL *)fileURL isPublic:(BOOL)isPublic {
	ORBFileWrapper *fileWrapper = [[ORBFileWrapper alloc] init];
	fileWrapper.localURL = fileURL;
	fileWrapper.isUploading = YES;
	fileWrapper.isUploadingAsPublic = isPublic;
	
	@synchronized (self.allFilesArray) {
		[self.allFilesArray insertObject:fileWrapper atIndex:0];
		[self refreshSearchResults];
	}
	
	return fileWrapper;
}


- (void)removeFileWrapper:(ORBFileWrapper *)fileWrapper {
    @synchronized (self.allFilesArray) {
        [self.allFilesArray removeObject:fileWrapper];
        [self refreshSearchResults];
    }
}


- (void)cancelRequestForFile:(ORBFileWrapper *)fileWrapper {
	if (fileWrapper.isDownloading) {
		fileWrapper.isDownloading = NO;
	}
	
	if (fileWrapper.isUploading) {
		fileWrapper.isUploading = NO;
	}
	
	if (fileWrapper.currentRequest) {
		[fileWrapper.currentRequest cancel];
	}
}


- (NSError *)errorWithLocalizedDescription:(NSString *)errorDescription {
    if (!errorDescription) {
        errorDescription = @"Unknown Error";
    }
    return [NSError errorWithDomain:@"Orbit" code:200 userInfo:@{NSLocalizedDescriptionKey: errorDescription}];
}


- (NSMutableDictionary *)userInfoDictionary {
    return [NSMutableDictionary dictionaryWithDictionary:@{@"appVersion" : [ORBUtilities appVersion], @"osxVersion" : [ORBUtilities osxVersion], @"deviceID" : [ORBUtilities deviceID]}];
}

#ifdef __IPHONE_OS_VERSION_MIN_REQUIRED

- (ORBAuthViewController *)authControllerWithSuccess:(ORBSuccessBlock)successBlock {
    ORBAuthViewController *authVC = [[ORBAuthViewController alloc] initWithClient:self.client
                                                                         clientID:kORBClientId
                                                              passwordGrantSecret:kORBPasswordGrantSecret
                                                                       authScopes:kAuthScope
                                                                       completion:^(ANKClient *authedClient, NSError *error, ORBAuthViewController *controller) {
        
        if (error) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Login error" message:[error localizedDescription] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [alert show];
        } else {
            [SSKeychain setPassword:authedClient.accessToken forService:kORBKeychainServiceName account:authedClient.authenticatedUser.username];
            
            if (successBlock) {
                successBlock();
            }
        }
    }];
    
    return authVC;
}

#else

#pragma mark - Mac Only Methods

- (void)downloadFile:(ORBFileWrapper *)file
         toDirectory:(NSString *)toDir
            progress:(void (^)(CGFloat iProgress))progressBlock
		  completion:(void (^)(NSError *error))completionBlock {
    [self requestPreflight];
    NSURLRequest *request = [NSURLRequest requestWithURL:[file URL]];
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    __block NSString *finalPath = [toDir stringByAppendingPathComponent:file.name];
    NSString *downloadPath = [finalPath stringByAppendingFormat:@".odownload"];
    
    __weak AFHTTPRequestOperation *aWeakOperation = operation;
    __block NSDate *lastUpdatedFilesystemDate = [NSDate date];
    ORBDownloadProgressBlock downloadProgressBlock = ^(NSUInteger bytesRead, long long totalBytesRead, long long totalBytesExpectedToRead) {
        CGFloat progress = (CGFloat) totalBytesRead / (CGFloat) totalBytesExpectedToRead;
        
        if ([[NSDate date] timeIntervalSinceDate:lastUpdatedFilesystemDate] > 0.10 || progress == 1.0 || progress == 0.0) {
            if (progressBlock) {
                progressBlock(progress);
            }
            
            lastUpdatedFilesystemDate = [NSDate date];
            NSDictionary *newAttributes = [self fileAttributesForFileAtPath:downloadPath showingProgress:progress];
            
            NSError *error = nil;
            [fileManager setAttributes:newAttributes ofItemAtPath:downloadPath error:&error];
            if (error) {
                NSLog(@"Error updating file attributes: %@", error);
                [aWeakOperation cancel];
            }
        }
    };
    
    operation.outputStream = [NSOutputStream outputStreamToFileAtPath:downloadPath append:NO];
    [operation setDownloadProgressBlock:downloadProgressBlock];
    
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        [self requestPostflightValidatingMeta:nil];
        
        NSError *moveError = nil;
        NSInteger fileSuffix = 2;
        while ([fileManager fileExistsAtPath:finalPath]) {
            NSString *extension = [file.name pathExtension];
            NSString *frontOfFile = [file.name stringByDeletingPathExtension];
            
            finalPath = [toDir stringByAppendingPathComponent:[NSString stringWithFormat:@"%@ %ld.%@", frontOfFile, fileSuffix, extension]];
            fileSuffix ++;
        }
        
        BOOL didMoveFile = [fileManager moveItemAtPath:downloadPath toPath:finalPath error:&moveError];
        
        if (didMoveFile) {
            NSLog(@"successfully wrote file to destination: %@", toDir);
        } else {
            NSLog(@"error moving file after download: %@", moveError);
        }
        
        if (completionBlock) {
            completionBlock(nil);
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if ([fileManager fileExistsAtPath:downloadPath]) {  // cleanup after error
            [fileManager removeItemAtPath:downloadPath error:nil];
        }
        
        [self requestPostflightValidatingMeta:nil];
        
        if (completionBlock) {
            completionBlock(error);
        }
    }];
    
    [fileManager createFileAtPath:downloadPath contents:nil attributes:nil];
    downloadProgressBlock(0, 0, 1);
    
	self.canRefreshFiles = NO;
	file.currentRequest = operation;
    [operation start];
}


- (NSDictionary *)fileAttributesForFileAtPath:(NSString *)iPath showingProgress:(CGFloat)iProgress {
    NSString *extendAttributesKey = @"NSFileExtendedAttributes";
    NSDictionary *originalFileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:iPath error:nil];
    
    NSDictionary *extendAttributes = [originalFileAttributes objectForKey:extendAttributesKey];
    NSMutableDictionary *mutableExtendAttributes = [NSMutableDictionary dictionaryWithDictionary:extendAttributes];
    // create data of progress value
    NSString *progressString = [NSString stringWithFormat:@"%1.5f", iProgress];
    NSData *progressData = [progressString dataUsingEncoding:NSASCIIStringEncoding];
    // change the progress
    [mutableExtendAttributes setObject:progressData forKey:@"com.apple.progress.fractionCompleted"];
    
    NSMutableDictionary *newFileAttributes = [NSMutableDictionary dictionaryWithDictionary:originalFileAttributes];
    // change extend attributes
    [newFileAttributes setObject:mutableExtendAttributes forKey:extendAttributesKey];
    
    NSDate *fileCreationDate;
    if (iProgress >= 0.0 && iProgress < 1.0) {
        // change file/dir create date to the special one otherwise progress bar will not show
        fileCreationDate = [NSDate dateWithString:@"1984-01-24 08:00:00 +0000"];
    } else {
        fileCreationDate = [NSDate date];
    }
    [newFileAttributes setObject:fileCreationDate forKey:NSFileCreationDate];
    
    return newFileAttributes;
}

#endif


@end
