//
//  DMTwitterLoginViewController.h
//  DMTwitterOAuth
//
//  Created by Daniele Margutti (daniele.margutti@gmail.com) on 5/13/12.
//  From an original work by Jaanus Kase
//  Copyright (c) 2012 http://danielem.org. All rights reserved.
//

#import <UIKit/UIKit.h>

enum {
    DMOTwitterLoginStatus_PromptUserData        =   0,      // Step 0. Prompt for user auth data
    DMOTwitterLoginStatus_RequestingToken       =   1,      // Step 1. Requesting authorization token with user's data
    DMOTwitterLoginStatus_TokenReceived         =   2,      // Step 2. Token is received (can or can't be valid)
    DMOTwitterLoginStatus_VerifyingToken        =   3,      // Step 3. Verifying token authorization
    DMOTwitterLoginStatus_TokenVerified         =   4       // Step 4. Token is verified. DMOTwitterLoginResult hanlder contains data of login or error
}; typedef NSUInteger DMOTwitterLoginStatus;


// Blocks handler
typedef void (^DMOTwitterLoginCurrentStatus)(DMOTwitterLoginStatus currentStatus);
typedef void (^DMOTwitterLoginResult)(NSString *screenName,NSString *user_id,NSError *error);


@class DMOAuthTwitter;
@interface DMTwitterLoginViewController : UIViewController {
    
}

@property (readonly)            UIWebView*                  webView;                // webView istance of the built-in login view controller
@property (nonatomic,assign)    NSString*                   customURLScheme;        // assign a value only if you plan to use a custom URL scheme

- (id)initWithOAuthSession:(DMOAuthTwitter *) authObj
           progressHandler:(DMOTwitterLoginCurrentStatus) currentProgress
       completitionHanlder:(DMOTwitterLoginResult) completition;

- (BOOL) handleTokenRequestResponseURL:(NSURL *) url;

@end
