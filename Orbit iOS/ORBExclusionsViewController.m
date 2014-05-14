//
//  ORBExclusionsViewController.m
//  Orbit
//
//  Created by Andy LaVoy on 7/6/13.
//  Copyright (c) 2013 Log Cabin. All rights reserved.
//

#import "ORBExclusionsViewController.h"
#import "ORBExclusionRule.h"


static NSString * const CellIdentifier = @"Cell";


@interface ORBExclusionsViewController ()

@end


@implementation ORBExclusionsViewController

- (id)init {
	if ((self = [super initWithStyle:UITableViewStyleGrouped])) {
		
	}
	return self;
}


- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"Exclusions";
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:CellIdentifier];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [[[ORBPreferences preferences] allExclusionRules] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    ORBExclusionRule *rule = [self ruleAtIndexPath:indexPath];
    
    cell.textLabel.text = rule.name;
	cell.textLabel.font = [UIFont fontWithName:kORBFontMedium size:16.0];
    cell.accessoryType = rule.isEnabled ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
    
    cell.imageView.image = [UIImage imageNamed:[rule imageString]];
    cell.imageView.highlightedImage = [UIImage imageNamed:[rule highlightedImageString]];
    cell.tintColor = kORBTintColor;
    
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    ORBExclusionRule *rule = [self ruleAtIndexPath:indexPath];
    
    [[ORBPreferences preferences] setShouldExclude:!rule.isEnabled usingRuleWithIdentifier:rule.identifier];
	if (self.exclusionsDidChangeHandler) {
		self.exclusionsDidChangeHandler();
	}
    
    [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
}

#pragma mark - Convenience

- (ORBExclusionRule *)ruleAtIndexPath:(NSIndexPath *)indexPath {
    return [[[ORBPreferences preferences] allExclusionRules] safeObjectAtIndex:indexPath.row];
}

@end
