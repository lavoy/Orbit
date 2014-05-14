//
//  ORBSettingsViewController.m
//  Orbit
//
//  Created by Andy LaVoy on 4/27/13.
//  Copyright (c) 2013 Log Cabin. All rights reserved.
//

#import "ORBSettingsViewController.h"
#import "ORBSettingCell.h"
#import "ORBPreferences.h"
#import "ORBExclusionsViewController.h"


typedef NS_ENUM(NSInteger, ORBSettingsRowType) {
	ORBSettingsRowTypeAccount,
	ORBSettingsRowTypeStorageSpace,
	ORBSettingsRowTypeUploadAsPublic,
	ORBSettingsRowTypeExclusions,
	ORBSettingsRowTypeFullSizeGalleryImages,
	ORBSettingsRowTypeRate
};


@interface ORBSettingsViewController () <UIActionSheetDelegate>

@property (nonatomic, assign) BOOL shouldSendReloadNotification;
@property (nonatomic, weak) ORBDataSource *dataSource;
@property (nonatomic, strong) NSArray *rowTypes;
@property (nonatomic, strong, readwrite) UILabel *footerLabel;
@property (nonatomic, strong) UIActionSheet *logOutActionSheet;

@end


@implementation ORBSettingsViewController

- (id)initWithDataSource:(ORBDataSource *)dataSource {
    if (self = [super initWithStyle:UITableViewStyleGrouped]) {
        self.title = @"Settings";
		
		__weak ORBSettingsViewController *weakSelf = self;
		
		self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStylePlain block:^(id weakSender) {
			if (weakSelf.shouldSendReloadNotification) {
				[[NSNotificationCenter defaultCenter] postNotificationName:kORBShouldReloadFilesNotification object:weakSelf];
			}
            [weakSelf.navigationController dismissViewControllerAnimated:YES completion:nil];
        }];
		
		self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Log Out" style:UIBarButtonItemStylePlain block:^(id weakSender) {
			[weakSelf logOutPressed];
		}];
		
        self.dataSource = dataSource;
        self.rowTypes = @[@[@(ORBSettingsRowTypeAccount), @(ORBSettingsRowTypeStorageSpace)], @[@(ORBSettingsRowTypeUploadAsPublic), @(ORBSettingsRowTypeFullSizeGalleryImages), @(ORBSettingsRowTypeExclusions)], @[@(ORBSettingsRowTypeRate)]];
    }
    return self;
}


- (void)viewDidLoad {
	[super viewDidLoad];
	
	UIView *footerView = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, self.view.frame.size.width, 0.0)];
	footerView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
	
	NSString *buildNumber = [[NSBundle mainBundle] objectForInfoDictionaryKey:(NSString *)kCFBundleVersionKey];
	NSString *footerValue = [NSString stringWithFormat:@"Orbit Version %@\n© 2013 Log Cabin.", buildNumber];
	self.footerLabel = [[UILabel alloc] initWithFrame:CGRectZero];
	self.footerLabel.numberOfLines = 0;
	self.footerLabel.text = footerValue;
	self.footerLabel.font = [UIFont fontWithName:kORBFontRegular size:14.0];
	self.footerLabel.textColor = [UIColor colorWithWhite:0.55 alpha:1.0];
	self.footerLabel.backgroundColor = [UIColor clearColor];
	self.footerLabel.textAlignment = NSTextAlignmentCenter;
	self.footerLabel.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
	[self.footerLabel sizeToFit];
	[footerView addSubview:self.footerLabel];
	[self.footerLabel centerInSuperview];
	self.footerLabel.frame = CGRectMake(self.footerLabel.frame.origin.x, 10.0, self.footerLabel.frame.size.width, self.footerLabel.frame.size.height);
	footerView.frame = CGRectMake(0.0, 0.0, footerView.frame.size.width, self.footerLabel.frame.size.height + 10.0);
	
	self.tableView.tableFooterView = footerView;
}


- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
    NSIndexPath *selectedIndexPath = [[self.tableView indexPathForSelectedRow] copy];
	[self.tableView reloadData];
    [self.tableView selectRowAtIndexPath:selectedIndexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
}


