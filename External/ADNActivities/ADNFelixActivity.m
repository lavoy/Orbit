//
//  ADNFelixActivity.m
//  ADNActivityCollection
//
//  Created by Brennan Stehling on 3/2/13.
//  Copyright (c) 2013 SmallSharptools LLC. All rights reserved.
//

#import "ADNFelixActivity.h"

// http://tigerbears.com/felix/urls.html
// felix://
// felix://compose/post?text=[text] ("text" is optional, but is expected to be URL-encoded.)

@implementation ADNFelixActivity

#pragma mark - Public Implementation
#pragma mark -

- (NSString *)clientURLScheme {
    return @"felix://";
}

#pragma mark - UIActivity Override Methods
#pragma mark -

- (NSString *)activityTitle {
    return @"Felix";
}

- (UIImage *)activityImage {
    static UIImage *image = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        image = [UIImage imageNamed:@"activity-felix"];
    });
    return image;
}

- (NSURL *)clientOpenURL {
    if (self.clientURLScheme != nil) {
        NSString *urlString = [NSString stringWithFormat:@"%@compose/post?text=%@", self.clientURLScheme, self.encodedText];
        NSString *appURLScheme = [self appURLScheme];
        if (appURLScheme != nil) {
            urlString = [NSString stringWithFormat:@"%@&returnURLScheme=%@", urlString, [self encodeText:appURLScheme]];
        }
#ifndef NDEBUG
        NSLog(@"clientOpenURL: %@", urlString);
#endif
        NSURL *openURL = [NSURL URLWithString:urlString];
        return openURL;
    }
    
    return nil;
}

@end
