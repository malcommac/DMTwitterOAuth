//
//  DMOAuthTwitter.m
//  DMTwitterOAuth
//
//  Created by Daniele Margutti (daniele.margutti@gmail.com) on 5/13/12.
//  From an original work by Jaanus Kase
//  Copyright (c) 2012 http://danielem.org. All rights reserved.
//

#import "DMOAuthTwitter.h"
#import "DMTwitterLoginViewController.h"
#import "JSONKit.h"

#define kDMAuthRequestTokenURL          @"https://api.twitter.com/oauth/request_token"
#define kDMTokenVerifierURL             @"https://api.twitter.com/oauth/access_token"
#define kDMCredentialsVerificationURL   @"https://api.twitter.com/1/account/verify_credentials.json"


@interface DMOAuthTwitter() {
    NSString*                       user_id;
    NSString*                       screen_name;
    
    DMTwitterLoginViewController*   currentLoginController;
    UINavigationController*         navigationController;
}

@end

@implementation DMOAuthTwitter

@synthesize screen_name, user_id;
@synthesize currentLoginController;

- (BOOL) newLoginSessionFrom:(UIViewController *) parentController
                    progress:(DMOTwitterLoginCurrentStatus) currentProgress
                completition:(DMOTwitterLoginResult) completition {
    // we have already an opened session, or current login session is already authenticated (in this case, use logout)
    if (currentLoginController != nil || self.oauth_token_authorized) return NO;

    currentLoginController = [[DMTwitterLoginViewController alloc] initWithOAuthSession:self
                                                                        progressHandler: currentProgress
                                                                    completitionHanlder:completition];
    navigationController = [[UINavigationController alloc] initWithRootViewController:currentLoginController];
    [parentController presentModalViewController:navigationController animated:YES];
    return YES;
}

#pragma mark -
#pragma mark Init and dealloc

- (id) initWithConsumerKey:(NSString *)aConsumerKey andConsumerSecret:(NSString *)aConsumerSecret {
    if ((self = [super initWithConsumerKey:aConsumerKey andConsumerSecret:aConsumerSecret])) {
        self.user_id = nil;
		self.screen_name = nil;
    }
    return self;
}

#pragma mark -
#pragma mark Twitter convenience methods

- (void) requestTwitterTokenWithCallbackUrl:(NSString *) callbackUrl
                               completition:(DMOAuthTwitterTokenRequestResult) tokenReqResult {
    
    self.oauth_token_authorized = NO;
    self.oauth_token = nil;
    self.oauth_token_secret = nil;
    
    // Calculate the header.
    // Guard against someone forgetting to set the callback. Pretend that we have out-of-band request
    // in that case.
    NSString *_callbackUrl = callbackUrl;
    if (!callbackUrl)
        _callbackUrl = @"oob";
    
    NSDictionary *request_params = [NSDictionary dictionaryWithObjectsAndKeys:_callbackUrl,@"oauth_callback", nil];
    NSString* oauth_header = [self oAuthHeaderForMethod:@"POST" 
                                                 andUrl:kDMAuthRequestTokenURL 
                                              andParams:request_params];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:kDMAuthRequestTokenURL]
                                                           cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData
                                                       timeoutInterval:7.0f];
    [request setHTTPMethod:@"POST"];
    [request addValue:oauth_header forHTTPHeaderField:@"Authorization"];
    
    NSHTTPURLResponse* response = nil;
    NSError *error = nil;
    
    NSData *data = [NSURLConnection sendSynchronousRequest:request
                                         returningResponse:&response
                                                     error:&error];
    NSString *responseString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    if ([response statusCode] != 200) {
        dispatch_async(dispatch_get_main_queue(), ^{
            tokenReqResult(nil,response,error);
        });
    } else {
        NSArray *responseBodyComponents = [responseString componentsSeparatedByString:@"&"];
        // For a successful response, break the response down into pieces and set the properties
		// with KVC. If there's a response for which there is no local property or ivar, this
		// may end up with setValue:forUndefinedKey:.
        for (NSString *component in responseBodyComponents) {
            NSArray *subcomponents = [component componentsSeparatedByString:@"="];
            [self setValue:[subcomponents objectAtIndex:1] forKey:[subcomponents objectAtIndex:0]];
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            tokenReqResult(self.oauth_token,response,nil);
        });
    }
}

