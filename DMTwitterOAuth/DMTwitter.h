//
//  DMTwitter.h
//  DMTwitterOAuth
//
//  Created by Daniele Margutti (daniele.margutti@gmail.com) on 5/13/12.
//  From an original work by Jaanus Kase
//  Copyright (c) 2012 http://danielem.org. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DMOAuthTwitter.h"

/*
 DMTwitter is a singleton for a DMOAuthTwitter object.
 If you don't plan to user more authentication session in a program you should safely use it instead of
 a custom instance of DMAuthTwitter (that's the standard way of course).
 
 Generally you will use this class using built-in Twitter Login View Controller (I've also exposed engine's call in DMOAuthTwitter
 if you want to implement your custom login panel).
 Before doing anything you need to follow these simple steps:
 
    #STEP 1. REGISTER YOUR APP'S CUSTOM URL SCHEME
    ==============================================
    This library uses Callback OAuth Authentication Method so Twitter Login Panel need to know how to handle response from twitter's server.
    You need to register your custom twitter login scheme (each app should have an unique login scheme) in your App Info.plist file.
    
    Create an CFBundleURLTypes key (array) and add a new item (a dictionary):
    It should have 3 keys:
        CFBundleTypeRole    = "Editor"
        CFBundleURLName     = <your custom url identifier> (ie com.firelabsw.dmtwitteroauth)
        CFBundleURLSchemes  = an array with one item, your custom scheme (*)
    
    (*) You can create a custom scheme and assign it to DMTwitterLoginViewController istance's customScheme property.
        You can also use our default notation: [tw]+[your app identifier] so if your app identifier is
        "com.firelabsw.DMTwitterOAuth" (as this example) your custom scheme is
        "twdmtwitteroauth" (all *lowercase*).
        
        In this sample app named DMTwitterOAuth our scheme is twdmtwitteroauth (and we have not assigned any custo scheme)
 
    #STEP 2. ASSIGN YOUR CONSUMER/SECRET KEY
    ========================================
    When you have created your twitter app from http://dev.twitter.com/ you have obtained two keys:
        - Consumer Key
        - Consumer Secret Key
    Edit kDMTwitterSingleton_ConsumerKey and kDMTwitterSingleton_SecretKey below in this file.
 
    #STEP 3. HANDLE TWITTER AUTH URL REQUESTS
    =========================================
    In your App Delegate (here DMAppDelegate.m) file you need to catch the handle:
        - (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation;
 
    You need to pass this URL (if it's related to your custom Twitter Auth URL Scheme) to DMOAuthTwitter instance.
    If you use DMTwitter singleton it's very easy. Just put:
 
        return [[DMTwitter shared].currentLoginController handleTokenRequestResponseURL:url];
 
    #STEP 4. PRESENT TWITTER LOGIN PANEL TO THE USER
    ================================================
    You are now ready. Everything is ok for your login!
    Use:
        [[DMTwitter shared] newLoginSessionFrom:progress:completition:]
 
    in order to show you login session window and allow user's authentication.
    Thanks to blocks you'll be informed about current login progress by progress handler and completition inside completition handler.
    Just one line of code and you have implemented your Twitter login!
    
 
                                                            OTHER INFOS...
 
 
 
    HOW TO SAVE USER'S CREDENTIALS
    ==============================
    If you use DMTwitter singleton you can save user's authentication data using:
        [[DMTwitter shared] saveCredentials];
    
    Credentials will stored inside application's NSUserDefaults and at next app's startup will be loaded automatically.
    (If you want to implement your custom saving methods use -sessionPersistentData to get credentials
     and -loadPersistentData: to reload them in a DMOAuthTwitter object.
 
 
    LOGOUT
    ======
    To logout from an authenticated session just use -logout method.
 */

#define kDMTwitterSingleton_ConsumerKey                 @"_REPLACE_WITH_YOUR_CONSUMER_KEY"
#define kDMTwitterSingleton_SecretKey                   @"_REPLACE_WITH_YOUR_SECRET_KEY"

@interface DMTwitter : DMOAuthTwitter {
    
}

// If you don't plan to use more than an DMOAuthTwitter object in your app you can use this singleton. It will save to you a lot of time!
+ (DMTwitter *) shared;

// Allows to save credentials (if are valid). These data will be restored automatically between app's session.
- (BOOL) saveCredentials;

@end
