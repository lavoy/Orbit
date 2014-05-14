//
//  ORBMasterViewController.m
//  Orbit iOS
//
//  Created by Andy LaVoy on 4/25/13.
//  Copyright (c) 2013 Log Cabin. All rights reserved.
//

#import "ORBFilesViewController.h"
#import "JJGWebViewController.h"
#import "MWPhotoBrowser.h"
#import "ORBFileCell.h"
#import "UIImageView+WebCache.h"
#import "SDWebImageManager.h"
#import "UIImage+Resizing.h"
#import "ORBPreferences.h"
#import "ORBSettingsViewController.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import "ADNActivityCollection.h"
#import "ORBPhotoBrowser.h"
#import "ORBNavigationBar.h"
#import "SDScreenshotCapture.h"

static NSString * const CellIdentifier  = @"Cell";

@interface ORBFilesViewController () <MWPhotoBrowserDelegate, UIActionSheetDelegate, UISearchDisplayDelegate, UISearchBarDelegate, UIAlertViewDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, SDWebImageManagerDelegate, UIPopoverControllerDelegate>

@property (nonatomic, weak) ORBDataSource *dataSource;
@property (nonatomic, copy) NSIndexPath *selectedFileIndexPath;
@property (nonatomic, copy) NSIndexPath *longPressedIndexPath;
@property (nonatomic, copy) NSIndexPath *renameFileIndexPath;
@property (nonatomic, strong) UISearchDisplayController *searchController;
@property (nonatomic, strong) UIActionSheet *fileActionActionSheet;
@property (nonatomic, strong) UIActionSheet *imageSourceActionSheet;
@property (nonatomic, strong) UIPopoverController *addFilesPopoverController;

@property (nonatomic, strong) NSMutableDictionary *imageURLsToIDs;  // temporary and managed

@end

@implementation ORBFilesViewController

- (id)initWithDataSource:(ORBDataSource *)dataSource {
    if (self = [super init]) {
        self.title = @"Files";
        self.dataSource = dataSource;
        self.tabBarItem = [[UITabBarItem alloc] initWithTitle:self.title image:[UIImage imageNamed:@"rocket"] tag:0];
        
        self.imageURLsToIDs = [[NSMutableDictionary alloc] init];
    }
    
    return self;
}
							
