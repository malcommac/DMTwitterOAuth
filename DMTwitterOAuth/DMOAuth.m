//
//  DMOAuth.m
//  DMTwitterOAuth
//
//  Created by Daniele Margutti (daniele.margutti@gmail.com) on 5/13/12.
//  From an original work by Jaanus Kase
//  Copyright (c) 2012 http://danielem.org. All rights reserved.
//

#import "DMOAuth.h"
#import "NSString+SHA1Extensions.h"
#import "NSString+URLEncoding.h"

// Fixed to "1.0". Although now that we support v2 too, should fix this.
#define kOAuthVersion               @"1.0"          
#define kOAuthSignatureMethod       @"HMAC-SHA1"

@interface DMOAuth() {
    NSString*               oauth_consumer_key;         // app credentials consumer key
    NSString*               oauth_consumer_secret;      // app credentials consumer secret
	
    NSString*               oauth_signature_method;     // fixed to "HMAC-SHA1"
	
    // calculated at runtime for each signature
    NSString*               oauth_timestamp;
    NSString*               oauth_nonce;
	
    NSString*               oauth_version;

	// YES if this token has been authorized and can be used for production calls.
	BOOL oauth_token_authorized;

    // We obtain these from the provider.
    // These may be either request token (oauth 1.0a 6.1.2) or access token (oauth 1.0a 6.3.2);
    // determine semantics with oauth_token_authorized and call synchronousVerifyCredentials
    // if you want to be really sure.
    //
    // For OAuth 2.0, the token simply stores the token that the provider issued, and
    // token_secret is undefined.
    NSString*               oauth_token;
    NSString*               oauth_token_secret;
    
}
@end

@interface DMOAuth(Private)

// Internal methods, no need to call these directly from outside.
- (NSString *) oauth_signature_base:(NSString *)httpMethod withUrl:(NSString *)url andParams:(NSDictionary *)params;
- (NSString *) oauth_authorization_header:(NSString *)oauth_signature withParams:(NSDictionary *)params;
- (NSString *) sha1:(NSString *)str;
- (NSArray *) oauth_base_components;

@end

@implementation DMOAuth

@synthesize oauth_token,oauth_token_secret,oauth_token_authorized;
@synthesize oauth_consumer_secret,oauth_consumer_key;

/**
 * Initialize an OAuth context object with a given consumer key and secret. These are immutable as you
 * always work in the context of one app.
 */
- (id) initWithConsumerKey:(NSString *)aConsumerKey andConsumerSecret:(NSString *)aConsumerSecret {
	if ((self = [super init])) {
		self.oauth_consumer_key = aConsumerKey;
		self.oauth_consumer_secret = aConsumerSecret;
		oauth_signature_method = kOAuthSignatureMethod;
		oauth_version = kOAuthVersion;
		self.oauth_token = @"";
		self.oauth_token_secret = @"";
		srandom(time(NULL)); // seed the random number generator, used for generating nonces
		self.oauth_token_authorized = NO;
    }
	
	return self;
}

- (id)initWithPersistentData:(NSDictionary *) persistentData {
    self = [self initWithConsumerKey:nil andConsumerSecret:nil];
    if (self) {
        [self loadPersistentData:persistentData];
    }
    return self;
}

- (id)init
{
    self = [self initWithConsumerKey:nil andConsumerSecret:nil];
    if (self) {
        
    }
    return self;
}

#pragma mark -
#pragma mark KVC

/**
 * We specify a set of keys that are known to be returned from OAuth responses, but that we are not interested in.
 * In case of any other keys, we log them since they may indicate changes in API that we are not prepared
 * to deal with, but we continue nevertheless.
 * This is only relevant for the Twitter request/authorize convenience methods that do HTTP calls and parse responses.
 */
- (void)setValue:(id)value forUndefinedKey:(NSString *)key {
	// KVC: define a set of keys that are known but that we are not interested in. Just ignore them.
	if ([[NSSet setWithObjects: @"oauth_callback_confirmed",nil] containsObject:key]) {
        // ... but if we got a new key that is not known, log it.
	} else {
		NSLog(@"Got unknown key from provider response. Key: \"%@\", value: \"%@\"", key, value);
	}
}

#pragma mark -
#pragma mark Public methods

/**
 * You will be calling this most of the time in your app, after the bootstrapping (authorization) is complete. You pass it
 * a set of information about your HTTP request (HTTP method, URL and any extra parameters), and you get back a header value
 * that you can put in the "Authorization" header. The header will also include a signature.
 *
 * "params" should be NSDictionary with any extra material to add in the signature. If you are doing a POST request,
 * this needs to exactly match what you will be POSTing. If you are GETting, this should include the parameters in your
 * QUERY_STRING; if there are none, this is nil.
 */