- (void) verifyTwitterAuthorizationToken:(NSString *) oauth_verifier
                            completition:(DMOAuthTwitterTokenAuthorizationResult) completition {
    // We manually specify the token as a param, because it has not yet been authorized
	// and the automatic state checking wouldn't include it in signature construction or header,
	// since oauth_token_authorized is still NO by this point.
    NSDictionary* params = [NSDictionary dictionaryWithObjectsAndKeys: 
                            self.oauth_token,@"oauth_token",
                            oauth_verifier,@"oauth_verifier",nil];
    
    NSString*oauth_ehader = [super oAuthHeaderForMethod:@"POST" 
                                                 andUrl:kDMTokenVerifierURL
                                              andParams:params
                                         andTokenSecret:self.oauth_token_secret];
    
    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:kDMTokenVerifierURL]
                                                           cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData
                                                       timeoutInterval:7.0f];
    [request setHTTPMethod:@"POST"];
    [request addValue:oauth_ehader forHTTPHeaderField:@"Authorization"];
    
    NSHTTPURLResponse* response = nil;
    NSError *error = nil;
    NSData *responseData = [NSURLConnection sendSynchronousRequest:request
                                                 returningResponse:&response
                                                             error:&error];
    NSString *responseString = [[NSString alloc] initWithData:responseData
                                                     encoding:NSUTF8StringEncoding];
    
    if ([response statusCode] != 200) {
        dispatch_async(dispatch_get_main_queue(), ^{
            completition(nil,nil,response,error);
        });
    } else {
        NSArray *responseBodyComponents = [responseString componentsSeparatedByString:@"&"];
		for (NSString *component in responseBodyComponents) {
			// Twitter as of January 2010 returns oauth_token, oauth_token_secret, user_id and screen_name.
			// We support all these.
			NSArray *subComponents = [component componentsSeparatedByString:@"="];
			[self setValue:[subComponents objectAtIndex:1] forKey:[subComponents objectAtIndex:0]];			
		}
		self.oauth_token_authorized = YES;
        
        dispatch_async(dispatch_get_main_queue(), ^{
            completition(self.screen_name,self.user_id,response,error);
        });
    }
}

- (void) validateTwitterCredentialsWithCompletition:(DMOAuthTwitterCredentialValidationResult) completition {
    NSString *oauth_header = [self oAuthHeaderForMethod:@"GET"
                                                 andUrl:kDMCredentialsVerificationURL 
                                              andParams:nil];

    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:kDMCredentialsVerificationURL]
                                                           cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData
                                                       timeoutInterval:7.0f];
    [request setHTTPMethod:@"GET"];
    [request addValue:oauth_header forHTTPHeaderField:@"Authorization"];
    
    NSHTTPURLResponse* response = nil;
    NSError *error = nil;
    
    NSData *data = [NSURLConnection sendSynchronousRequest:request
                                         returningResponse:&response
                                                     error:&error];
    NSString *resultData = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        // we use JSONKit in order to parse user's data, returned in JSON format.
        // if you don't plan to use it in your code you can remove all references
        completition(([response statusCode] == 200),[resultData objectFromJSONString]);
    });
}


#pragma mark -
#pragma mark State management, loading, saving

- (void) logout {
    self.user_id = nil;
	self.screen_name = nil;
    
    if (currentLoginController != nil) {
        [currentLoginController dismissModalViewControllerAnimated:YES];
        currentLoginController = nil;
        navigationController = nil;
    }
    [super resetState];
}

- (void) loadPersistentData:(NSDictionary *)persistentDict {
    [super loadPersistentData:persistentDict];
    self.screen_name = [persistentDict objectForKey:kDMPersistentData_ScreenName];
    self.user_id = [persistentDict objectForKey:kDMPersistentData_ScreenID];
}

- (NSDictionary *) sessionPersistentData {    
    NSMutableDictionary *data = (NSMutableDictionary*)[super sessionPersistentData];
    if (data == nil) return nil;
    
    if (self.screen_name != nil)    [data setObject:self.screen_name forKey:kDMPersistentData_ScreenName];
    if (self.user_id != nil)        [data setObject:self.user_id forKey:kDMPersistentData_ScreenID];
    return data;
}

@end
