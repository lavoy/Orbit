//
//  ORBMasterViewController.h
//  Orbit iOS
//
//  Created by Andy LaVoy on 4/25/13.
//  Copyright (c) 2013 Log Cabin. All rights reserved.
//

#import "ORBTableViewController.h"

@interface ORBFilesViewController : ORBTableViewController <UISplitViewControllerDelegate>

- (id)initWithDataSource:(ORBDataSource *)dataSource;
- (void)fetchFilesWithCompletion:(ORBVoidBlock)completion;
- (void)reloadData;

- (void)uploadFileFromURL:(NSURL *)fileURL
               completion:(void (^)(ORBFileWrapper *uploadedFile, NSError *error))completionBlock;

- (void)possiblyDropPages;

@end
