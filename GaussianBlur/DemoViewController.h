//
//  DemoViewController.h
//  GaussianBlur
//
//  Created by Zikomo Fields on 1/12/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OGLShader.h"

@interface DemoViewController : UIViewController
{
    UIImage *oldImage;
    IBOutlet UIImageView *zikomo;
    OGLShader *effects;
    EAGLContext *context;
}
-(IBAction) blurMe;
-(IBAction) reset;
@end
