//
//  DMViewController.m
//  DMTwitterOAuth
//
//  Created by Daniele Margutti (daniele.margutti@gmail.com) on 5/13/12.
//  From an original work by Jaanus Kase
//  Copyright (c) 2012 http://danielem.org. All rights reserved.
//

#import "DMViewController.h"
#import "DMOAuthTwitter.h"
#import "DMTwitterCore.h"

@interface DMViewController () {
    IBOutlet    UIButton*       btn_loginLogout;
    IBOutlet    UILabel*        lbl_welcome;
    IBOutlet    UITextView*     tw_userData;
}

- (IBAction)btn_twitterLogin:(id)sender;
+ (NSString *) readableCurrentLoginStatus:(DMOTwitterLoginStatus) cstatus;

@end

@implementation DMViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.navigationItem.title = @"Twitter OAuth";
    if ([DMTwitter shared].oauth_token_authorized) {
        [btn_loginLogout setTitle:@"Already Logged, Press to Logout" forState:UIControlStateNormal];
        [lbl_welcome setText:[NSString stringWithFormat:@"You're %@!",[DMTwitter shared].screen_name]];
        tw_userData.text = @"";
    }
}

- (IBAction)btn_twitterLogin:(id)sender {
    if ([DMTwitter shared].oauth_token_authorized) {
        // already logged, execute logout
        [[DMTwitter shared] logout];
        [btn_loginLogout setTitle:@"Twitter Login" forState:UIControlStateNormal];
        [lbl_welcome setText:@"Press \"Twitter Login!\" to start!"];
        tw_userData.text = @"";
    } else {
        // prompt login
        [[DMTwitter shared] newLoginSessionFrom:self.navigationController
                                   progress:^(DMOTwitterLoginStatus currentStatus) {
                                       NSLog(@"current status = %@",[DMViewController readableCurrentLoginStatus:currentStatus]);
                                   } completition:^(NSString *screenName, NSString *user_id, NSError *error) {
                                       
                                       if (error != nil) {
                                           NSLog(@"Twitter login failed: %@",error);
                                       } else {
                                           NSLog(@"Welcome %@!",screenName);
                                           
                                           [btn_loginLogout setTitle:@"Twitter Logout" forState:UIControlStateNormal];
                                           [lbl_welcome setText:[NSString stringWithFormat:@"Welcome %@!",screenName]];
                                           [tw_userData setText:@"Loading your user info..."];
                                           
                                           // store our auth data so we can use later in other sessions
                                           [[DMTwitter shared] saveCredentials];
                                       
                                           NSLog(@"Now getting more data...");
                                           // you can use this call in order to validate your credentials
                                           // or get more user's info data
                                           [[DMTwitter shared] validateTwitterCredentialsWithCompletition:^(BOOL credentialsAreValid, NSDictionary *userData) {
                                               if (credentialsAreValid)
                                                   tw_userData.text = [NSString stringWithFormat:@"Data for %@ (userid=%@):\n%@",screenName,user_id,userData];
                                               else
                                                   tw_userData.text = @"Cannot get more data. Token is not authorized to get this info.";
                                           }];
                                       }
                                   }]; 
    }
}

+ (NSString *) readableCurrentLoginStatus:(DMOTwitterLoginStatus) cstatus {
    switch (cstatus) {
        case DMOTwitterLoginStatus_PromptUserData:
            return @"Prompt for user data and request token to server";
        case DMOTwitterLoginStatus_RequestingToken:
            return @"Requesting token for current user's auth data...";
        case DMOTwitterLoginStatus_TokenReceived:
            return @"Token received from server";
        case DMOTwitterLoginStatus_VerifyingToken:
            return @"Verifying token...";
        case DMOTwitterLoginStatus_TokenVerified:
            return @"Token verified";
        default:
            return @"[unknown]";
    }
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

@end
