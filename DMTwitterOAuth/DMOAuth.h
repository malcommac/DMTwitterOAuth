//
//  DMOAuth.h
//  DMTwitterOAuth
//
//  Created by Daniele Margutti (daniele.margutti@gmail.com) on 5/13/12.
//  From an original work by Jaanus Kase
//  Copyright (c) 2012 http://danielem.org. All rights reserved.
//

#import <Foundation/Foundation.h>
#include <CommonCrypto/CommonDigest.h>

#define kDMPersistentData_ConsumerKey               @"consumer_key"
#define kDMPersistentData_ConsumerSecret            @"consumer_secret"

#define kDMPersistentData_AuthToken                 @"auth_token"
#define kDMPersistentData_AuthTokenSecret           @"auth_token_secret"
#define kDMPersistentData_AuthTokenIsAuthorized     @"auth_token_authorized"


@interface DMOAuth : NSObject {
    
}

@property (assign)  BOOL                oauth_token_authorized;
@property (copy)    NSString *          oauth_token;
@property (copy)    NSString *          oauth_token_secret;
@property (copy)    NSString *          oauth_consumer_key;
@property (copy)    NSString *          oauth_consumer_secret;

- (id)init;

- (id)initWithPersistentData:(NSDictionary *) persistentData;

// You initialize the object with your app (consumer) credentials.
- (id) initWithConsumerKey:(NSString *)aConsumerKey andConsumerSecret:(NSString *)aConsumerSecret;

// This is really the only critical oAuth method you need.
- (NSString *) oAuthHeaderForMethod:(NSString *)method andUrl:(NSString *)url andParams:(NSDictionary *)params;	

// Child classes need this method during initial authorization phase. No need to call during real-life use.
- (NSString *) oAuthHeaderForMethod:(NSString *)method andUrl:(NSString *)url andParams:(NSDictionary *)params
					 andTokenSecret:(NSString *)token_secret;

// If you detect a login state inconsistency in your app, use this to reset the context back to default,
// not-logged-in state.
- (void) resetState;

- (NSDictionary *) sessionPersistentData;
- (void) loadPersistentData:(NSDictionary *) persistentDict;

@end
