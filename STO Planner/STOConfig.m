//
//  MPConfig.m
//  MasterPassword
//
//  Created by Maarten Billemont on 02/01/12.
//  Copyright (c) 2012 Lyndir. All rights reserved.
//

#import "STOConfig.h"

@implementation STOConfig

- (id)init {

    if (!(self = [super init]))
        return nil;

    [self.defaults registerDefaults:@{
            NSStringFromSelector( @selector( askForReviews ) ) : @YES,
            NSStringFromSelector( @selector( appleID ) )       : @"1067388294",
    }];

    return self;
}

@end