- (void)viewDidLoad {
    [super viewDidLoad];
	
	__weak ORBFilesViewController *wSelf = self;
    
    UILongPressGestureRecognizer *gestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
    gestureRecognizer.minimumPressDuration = 1.0;
    [self.tableView addGestureRecognizer:gestureRecognizer];
    
    UISearchBar *searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 0, self.view.frameWidth, 44)];
    searchBar.delegate = self;
    searchBar.placeholder = @"Filter";
    self.tableView.tableHeaderView = searchBar;
    
    for (UIView *searchBarSubview in searchBar.subviews) { // shitty but our only option right now
        if ([searchBarSubview isKindOfClass:[UITextField class]]) {
            UITextField *textField = (UITextField *)searchBarSubview;
            textField.font = [UIFont fontWithName:kORBFontMedium size:14];
			break;
        }
    }
    
    self.tableView.rowHeight = [ORBFileCell height];
    [self.tableView registerClass:[ORBFileCell class] forCellReuseIdentifier:CellIdentifier];
	self.tableView.separatorInset = UIEdgeInsetsMake(0.0, kFileCellIconSize + 14.0, 0.0, 0.0);
    
    self.searchController = [[UISearchDisplayController alloc] initWithSearchBar:searchBar contentsController:self];
    self.searchController.delegate = self;
    self.searchController.searchResultsDataSource = self;
    self.searchController.searchResultsDelegate = self;
    
    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.refreshControl handleControlEvents:UIControlEventValueChanged withBlock:^(UIRefreshControl *weakControl) {
        [wSelf fetchFilesWithCompletion:nil];
    }];
    
    UIBarButtonItem *addFileBBI = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd block:^(id weakSender) {
        BOOL hasCamera = [UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera];
        
        NSMutableArray *buttonTitles = [NSMutableArray arrayWithArray:@[@"Last Photo Taken", @"Choose Existing"]];
        if (hasCamera) {
            [buttonTitles addObject:@"Take Photo or Video"];
        }
        if ([self hasImageOnCliboard]) {
            [buttonTitles insertObject:@"Image from Clipboard" atIndex:0];
        }
        [buttonTitles addObject:@"Cancel"];
        
		if (!wSelf.imageSourceActionSheet) {
			wSelf.imageSourceActionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:wSelf cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:nil];
            
            for (NSString *buttonTitle in buttonTitles) {
                [wSelf.imageSourceActionSheet addButtonWithTitle:buttonTitle];
            }
            
            [wSelf.imageSourceActionSheet setCancelButtonIndex:[buttonTitles count] - 1];
			
			if (ORBIsPhone) {
				[wSelf.imageSourceActionSheet showInView:wSelf.navigationController.view];
			} else {
				[wSelf.imageSourceActionSheet showFromBarButtonItem:wSelf.navigationItem.rightBarButtonItem animated:YES];
			}
		} else {
			[wSelf.imageSourceActionSheet dismissWithClickedButtonIndex:-1 animated:YES];
		}
    }];
    self.navigationItem.rightBarButtonItem = addFileBBI;
    
    UIBarButtonItem *settingsBBI = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"gear"] style:UIBarButtonItemStylePlain block:^(id weakSender) {
        ORBSettingsViewController *settingsVC = [[ORBSettingsViewController alloc] initWithDataSource:wSelf.dataSource];
        ORBNavigationController *navController = [[ORBNavigationController alloc] initWithRootViewController:settingsVC];
		if (ORBIsPad) {
			navController.modalPresentationStyle = UIModalPresentationFormSheet;
		}
        [wSelf presentViewController:navController animated:YES completion:nil];
    }];
    settingsBBI.accessibilityLabel = @"Settings";
    self.navigationItem.leftBarButtonItem = settingsBBI;
    
    [SDImageCache sharedImageCache].maxCacheAge = 604800;       // 1 week
    [SDImageCache sharedImageCache].maxCacheSize = 20971520;    // 20 MB
    [SDWebImageManager sharedManager].delegate = self;
    [[SDWebImageManager sharedManager] setCacheKeyFilter:^NSString *(NSURL *url) {
        // given the url, find the id that owns it
        // this also will only cache images in the list, nothing in the full screen viewer
        return [self.imageURLsToIDs objectForKey:[url absoluteString]];
    }];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(shouldReloadFilesNotification:) name:kORBShouldReloadFilesNotification object:nil];
}


- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    self.selectedFileIndexPath = nil;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    [self possiblyDropPages];
    
#if DEBUG
    NSLog(@"%@", [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject]);
    [SDScreenshotCapture takeScreenshotToDocumentsDirectory];
#endif
}


- (void)shouldReloadFilesNotification:(NSNotification *)notification {
	[self fetchFilesWithCompletion:nil];
}


- (void)fetchFilesWithCompletion:(ORBVoidBlock)completion {
    [self.refreshControl beginRefreshing];
    [self.dataSource fetchFilesWithSuccess:^{
        [self.tableView reloadData];
        [self.refreshControl endRefreshing];
        [[ORBAppDelegate sharedAppDelegate] refreshStorageSpace];
        if (completion) {
            completion();
        }
    }];
}


- (void)reloadData {
    [self.tableView reloadData];
}


#pragma mark - Upload File

- (void)uploadImage:(UIImage *)image
         completion:(void (^)(ORBFileWrapper *uploadedFile, NSError *error))completionBlock {
    if (image) {
        [SVProgressHUD show];
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
            [dateFormat setDateFormat:@"yyyy-MM-dd hh:mm:ss a"];
            NSString *dateString = [dateFormat stringFromDate:[NSDate date]];
            
            NSString *tmpPath = [NSTemporaryDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"Orbit Image %@.jpg", dateString]];
            
            [UIImageJPEGRepresentation(image, 1.0) writeToFile:tmpPath atomically:YES];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [SVProgressHUD dismiss];
                [self uploadFileFromURL:[NSURL fileURLWithPath:tmpPath] completion:^(ORBFileWrapper *uploadedFile, NSError *error) {
                    [[NSFileManager defaultManager] removeItemAtPath:tmpPath error:nil];
                    if (completionBlock) {
                        completionBlock(uploadedFile, error);
                    }
                }];
            });
        });
    }
}

