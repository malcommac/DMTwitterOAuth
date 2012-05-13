//
//  DMOAuthTwitter.h
//  DMTwitterOAuth
//
//  Created by Daniele Margutti (daniele.margutti@gmail.com) on 5/13/12.
//  From an original work by Jaanus Kase
//  Copyright (c) 2012 http://danielem.org. All rights reserved.
//

#import "DMOAuth.h"
#import "DMTwitterLoginViewController.h"

#define kDMPersistentData_ScreenName                @"twitter_screenname"
#define kDMPersistentData_ScreenID                  @"twitter_screenid"

// Blocks Handlers
typedef void (^DMOAuthTwitterTokenRequestResult)(NSString *token,NSHTTPURLResponse *response,NSError*error);
typedef void (^DMOAuthTwitterTokenAuthorizationResult)(NSString *screenName,NSString *user_id,NSHTTPURLResponse *response,NSError*error);
typedef void (^DMOAuthTwitterCredentialValidationResult)(BOOL credentialsAreValid,NSDictionary *userData);

@class DMTwitterLoginViewController;
@interface DMOAuthTwitter : DMOAuth { }

@property (copy)        NSString *                      user_id;                // Twitter User ID
@property (copy)        NSString *                      screen_name;            // Twitter Screen Name  (ie. @danielemargutti)

@property (readonly)    DMTwitterLoginViewController*   currentLoginController; // If you have presented a login panel this contains a reference to it  

#pragma mark - LOGIN VIA BUILT-IN VIEW CONTROLLER

// Use this method to start a new login session using the standard way via the built-in interface
// You can also specify an handler to follow your currentProgress and a completition handler to get the final login result data
- (BOOL) newLoginSessionFrom:(UIViewController *) parentController
                    progress:(DMOTwitterLoginCurrentStatus) currentProgress
                completition:(DMOTwitterLoginResult) completition;

// Logout current session.
- (void) logout;

#pragma mark - LOGIN METHODS (You should use it only if you plan to make a custom view-controller)

/**
 * Given a request URL, request an unauthorized OAuth token from that URL.
 * This starts the process of getting permission from user.
 * This operation uses blocks to notify you about the final operation result.
 *
 * This is the request/response specified in OAuth Core 1.0A section 6.1.
 */
- (void) requestTwitterTokenWithCallbackUrl:(NSString *) callbackUrl
                               completition:(DMOAuthTwitterTokenRequestResult) tokenReqResult;

/**
 * When you call this method you have your token and you need to verify authorization. (only for PIN support)
 * This is the request/response specified in OAuth Core 1.0A section 6.3.
 */
- (void) verifyTwitterAuthorizationToken:(NSString *) oauth_verifier
                            completition:(DMOAuthTwitterTokenAuthorizationResult) completition;


/**
 * You can use this method to validate your authorization token or get user's profile data.
 */
- (void) validateTwitterCredentialsWithCompletition:(DMOAuthTwitterCredentialValidationResult) completition;

@end
