//
//  NSString+SHA1Extensions.h
//  DMTwitterOAuth
//
//  Created by Daniele Margutti (daniele.margutti@gmail.com) on 5/13/12.
//  From an original work by Jaanus Kase
//  Copyright (c) 2012 http://danielem.org. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (SHA1Extensions) {
    
}

- (NSString *)signClearTextWithSecret:(NSString *)secret;

@end
