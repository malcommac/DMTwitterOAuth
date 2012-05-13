//
//  DMAppDelegate.h
//  DMTwitterOAuth
//
//  Created by Daniele Margutti (daniele.margutti@gmail.com) on 5/13/12.
//  From an original work by Jaanus Kase
//  Copyright (c) 2012 http://danielem.org. All rights reserved.
//

#import <UIKit/UIKit.h>

@class DMViewController;

@interface DMAppDelegate : UIResponder <UIApplicationDelegate> {
    UINavigationController* navigationController;
}

@property (strong, nonatomic) UIWindow *window;
@property (strong) UINavigationController *navigationController;

@property (strong, nonatomic) DMViewController *viewController;

@end