- (NSString *) oAuthHeaderForMethod:(NSString *)method andUrl:(NSString *)url andParams:(NSDictionary *)params {
	return [self oAuthHeaderForMethod:method 
							   andUrl:url
							andParams:params
					   andTokenSecret:self.oauth_token_authorized ? oauth_token_secret : @""];
}

/**
 * An extra method that lets the caller override the token secret used to sign the header. This is determined automatically
 * most of the time based on if our token has been authorized or not and you can use the method without the extra parameter,
 * but we need to override it for our /authorize request because our token has not been authorized by this point,
 * yet we still need to sign our /authorize request with both consumer and token secrets.
 */
- (NSString *) oAuthHeaderForMethod:(NSString *)method
							 andUrl:(NSString *)url
						  andParams:(NSDictionary *)params
					 andTokenSecret:(NSString *)token_secret {
    	
	// If there were any params, URLencode them. Also URLencode their keys.
	NSMutableDictionary *_params = [NSMutableDictionary dictionaryWithCapacity:[params count]];
	if (params) {
		for (NSString *key in [params allKeys]) {
			[_params setObject:[[params objectForKey:key] encodedURLParameterString] forKey: [key encodedURLParameterString]];
		}
	}

    // Given a signature base and secret key, calculate the signature.
    NSString *clear_text = [self oauth_signature_base:method
                                              withUrl:url
                                            andParams:_params];
    NSString *oauth_signature = [clear_text signClearTextWithSecret: [NSString stringWithFormat:@"%@&%@", oauth_consumer_secret, token_secret]];
	
	// Return the authorization header using the signature and parameters (if any).
	return [self oauth_authorization_header:oauth_signature withParams:_params];
}

/**
 * When the user invokes the "sign out" function in the app, forget the current OAuth context.
 * We still remember consumer key and secret
 * since those are for an app and don't change, but we forget everything else.
 */
- (void) resetState {
	self.oauth_token_authorized = NO;
	self.oauth_token = @"";
	self.oauth_token_secret = @"";
}

#pragma mark -
#pragma mark Loading and saving

- (NSDictionary *) sessionPersistentData {
    if (self.oauth_token_authorized == NO) return nil;

    NSMutableDictionary* data = [[NSMutableDictionary alloc] init];
    
    if (self.oauth_token != nil) [data setObject:self.oauth_token forKey:kDMPersistentData_AuthToken];
    if (self.oauth_token_secret != nil) [data setObject:self.oauth_token_secret forKey:kDMPersistentData_AuthTokenSecret];
    if (self.oauth_token_secret != nil) [data setObject:[NSNumber numberWithBool:self.oauth_token_authorized] forKey:kDMPersistentData_AuthTokenIsAuthorized];
    if (self.oauth_token_secret != nil) [data setObject:self.oauth_consumer_key forKey:kDMPersistentData_ConsumerKey];
    if (self.oauth_consumer_secret != nil) [data setObject:self.oauth_consumer_secret forKey:kDMPersistentData_ConsumerSecret];
    
    return data;
}

- (void) loadPersistentData:(NSDictionary *) persistentDict {
    self.oauth_consumer_key = [persistentDict objectForKey:kDMPersistentData_ConsumerKey];
    self.oauth_consumer_secret = [persistentDict objectForKey:kDMPersistentData_ConsumerSecret];
    self.oauth_token = [persistentDict objectForKey:kDMPersistentData_AuthToken];
    self.oauth_token_secret = [persistentDict objectForKey:kDMPersistentData_AuthTokenSecret];
    self.oauth_token_authorized = [[persistentDict objectForKey:kDMPersistentData_AuthTokenIsAuthorized] boolValue];
}


#pragma mark -
#pragma mark Internal utilities for crypto, signing.

/**
 * Given a HTTP method, URL and a set of parameters, calculate the signature base string according to the spec.
 * Some ideas for the implementation come from OAMutableUrlRequest
 * (http://oauth.googlecode.com/svn/code/obj-c/OAuthConsumer/OAMutableURLRequest.m).
 */
