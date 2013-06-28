//
//  DemoAppDelegate.h
//  GaussianBlur
//
//  Created by Zikomo Fields on 1/12/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OGLShader.h"

@class DemoViewController;

@interface DemoAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (strong, nonatomic) DemoViewController *viewController;

@property (strong, nonatomic) OGLShader* imageEffectsController;

@end
