//
//  ORBGradientLayerView.m
//  Orbit
//
//  Created by Joel Levin on 8/11/13.
//  Copyright (c) 2013 Log Cabin. All rights reserved.
//

#import "ORBGradientLayerView.h"


@implementation ORBGradientLayerView

+ (Class)layerClass {
	return [CAGradientLayer class];
}


- (CAGradientLayer *)gradientLayer {
	return (CAGradientLayer *)self.layer;
}


@end
