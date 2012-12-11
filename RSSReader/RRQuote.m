//
//  RRQuote.m
//  RSSReader
//
//  Created by goldenway on 12/10/12.
//  Copyright (c) 2012 goldenway. All rights reserved.
//

#import "RRQuote.h"

@implementation RRQuote

- (void)dealloc
{
    self.number = nil;
    self.text = nil;
    self.link = nil;
    
    [super dealloc];
}

@end