- (void)uploadVideoAtPath:(NSURL *)path
         completion:(void (^)(ORBFileWrapper *uploadedFile, NSError *error))completionBlock {
    if (path) {
        [self uploadFileFromURL:path completion:^(ORBFileWrapper *uploadedFile, NSError *error) {
            if (completionBlock) {
                completionBlock(uploadedFile, error);
            }
        }];
    }
}

- (void)uploadFileFromURL:(NSURL *)fileURL
               completion:(void (^)(ORBFileWrapper *uploadedFile, NSError *error))completionBlock {
	BOOL isPublic = [ORBPreferences preferences].newFilesArePublicPref;
    
    ORBFileWrapper *fileToUpload = [self.dataSource insertWrapperForCreatingFileFromURL:fileURL isPublic:isPublic];
    [self.tableView reloadData];
    
    [self.dataSource createServerFileFromWrapper:fileToUpload progress:^(CGFloat iProgress) {
        fileToUpload.progress = iProgress;
        [self.tableView beginUpdates];
        NSInteger index = [self.dataSource indexOfFile:fileToUpload];
        [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:index inSection:0]] withRowAnimation:UITableViewRowAnimationNone];
        [self.tableView endUpdates];
    } completion:^(ORBFileWrapper *uploadedFile, NSError *error) {        
        if (!uploadedFile) {
            [self.dataSource removeFileWrapper:fileToUpload];
            
            NSString *uploadErrorString = error ? [error localizedDescription] : @"Unknown Error";
            
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error uploading file" message:uploadErrorString delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [alert show];
        }
        
        [self.tableView reloadData];
        
        if (completionBlock) {
            completionBlock(uploadedFile, error);
        }
    }];
}


#pragma mark - Table View

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSUInteger numberOfFiles = [self.dataSource numberOfFiles];
    NSUInteger filesWithLoadingIndicator = self.dataSource.moreFilesAvailable && tableView == self.tableView ? numberOfFiles + 1 : numberOfFiles;
	
    return self.dataSource.client.isLoggedIn ? filesWithLoadingIndicator : 0;
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    ORBFileCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (!cell) {
        cell = [[[ORBFileCell class] alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    if (cell.imageOperation) {
        if (cell.imageOperationCleanupBlock) {
            cell.imageOperationCleanupBlock();
            cell.imageOperationCleanupBlock = nil;
        }
        [cell.imageOperation cancel];   // cancel the existing operation for a previous cell
        cell.imageOperation = nil;
    }
    
    ORBFileWrapper *fileWrapper = [self fileWrapperAtIndexPath:indexPath];
    
    if (!fileWrapper) {
        cell.textLabel.text = nil;
        cell.attributedDetailText = nil;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.accessoryType = UITableViewCellAccessoryNone;
        cell.progressView.hidden = YES;
        [cell.loadingActivityIndicator startAnimating];
        cell.imageView.image = nil;
    } else if (fileWrapper.isUploading) {
        cell.textLabel.text = [fileWrapper name];
		cell.attributedDetailText = nil;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.accessoryType = (ORBIsPhone ? UITableViewCellAccessoryDisclosureIndicator : UITableViewCellSelectionStyleNone);
        cell.progressView.progress = fileWrapper.progress;
        cell.progressView.hidden = NO;
        [cell.loadingActivityIndicator stopAnimating];
        cell.imageView.image = [fileWrapper iconImage];
    } else {
        cell.textLabel.text = [fileWrapper name];
		cell.attributedDetailText = [fileWrapper attributedFormattedSizeAndCreatedAt];
        cell.selectionStyle = UITableViewCellSelectionStyleBlue;
        cell.accessoryType = (ORBIsPhone ? UITableViewCellAccessoryDisclosureIndicator : UITableViewCellSelectionStyleNone);
        cell.progressView.hidden = YES;
        [cell.loadingActivityIndicator stopAnimating];
        cell.imageView.image = [fileWrapper iconImage];
        
        if ([fileWrapper thumbnailURL]) {
            
            NSString *thumbURLString = [[fileWrapper thumbnailURL] absoluteString];
            [self.imageURLsToIDs setObject:fileWrapper.file.fileID forKey:thumbURLString];
            
            cell.imageOperationCleanupBlock = ^() {
                [self.imageURLsToIDs removeObjectForKey:thumbURLString];
            };
            
            cell.imageOperation = [[SDWebImageManager sharedManager] downloadWithURL:[fileWrapper thumbnailURL] options:SDWebImageRetryFailed progress:nil completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, BOOL finished) {
                if (image && cacheType != SDImageCacheTypeNone) {
                    image = [self scaledImageForTumbnail:image];
                }

                cell.imageView.image = image;
                cell.imageOperation = nil;
                
                if (cell.imageOperationCleanupBlock) {
                    cell.imageOperationCleanupBlock();
                }
            }];
        }
    }
    
    [self cellDidDisplayAtIndexPath:indexPath];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    ORBFileWrapper *fileWrapper = [self fileWrapperAtIndexPath:indexPath];
    
    if (!fileWrapper.isUploading && ![self.selectedFileIndexPath isEqual:indexPath]) {
		self.selectedFileIndexPath = indexPath;
		
        UIViewController *vc = nil;
        if ([self.dataSource isFileAnImage:fileWrapper]) {
            ORBPhotoBrowser *photoBrowser = [[ORBPhotoBrowser alloc] initWithDelegate:self];
            [photoBrowser setCurrentPhotoIndex:[self.dataSource indexOfImageFile:fileWrapper]];
            vc = photoBrowser;
        } else {
            vc = [JJGWebViewController webViewControllerWithURL:[fileWrapper sharableURL] title:[fileWrapper name]];
        }
        
		if (self.splitViewController) {
			ORBNavigationController *currentDetailNavController = [self.splitViewController.viewControllers lastObject];
			ORBNavigationController *nextDetailNavController = [[ORBNavigationController alloc] initWithRootViewController:vc];
			
			if (currentDetailNavController.navigationBar.topItem.leftBarButtonItem) {
				nextDetailNavController.navigationBar.topItem.leftBarButtonItem = currentDetailNavController.navigationBar.topItem.leftBarButtonItem;
			}
			self.splitViewController.viewControllers = @[self.navigationController, nextDetailNavController];
		} else {
			[self.navigationController pushViewController:vc animated:YES];
		}
    }
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return ![self fileWrapperAtIndexPath:indexPath].isUploading;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        [self deleteFileAtIndexPath:indexPath];
    }
}

