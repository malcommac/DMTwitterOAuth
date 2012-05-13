//
//  DMTwitter.m
//  DMTwitterOAuth
//
//  Created by Daniele Margutti (daniele.margutti@gmail.com) on 5/13/12.
//  From an original work by Jaanus Kase
//  Copyright (c) 2012 http://danielem.org. All rights reserved.
//

#import "DMTwitter.h"

#define kDMTwitterSingleton_PersistentData  @"kDMTwitterSingleton_PersistentData"

@implementation DMTwitter

+ (DMTwitter *) shared {
    static dispatch_once_t pred;
    static DMTwitter *shared = nil;
    
    dispatch_once(&pred, ^{
        NSData *saved_credentials = [[NSUserDefaults standardUserDefaults] objectForKey:kDMTwitterSingleton_PersistentData];
        if (saved_credentials != nil)
            shared = [[DMTwitter alloc] initWithPersistentData:[NSKeyedUnarchiver unarchiveObjectWithData:saved_credentials]];
        else
            shared = [[DMTwitter alloc] initWithConsumerKey:kDMTwitterSingleton_ConsumerKey
                                          andConsumerSecret:kDMTwitterSingleton_SecretKey];
    });
    return shared;
}

- (void) logout {
    [super logout];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kDMTwitterSingleton_PersistentData];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (BOOL) saveCredentials {
    if (self.oauth_token_authorized == NO) return NO;
    [[NSUserDefaults standardUserDefaults] setObject:[NSKeyedArchiver archivedDataWithRootObject:[self sessionPersistentData]]
                                              forKey:kDMTwitterSingleton_PersistentData];
    [[NSUserDefaults standardUserDefaults] synchronize];
    return YES;
}

@end
