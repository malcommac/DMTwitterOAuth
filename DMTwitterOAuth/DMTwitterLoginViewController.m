//
//  DMTwitterLoginViewController.m
//  DMTwitterOAuth
//
//  Created by Daniele Margutti (daniele.margutti@gmail.com) on 5/13/12.
//  From an original work by Jaanus Kase
//  Copyright (c) 2012 http://danielem.org. All rights reserved.
//

#import "DMTwitterLoginViewController.h"
#import "DMOAuthTwitter.h"

@interface DMTwitterLoginViewController () <UIWebViewDelegate,UIAlertViewDelegate> {
                UIActivityIndicatorView*        activityIndicator;
    IBOutlet    UIWebView*                      webView;
    
                DMOAuthTwitter*                 OAuthTwitter;
                DMOTwitterLoginCurrentStatus    handler_currentStatus;
                DMOTwitterLoginResult           handler_loginFinalResult;
}

- (void) urlcallback_requestTokenWithCallbackUrl:(NSString *)callbackUrl;

- (void) handleResultFromTwitterTokenRequest:(NSString *) token response:(NSHTTPURLResponse *) response error:(NSError *) error;
- (void) handleOAuthVerifier:(NSString *) key;

- (void) startLoginRequest;

@end

@implementation DMTwitterLoginViewController

@synthesize webView;
@synthesize customURLScheme;

- (id)initWithOAuthSession:(DMOAuthTwitter *) authObj
           progressHandler:(DMOTwitterLoginCurrentStatus) currentProgress
       completitionHanlder:(DMOTwitterLoginResult) completition {
    self = [super initWithNibName:@"DMTwitterLoginViewController" bundle:nil];
    if (self) {
        OAuthTwitter = authObj;
        handler_currentStatus = currentProgress;
        handler_loginFinalResult = completition;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.title = @"Twitter Login";
    activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:activityIndicator];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                                           target:self
                                                                                           action:@selector(btn_cancelLoginSession:)];
    
    webView.dataDetectorTypes = UIDataDetectorTypeNone;
    webView.scalesPageToFit = YES;
    webView.delegate = self;
}

- (void)dealloc {
    webView.delegate = nil;
    [webView stopLoading];
}

- (void) btn_cancelLoginSession:(id) sender {
    [activityIndicator stopAnimating];
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    [OAuthTwitter logout];
    [self.navigationController dismissModalViewControllerAnimated:YES];
}

- (void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    handler_currentStatus(DMOTwitterLoginStatus_PromptUserData);
    [self startLoginRequest];
}

- (void) startLoginRequest {
    NSString *callback_url = self.customURLScheme;
    
    if (self.customURLScheme == nil) {
        NSString* appID = [[[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleIdentifier"] componentsSeparatedByString:@"."] lastObject];
        callback_url = [[NSString stringWithFormat:@"tw%@://handleOAuthLogin",appID] lowercaseString];
    }
    [self urlcallback_requestTokenWithCallbackUrl:callback_url];
}

- (void) urlcallback_requestTokenWithCallbackUrl:(NSString *)callbackUrl {
    handler_currentStatus(DMOTwitterLoginStatus_RequestingToken);
    
    [OAuthTwitter requestTwitterTokenWithCallbackUrl:callbackUrl
                                        completition:^(NSString *token, NSHTTPURLResponse *response, NSError *error) {
                                            [self handleResultFromTwitterTokenRequest:token response:response error:error];
                                        }];
}

- (BOOL) handleTokenRequestResponseURL:(NSURL *) url {
    NSArray *urlComponents = [[url absoluteString] componentsSeparatedByString:@"?"];
    NSArray *requestParameterChunks = [[urlComponents objectAtIndex:1] componentsSeparatedByString:@"&"];
    for (NSString *chunk in requestParameterChunks) {
        NSArray *keyVal = [chunk componentsSeparatedByString:@"="];
        
        if ([[keyVal objectAtIndex:0] isEqualToString:@"oauth_verifier"])
            [self handleOAuthVerifier:[keyVal objectAtIndex:1]];
    }
    return YES;
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    NSString *button_title = (buttonIndex < 0 ? nil : [alertView buttonTitleAtIndex:buttonIndex]);
    
    if (alertView.tag == DMOTwitterLoginStatus_TokenReceived) {
        if ([button_title isEqualToString:@"Cancel"])
            [self.navigationController dismissModalViewControllerAnimated:YES];
        else if ([button_title isEqualToString:@"Try Again"])
            [self startLoginRequest];
    }
}


- (void)viewDidUnload {
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - WEBVIEW DELEGATE

- (void)webViewDidStartLoad:(UIWebView *)webView {
    [activityIndicator startAnimating];
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    [activityIndicator stopAnimating];
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
}

#pragma mark - EVENTS HANDLER


- (void) handleResultFromTwitterTokenRequest:(NSString *) token response:(NSHTTPURLResponse *) response error:(NSError *) error {
    handler_currentStatus(DMOTwitterLoginStatus_TokenReceived);
    
    if (error != nil) {
        UIAlertView *a = [[UIAlertView alloc] initWithTitle:@"Failed to get token"
                                                    message:[error domain]
                                                   delegate:self
                                          cancelButtonTitle:@"Cancel"
                                          otherButtonTitles:@"Try Again", nil];
        a.tag = DMOTwitterLoginStatus_TokenReceived;
        [a show];
    } else {
        NSURL *destinationURL = [NSURL URLWithString:[NSString stringWithFormat:@"https://api.twitter.com/oauth/authorize?oauth_token=%@",token]];
        [webView loadRequest:[NSURLRequest requestWithURL:destinationURL]];
    }
}

- (void) handleOAuthVerifier:(NSString *) key {
    handler_currentStatus(DMOTwitterLoginStatus_VerifyingToken);
    
    [OAuthTwitter verifyTwitterAuthorizationToken:key
                                     completition:^(NSString *screenName, NSString *user_id, NSHTTPURLResponse *response, NSError *error) {
                                         handler_currentStatus(DMOTwitterLoginStatus_TokenVerified);
                                         handler_loginFinalResult(screenName,user_id,error);
                                         [self.navigationController dismissModalViewControllerAnimated:YES];
                                     }];
}

@end