- (ORBFileWrapper *)fileWrapperAtIndexPath:(NSIndexPath *)indexPath {
    return [self.dataSource fileAtIndex:indexPath.row];
}

- (void)grabLastPhotoTaken {
    ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
    
    // Enumerate just the photos and videos group by using ALAssetsGroupSavedPhotos.
    [library enumerateGroupsWithTypes:ALAssetsGroupSavedPhotos usingBlock:^(ALAssetsGroup *group, BOOL *libraryStop) {
        
        // Within the group enumeration block, filter to enumerate just photos.
        [group setAssetsFilter:[ALAssetsFilter allPhotos]];
        
        if ([group numberOfAssets] > 0) {
            // Chooses the photo at the last index
            [group enumerateAssetsAtIndexes:[NSIndexSet indexSetWithIndex:[group numberOfAssets] - 1] options:0 usingBlock:^(ALAsset *asset, NSUInteger index, BOOL *groupStop) {
                
                // The end of the enumeration is signaled by asset == nil.
                if (asset) {
                    ALAssetRepresentation *representation = [asset defaultRepresentation];
                    UIImage *latestPhoto = [UIImage imageWithCGImage:[representation fullScreenImage]];
                    
                    [self uploadImage:latestPhoto completion:nil];
                    
                    *groupStop = YES;
                    *libraryStop = YES;
                }
            }];
        }
    } failureBlock: ^(NSError *error) {
        [SVProgressHUD showErrorWithStatus:@"Could not find any photos."];
    }];
}

#pragma mark - UIImagePickerController