- (NSString *) oauth_signature_base:(NSString *)httpMethod withUrl:(NSString *)url andParams:(NSDictionary *)params {
	
	// Freshen the context. Get a fresh timestamp and calculate a nonce.
	// Nonce algorithm is sha1(timestamp || random), i.e
	// we concatenate timestamp with a random string, and then sha1 it.
	int timestamp = time(NULL);
	oauth_timestamp = [NSString stringWithFormat:@"%d", timestamp];
	int myRandom = random();
	oauth_nonce = [self sha1:[NSString stringWithFormat:@"%d%d", timestamp, myRandom]];
	
	NSMutableDictionary *parts = [NSMutableDictionary dictionaryWithCapacity:[[self oauth_base_components] count]];
	
	[NSMutableArray arrayWithCapacity:[[self oauth_base_components] count]];
	
	// Include all the OAuth base components into signature base string, no matter what else is going on.
	for (NSString *part in [self oauth_base_components]) {
		[parts setObject:[self valueForKey:part] forKey:part];
	}
	
	if (params) {		
		[parts addEntriesFromDictionary:params];
	}
	
	// Sort the base string components and make them into string key=value pairs.
	NSMutableArray *normalizedBase = [NSMutableArray arrayWithCapacity:[parts count]];
	for (NSString *key in [[parts allKeys] sortedArrayUsingSelector:@selector(compare:)]) {
		[normalizedBase addObject:[NSString stringWithFormat:@"%@=%@", key, [parts objectForKey:key]]];
	}
	
	NSString *normalizedRequestParameters = [normalizedBase componentsJoinedByString:@"&"];
	
	// Return the signature base string. Note that the individual parameters must have previously
	// already URL-encoded and here we are encoding them again; thus you will see some
	// double URL-encoding for params. This is normal.
	return [NSString stringWithFormat:@"%@&%@&%@",
            httpMethod,
            [url encodedURLParameterString],
            [normalizedRequestParameters encodedURLParameterString]];
}

/**
 * Given a calculated signature (by this point it is Base64-encoded string) and a set of parameters, return
 * the header value that you will stick in the "Authorization" header.
 */
- (NSString *) oauth_authorization_header:(NSString *)oauth_signature withParams:(NSDictionary *)params {
	NSMutableArray *chunks = [[NSMutableArray alloc] init];
	
	// First add all the base components.
	[chunks addObject:[NSString stringWithString:@"OAuth realm=\"\""]];
	for (NSString *part in [self oauth_base_components]) {
		[chunks addObject:[NSString stringWithFormat:@"%@=\"%@\"", part, [[self valueForKey:part] encodedURLParameterString]]];
	}
	
	// Add parameter values if any. They don't really have to be sorted, but we do it anyway
	// just to be nice and make the output somewhat more parsable.
	if (params) {
		for (NSString *key in [[params allKeys] sortedArrayUsingSelector:@selector(compare:)]) {		
			[chunks addObject:[NSString stringWithFormat:@"%@=\"%@\"", key, [params objectForKey:key]]];
		}
	}
	
	// Signature will be the last component of our header.
	[chunks addObject:[NSString stringWithFormat:@"%@=\"%@\"", @"oauth_signature", [oauth_signature encodedURLParameterString]]];
	
	return [NSString stringWithFormat:@"%@", [chunks componentsJoinedByString:@", "]];
}

/**
 * Return the set of OAuth base components to always include in signature base string and header. If we have an authorized token, we use it,
 * otherwise we don't. The token is not authorized for /request and /access_token. For the former, we don't need to include the token.
 * For the latter, we include it manually as an input parameter to the methods.
 */
- (NSArray *) oauth_base_components {
	if (self.oauth_token_authorized) {
		return [NSArray arrayWithObjects:@"oauth_timestamp", @"oauth_nonce",
				@"oauth_signature_method", @"oauth_consumer_key", @"oauth_version", @"oauth_token", nil];
	} else {
		return [NSArray arrayWithObjects:@"oauth_timestamp", @"oauth_nonce",
				@"oauth_signature_method", @"oauth_consumer_key", @"oauth_version", nil];
	}
}

// http://stackoverflow.com/questions/1353771/trying-to-write-nsstring-sha1-function-but-its-returning-null
- (NSString *)sha1:(NSString *)str {
	const char *cStr = [str UTF8String];
	unsigned char result[CC_SHA1_DIGEST_LENGTH];
	CC_SHA1(cStr, strlen(cStr), result);
	NSMutableString *out = [NSMutableString stringWithCapacity:20];
	for (int i = 0; i < CC_SHA1_DIGEST_LENGTH; i++) {
		[out appendFormat:@"%02X", result[i]];
	}
	return [out lowercaseString];
}
@end