#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [self.rowTypes count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.rowTypes[section] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    ORBSettingsRowType rowType = [self rowTypeForIndexPath:indexPath];
    UITableViewCellStyle style = UITableViewCellStyleValue1;
    
    NSString *cellIdentifier = [NSString stringWithFormat:@"%d", style];
    ORBSettingCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
    if (!cell) {
        cell = [[ORBSettingCell alloc] initWithStyle:style reuseIdentifier:cellIdentifier];
    }
    
    NSString *text;
    NSString *detailText = nil;
    UIView *accessoryView = nil;
    UITableViewCellAccessoryType accessoryType = UITableViewCellAccessoryNone;
    NSTextAlignment alignment;
    UITableViewCellSelectionStyle selectionStyle;
    [cell.contentView removeAllSubviews];
    
    switch (rowType) {
        case ORBSettingsRowTypeAccount:
            text = @"Account";
            detailText = self.dataSource.client.authenticatedUser.username;
            alignment = NSTextAlignmentLeft;
            selectionStyle = UITableViewCellSelectionStyleNone;
            break;
        case ORBSettingsRowTypeStorageSpace:
            text = @"Storage";
            detailText = [[ORBAppDelegate sharedAppDelegate].storageInfo storageSpaceString];
            alignment = NSTextAlignmentLeft;
            selectionStyle = UITableViewCellSelectionStyleNone;
            break;
        case ORBSettingsRowTypeUploadAsPublic: {
            text = @"Upload files as public";
            alignment = NSTextAlignmentLeft;
            selectionStyle = UITableViewCellSelectionStyleNone;
            
            UISwitch *publicSwitch = [[UISwitch alloc] init];
            publicSwitch.on = [ORBPreferences preferences].newFilesArePublicPref;
            [publicSwitch handleControlEvents:UIControlEventValueChanged withBlock:^(id weakControl) {
                [ORBPreferences preferences].newFilesArePublicPref = publicSwitch.isOn;
            }];
            
            accessoryView = publicSwitch;
        }
            break;
        case ORBSettingsRowTypeExclusions: {
			text = @"Exclusions";
            alignment = NSTextAlignmentLeft;
            selectionStyle = UITableViewCellSelectionStyleBlue;
            accessoryType = UITableViewCellAccessoryDisclosureIndicator;
			
			detailText = @"None enabled";
			NSArray *enabledRules = [[ORBPreferences preferences] enabledExclusionRules];
			if (enabledRules.count > 0) {
				detailText = [NSString stringWithFormat:@"%@ enabled", @([enabledRules count])];
			}
            break;
		}
        case ORBSettingsRowTypeFullSizeGalleryImages: {
            text = @"Load full-sized images";
            alignment = NSTextAlignmentLeft;
            selectionStyle = UITableViewCellSelectionStyleNone;
            
            UISwitch *fullImagesSwitch = [[UISwitch alloc] init];
            fullImagesSwitch.on = [ORBPreferences preferences].fullSizeGalleryImagesPref;
            [fullImagesSwitch handleControlEvents:UIControlEventValueChanged withBlock:^(id weakControl) {
                [ORBPreferences preferences].fullSizeGalleryImagesPref = fullImagesSwitch.isOn;
            }];
            
            accessoryView = fullImagesSwitch;
        }
            break;
        case ORBSettingsRowTypeRate: {
            text = @"Review Orbit on iTunes";
            alignment = NSTextAlignmentLeft;
            selectionStyle = UITableViewCellSelectionStyleDefault;
        }
            break;
    }
    
    cell.textLabel.text = text;
    cell.detailTextLabel.text = detailText;
    cell.textLabel.textAlignment = alignment;
    cell.selectionStyle = selectionStyle;
    cell.accessoryView = accessoryView;
    cell.accessoryType = accessoryType;
    
    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    switch ([self rowTypeForIndexPath:indexPath]) {
        case ORBSettingsRowTypeStorageSpace:
            [ORBStorageInfo toggleStorageFormat];
            [tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
            break;
        case ORBSettingsRowTypeExclusions: {
            ORBExclusionsViewController *exclusionsVC = [[ORBExclusionsViewController alloc] init];
			exclusionsVC.exclusionsDidChangeHandler = ^{
				self.shouldSendReloadNotification = YES;
			};
            [self.navigationController pushViewController:exclusionsVC animated:YES];
        }
        case ORBSettingsRowTypeRate:
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"itms-apps://itunes.apple.com/app/id677014321"]];
            [tableView deselectRowAtIndexPath:indexPath animated:YES];
            break;
            
        default:
            break;
    }
}


- (ORBSettingsRowType)rowTypeForIndexPath:(NSIndexPath *)indexPath {
    NSNumber *rowTypeNum = self.rowTypes[indexPath.section][indexPath.row];
    return [rowTypeNum integerValue];
}

#pragma mark - Logout flow

- (void)logOutPressed {
	if (!self.logOutActionSheet) {
		self.logOutActionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:@"Log Out" otherButtonTitles:nil];
		if (ORBIsPhone) {
			[self.logOutActionSheet showInView:self.view];
		} else {
			[self.logOutActionSheet showFromBarButtonItem:self.navigationItem.leftBarButtonItem animated:YES];
		}
	} else {
		[self.logOutActionSheet dismissWithClickedButtonIndex:-1 animated:YES];
	}
}


- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex {
	if (buttonIndex == 0) {
        [[ORBAppDelegate sharedAppDelegate] logout:nil];
    }
	self.logOutActionSheet = nil;
}


@end