- (void)showImagePickerForSourceType:(UIImagePickerControllerSourceType)sourceType {
    UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];
    imagePicker.sourceType = sourceType;
    imagePicker.delegate = self;
    imagePicker.mediaTypes = @[(NSString *)kUTTypeImage, (NSString *)kUTTypeMovie];
    
    [[UIBarButtonItem appearance] setTitleTextAttributes:@{NSForegroundColorAttributeName: [UIColor blackColor]} forState:UIControlStateNormal];
	
	if (ORBIsPad) {
		self.addFilesPopoverController = [[UIPopoverController alloc] initWithContentViewController:imagePicker];
        self.addFilesPopoverController.delegate = self;
		[self.addFilesPopoverController presentPopoverFromBarButtonItem:self.navigationItem.rightBarButtonItem permittedArrowDirections:UIPopoverArrowDirectionUp animated:YES];
	} else {
		[self presentViewController:imagePicker animated:YES completion:^{
            [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault animated:YES];
        }];
	}
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    NSString *mediaType = [info objectForKey:UIImagePickerControllerMediaType];
    
    if ([mediaType isEqualToString:(NSString *) kUTTypeMovie]) {
        NSURL *moviePath = [info objectForKey:UIImagePickerControllerMediaURL];
        
        [self uploadVideoAtPath:moviePath completion:nil];
    } else {
        [self uploadImage:[info objectForKey:UIImagePickerControllerOriginalImage] completion:nil];
    }
    
    [self dismissImagePicker];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [self dismissImagePicker];
}

- (void)dismissImagePicker {
    [[UIBarButtonItem appearance] setTitleTextAttributes:@{NSForegroundColorAttributeName: [UIColor whiteColor]} forState:UIControlStateNormal];
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent animated:YES];
    
	if (ORBIsPad) {
        if (self.addFilesPopoverController) {
            [self.addFilesPopoverController dismissPopoverAnimated:YES];
            self.addFilesPopoverController = nil;
        }
	} else {
		[self dismissViewControllerAnimated:YES completion:nil];
	}
}

#pragma mark - UIPopoverControllerDelegate

- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController {
    [self dismissImagePicker];
}

#pragma mark - File Actions

- (void)deleteFileAtIndexPath:(NSIndexPath *)indexPath {
    ORBFileWrapper *fileWrapper = [self fileWrapperAtIndexPath:indexPath];
    [self.dataSource deleteServerFile:fileWrapper success:^{
        BOOL shouldSelectNextRow = NO;
        
        if ([self.selectedFileIndexPath isEqual:indexPath]) {
            [self.tableView deselectRowAtIndexPath:indexPath animated:NO];
            shouldSelectNextRow = YES;
            self.selectedFileIndexPath = nil;
        }
        
        [self.tableView beginUpdates];
        
        [self.dataSource removeFileWrapper:fileWrapper];
        [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationRight];
        
        [self.tableView endUpdates];
        
        if (shouldSelectNextRow && [self.dataSource fileAtIndex:indexPath.row]) {
            [self.tableView selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionNone];
            [self tableView:self.tableView didSelectRowAtIndexPath:indexPath];
        }
    } failure:^(NSError *error) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error deleting" message:[error localizedDescription] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
        NSLog(@"error deleting: %@", error);
    }];
}


- (void)togglePublicPrivateForFileAtIndexPath:(NSIndexPath *)indexPath {
    ORBFileWrapper *fileWrapper = [self fileWrapperAtIndexPath:indexPath];
    [self.dataSource updateServerFile:fileWrapper asPublic:!fileWrapper.isPublic success:^{
        NSString *publicOrPrivate = !fileWrapper.isPublic ? @"public" : @"private";
        [SVProgressHUD showAutodismissingSuccessWithStatus:[NSString stringWithFormat:@"Updated file to %@", publicOrPrivate]];
        [self.tableView reloadData];
    } failure:^(NSError *error) {
        NSLog(@"error updating file: %@", error);
        [SVProgressHUD showErrorWithStatus:@"Error updating file"];
    }];
}


- (void)renameFileAtIndexPath:(NSIndexPath *)indexPath {
    ORBFileWrapper *fileWrapper = [self fileWrapperAtIndexPath:indexPath];
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Rename File" message:fileWrapper.name delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Rename", nil];
    alert.alertViewStyle = UIAlertViewStylePlainTextInput;
    [alert show];
    
    self.renameFileIndexPath = indexPath;
}


