//
//  NBDataSource.h
//  NetBox
//
//  Created by Andy LaVoy on 3/30/13.
//  Copyright (c) 2013 Andy LaVoy. All rights reserved.
//

#import "ORBStorageInfo.h"
#import <Foundation/Foundation.h>


@class ORBFileWrapper;
@class ORBAuthViewController;

typedef void (^ORBFailureBlock)(NSError *error);
typedef void (^ORBSuccessBlock)();
typedef void (^ORBFilesSuccessBlock)(NSArray *files);
typedef void (^ORBDownloadProgressBlock)(NSUInteger bytesRead, long long totalBytesRead, long long totalBytesExpectedToRead);
static NSUInteger const kORBFilePageBatchSize = 50;


@interface ORBDataSource : NSObject

@property (assign) BOOL isRunningRequest;
@property (assign) BOOL isFiltering;
@property (assign) BOOL canRefreshFiles;
@property (assign) BOOL moreFilesAvailable;
@property (assign) NSUInteger extraPagesLoaded;
@property (strong) ANKClient *client;

#pragma mark - ORBFileWrapper Access

- (NSInteger)numberOfFiles;
- (NSInteger)numberOfImageFiles;
- (ORBFileWrapper *)fileAtIndex:(NSUInteger)index;
- (ORBFileWrapper *)imageFileAtIndex:(NSUInteger)index;
- (ORBFileWrapper *)fileWithID:(NSString *)fileID;
- (NSArray *)filesAtIndeces:(NSIndexSet *)iIndexSet;
- (NSArray *)draggableFilesAtIndeces:(NSIndexSet *)iIndexSet;
- (NSUInteger)indexOfFile:(ORBFileWrapper *)fileWrapper;
- (NSUInteger)indexOfImageFile:(ORBFileWrapper *)fileWrapper;
- (BOOL)isFileAnImage:(ORBFileWrapper *)fileWrapper;
- (void)dropPagesAfterPage:(NSUInteger)page;
- (void)mapImageFiles:(id (^)(id object))mapBlock;

- (ORBFileWrapper *)insertWrapperForCreatingFileFromURL:(NSURL *)fileURL isPublic:(BOOL)isPublic;
- (void)removeFileWrapper:(ORBFileWrapper *)fileWrapper;
- (void)cancelRequestForFile:(ORBFileWrapper *)fileWrapper;

- (void)filterForSearchQuery:(NSString *)searchQuery;
- (void)stopFiltering;

#pragma mark - Public Endpoints

- (void)authenticateWithUsername:(NSString *)username
                        password:(NSString *)password
                         success:(ORBSuccessBlock)successBlock
                         failure:(ORBFailureBlock)failureBlock;
- (void)logInWithCompletion:(void (^)(BOOL isLoggedIn, NSError *error))completionBlock;
- (void)logOut;

- (void)fetchFilesWithSuccess:(ORBSuccessBlock)successBlock;
- (void)fetchNextFilesBatchWithSuccess:(ORBSuccessBlock)successBlock;
- (void)fetchStorageFreeSpaceForStorageInfo:(ORBStorageInfo *)storageInfo
                                 completion:(ORBSuccessBlock)completionBlock;

- (void)deleteServerFile:(ORBFileWrapper *)fileToDelete
                 success:(ORBSuccessBlock)successBlock
                 failure:(ORBFailureBlock)failureBlock;
- (void)updateServerFile:(ORBFileWrapper *)fileToUpdate
                asPublic:(BOOL)isPublic
                 success:(ORBSuccessBlock)successBlock
                 failure:(ORBFailureBlock)failureBlock;

- (void)createServerFileFromWrapper:(ORBFileWrapper *)fileWrapper
                           progress:(void (^)(CGFloat iProgress))progressBlock
                         completion:(void (^)(ORBFileWrapper *uploadedFile, NSError *error))completionBlock;

- (void)renameFile:(ORBFileWrapper *)file
            toName:(NSString *)renamedName
           success:(ORBSuccessBlock)successBlock
           failure:(ORBFailureBlock)failureBlock;

#ifdef __IPHONE_OS_VERSION_MIN_REQUIRED

- (ORBAuthViewController *)authControllerWithSuccess:(ORBSuccessBlock)successBlock;

#else

- (void)downloadFile:(ORBFileWrapper *)iFile
         toDirectory:(NSString *)iToDir
            progress:(void (^)(CGFloat iProgress))iProgressBlock
		  completion:(void (^)(NSError *error))completionBlock;

#endif

@end