- (void)shareFileURLAtIndexPath:(NSIndexPath *)indexPath {
    ORBFileWrapper *fileWrapper = [self fileWrapperAtIndexPath:indexPath];

    [self showImageOnPadForIndexPath:indexPath];
    [self shareActivityItem:[fileWrapper sharableURL]];
}


- (void)shareImageAtIndexPath:(NSIndexPath *)indexPath {
    ORBFileWrapper *fileWrapper = [self fileWrapperAtIndexPath:indexPath];
    NSString *loadingText = @"Loading image...";
    
    [self showImageOnPadForIndexPath:indexPath];
    
    [SVProgressHUD showWithStatus:loadingText];
    [[SDWebImageManager sharedManager] downloadWithURL:[fileWrapper previewItemURL] options:0 progress:^(NSInteger receivedSize, NSInteger expectedSize) {
        if (expectedSize > 0) {
            CGFloat progress = (float) receivedSize / (float) expectedSize;
            [SVProgressHUD showProgress:progress status:loadingText];
        }
    } completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, BOOL finished) {
        if (image) {
            [SVProgressHUD dismiss];
            [self shareActivityItem:image];
        } else {
            [SVProgressHUD showErrorWithStatus:[error localizedDescription]];
        }
    }];
}

- (void)showImageOnPadForIndexPath:(NSIndexPath *)indexPath {
    if (ORBIsPad) {
        [self tableView:self.tableView didSelectRowAtIndexPath:indexPath];
        
        if (ORBIsPortrait) {
            UINavigationController *navController = [self.splitViewController.viewControllers lastObject];
            UIViewController *webVC = [navController.viewControllers lastObject];
            UINavigationItem *navItem = webVC.navigationItem;
            UIBarButtonItem *leftBBI = navItem.leftBarButtonItem;
            
            if (leftBBI) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
                [leftBBI.target performSelector:leftBBI.action];
#pragma clang diagnostic pop
            }
        }
    }
}

#pragma mark - Long Press Gesture Recognizer

- (void)handleLongPress:(UIGestureRecognizer *)gestureRecognizer {
    if (gestureRecognizer.state == UIGestureRecognizerStateBegan) {
        CGPoint point = [gestureRecognizer locationInView:self.tableView];
        NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:point];
        [self.tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
        
        [self handleLongPressForIndexPath:indexPath];
    }
}

- (void)handleLongPressForIndexPath:(NSIndexPath *)indexPath {
    if (indexPath) {
        ORBFileWrapper *fileWrapper = [self fileWrapperAtIndexPath:indexPath];
        
        if (!fileWrapper.isUploading) {
            self.longPressedIndexPath = indexPath;
            NSString *togglePermissionString = fileWrapper.isPublic ? @"Mark as Private" : @"Mark as Public";
            if ([self.dataSource isFileAnImage:fileWrapper]) {
                self.fileActionActionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:@"Share URL" otherButtonTitles:@"Share Image", @"Rename", togglePermissionString, @"Delete", nil];
                self.fileActionActionSheet.destructiveButtonIndex = 4;
            } else {
                self.fileActionActionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:@"Share URL" otherButtonTitles:@"Rename", togglePermissionString, @"Delete", nil];
                self.fileActionActionSheet.destructiveButtonIndex = 3;
            }
            
            if (ORBIsPad) {
                UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
                [self.fileActionActionSheet showFromRect:cell.frame inView:self.view animated:YES];
            } else {
                [self.fileActionActionSheet showInView:self.navigationController.view];
            }
        }
    }
}

#pragma mark - UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet willDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (actionSheet == self.fileActionActionSheet) {
        if (buttonIndex == 0) {
            [self shareFileURLAtIndexPath:self.longPressedIndexPath];
        } else {
            ORBFileWrapper *fileWrapper = [self fileWrapperAtIndexPath:self.longPressedIndexPath];
            BOOL isFileAnImage = [self.dataSource isFileAnImage:fileWrapper];
            
            if (isFileAnImage) {
                buttonIndex --;
            }
            
            if (buttonIndex != actionSheet.cancelButtonIndex) {
                switch (buttonIndex) {
                    case 0:
                        [self shareImageAtIndexPath:self.longPressedIndexPath];
                        break;
                    case 1:
                        [self renameFileAtIndexPath:self.longPressedIndexPath];
                        break;
                    case 2:
                        [self togglePublicPrivateForFileAtIndexPath:self.longPressedIndexPath];
                        break;
                    case 3:
                        [self deleteFileAtIndexPath:self.longPressedIndexPath];
                        break;
                        
                    default:
                        break;
                }
            }
        }
        
        
        [self.tableView deselectRowAtIndexPath:self.longPressedIndexPath animated:YES];
        self.longPressedIndexPath = nil;
        self.fileActionActionSheet = nil;
    } else if (actionSheet == self.imageSourceActionSheet) {
        if (buttonIndex != actionSheet.cancelButtonIndex) {
            if (![self hasImageOnCliboard]) buttonIndex++;
            
            switch (buttonIndex) {
                case 0:
                    [self uploadImageFromClipboard];
                    break;
                case 1:
                    [self grabLastPhotoTaken];
                    break;
                case 2:
                    [self showImagePickerForSourceType:UIImagePickerControllerSourceTypePhotoLibrary];
                    break;
                case 3:
                    [self showImagePickerForSourceType:UIImagePickerControllerSourceTypeCamera];
                    break;
                    
                default:
                    break;
            }
        }
		self.imageSourceActionSheet = nil;
    }
}


#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView willDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (buttonIndex == alertView.firstOtherButtonIndex) {
        ORBFileWrapper *fileWrapper = [self.dataSource fileAtIndex:self.renameFileIndexPath.row];
        [self.dataSource renameFile:fileWrapper toName:[alertView textFieldAtIndex:0].text success:^{
            [SVProgressHUD showAutodismissingSuccessWithStatus:@"Successfully renamed file."];
            [self.tableView reloadData];
        } failure:^(NSError *error) {
            NSLog(@"%@", error);
            [SVProgressHUD showErrorWithStatus:@"Unable to rename file"];
        }];
    }
    self.renameFileIndexPath = nil;
}

#pragma mark - Clipboard

- (BOOL)hasImageOnCliboard {
    return [self.dataSource.client isAuthenticated] && [UIPasteboard generalPasteboard].image;
}

- (void)uploadImageFromClipboard {
    [self uploadImage:[UIPasteboard generalPasteboard].image completion:^(ORBFileWrapper *uploadedFile, NSError *error) {
        if (uploadedFile) {
            [UIPasteboard generalPasteboard].images = nil;  // clear the clipboard regardless
        }
    }];
}

#pragma mark - MWPhotoBrowserDelegate

- (NSUInteger)numberOfPhotosInPhotoBrowser:(MWPhotoBrowser *)photoBrowser {
    return [self.dataSource numberOfImageFiles];
}

- (id<MWPhoto>)photoBrowser:(MWPhotoBrowser *)photoBrowser photoAtIndex:(NSUInteger)index {
    ORBFileWrapper *file = [self.dataSource imageFileAtIndex:index];
    MWPhoto *photo = [MWPhoto photoWithURL:[file previewItemURL]];
    photo.caption = [file name];
    
    return photo;
}

- (void)photoBrowser:(MWPhotoBrowser *)photoBrowser didDisplayPhotoAtIndex:(NSUInteger)index {
    ORBFileWrapper *fileWrapper = [self.dataSource imageFileAtIndex:index];
    NSIndexPath *newOverallIndexPath = [NSIndexPath indexPathForRow:[self.dataSource indexOfFile:fileWrapper] inSection:0];
    
    if (self.selectedFileIndexPath && ![self.selectedFileIndexPath isEqual:newOverallIndexPath]) {
		if (ORBIsPhone) {
			[self.tableView selectRowAtIndexPath:newOverallIndexPath animated:NO scrollPosition:UITableViewScrollPositionMiddle];
		} else {
			[self.tableView selectRowAtIndexPath:newOverallIndexPath animated:YES scrollPosition:UITableViewScrollPositionMiddle];
		}
    }
    
    self.selectedFileIndexPath = newOverallIndexPath;
}

- (NSURL *)photoBrowser:(MWPhotoBrowser *)photoBrowser sharableURLAtIndex:(NSUInteger)index {
    ORBFileWrapper *fileWrapper = [self.dataSource imageFileAtIndex:index];
    return [fileWrapper sharableURL];
}

#pragma mark - UISearchBarDelegate

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    [self.dataSource filterForSearchQuery:searchText];
    [self.tableView reloadData];
}

#pragma mark - UISearchDisplayDelegate

- (void)searchDisplayControllerWillBeginSearch:(UISearchDisplayController *)controller {
    [self.searchController.searchResultsTableView registerClass:[ORBFileCell class] forCellReuseIdentifier:CellIdentifier];
}

- (void)searchDisplayControllerDidBeginSearch:(UISearchDisplayController *)controller {
    double delayInSeconds = 0.0;    // these dont work correctly if not run on next run loop
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        ORBNavigationBar *navBar = (ORBNavigationBar *) self.navigationController.navigationBar;
        [navBar removeDarkUnderlayView];
    });
}

- (void)searchDisplayControllerWillEndSearch:(UISearchDisplayController *)controller {
    double delayInSeconds = 0.0;    // these dont work correctly if not run on next run loopg
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        ORBNavigationBar *navBar = (ORBNavigationBar *) self.navigationController.navigationBar;
        [navBar addDarkUnderlayView];
    });
}

- (void)searchDisplayController:(UISearchDisplayController *)controller didHideSearchResultsTableView:(UITableView *)tableView {
    [self.dataSource stopFiltering];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
    [self.tableView reloadData];
    self.navigationController.navigationBar.barTintColor = kORBBarTintColor;
}

- (void)searchDisplayController:(UISearchDisplayController *)controller didShowSearchResultsTableView:(UITableView *)tableView {
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
}

#pragma mark - SDWebImageManagerDelegate

- (UIImage *)imageManager:(SDWebImageManager *)imageManager
 transformDownloadedImage:(UIImage *)image
                  withURL:(NSURL *)imageURL {
    if (image && [self.imageURLsToIDs objectForKey:[imageURL absoluteString]]) { // downloading the image
        image = [self scaledImageForTumbnail:image];
    }
    
    return image;
}

- (UIImage *)scaledImageForTumbnail:(UIImage *)sourceImage {
    CGFloat scale = [UIScreen mainScreen].scale;
    CGFloat size = kFileCellIconSize * scale;
    
    UIImage *image;
    if (sourceImage.size.width != size || sourceImage.size.height != size) {
        image = [sourceImage scaleToFitSize:CGSizeMake(size, size)];
    } else {
        image = sourceImage;
    }
    
    if (scale > 1.0) {
        image = [UIImage imageWithCGImage:[image CGImage]
                                    scale:scale
                              orientation:image.imageOrientation];
    }
    
    return image;
}

#pragma mark - UISplitViewControllerDelegate

- (void)splitViewController:(UISplitViewController *)svc willHideViewController:(UIViewController *)aViewController withBarButtonItem:(UIBarButtonItem *)barButtonItem forPopoverController:(UIPopoverController *)pc {
	ORBNavigationController *detailNavController = [self.splitViewController.viewControllers lastObject];
    barButtonItem.title = @"Files";
	detailNavController.navigationBar.topItem.leftBarButtonItem = barButtonItem;
}


- (void)splitViewController:(UISplitViewController *)svc willShowViewController:(UIViewController *)aViewController invalidatingBarButtonItem:(UIBarButtonItem *)barButtonItem {
	ORBNavigationController *detailNavController = [self.splitViewController.viewControllers lastObject];
	detailNavController.navigationBar.topItem.leftBarButtonItem = nil;
}


#pragma mark - Paging

- (void)cellDidDisplayAtIndexPath:(NSIndexPath *)indexPath {
	if (indexPath.row + 1 == [self.dataSource numberOfFiles] &&
        !self.dataSource.isRunningRequest &&
        self.dataSource.canRefreshFiles &&
        self.dataSource.moreFilesAvailable &&
        !self.dataSource.isFiltering) {
        
		[self.dataSource fetchNextFilesBatchWithSuccess:^{
			[self.tableView reloadData];
		}];
	}
}


- (void)possiblyDropPages {
	NSIndexPath *lastIndexPath = [[self.tableView indexPathsForVisibleRows] lastObject];
	NSUInteger page = lastIndexPath.row / kORBFilePageBatchSize;
	
	if (page < self.dataSource.extraPagesLoaded) {
		[self.dataSource dropPagesAfterPage:page];
		[self.tableView reloadData];
	}
}

@end
