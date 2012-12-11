//
//  RRSharingCell.m
//  RSSReader
//
//  Created by goldenway on 12/7/12.
//  Copyright (c) 2012 goldenway. All rights reserved.
//

#import "RRSharingCell.h"

#define NUMBER_LEFT_OFFSET 22
#define NUMBER_TOP_OFFSET 10
#define NUMBER_WIDTH 200
#define NUMBER_HEIGHT 20
#define NUMBER_FONT [UIFont boldSystemFontOfSize:16.0]
#define BUTTON_RIGHT_OFFSET 15
#define BUTTON_TOP_OFFSET 5
#define BUTTON_WIDTH 30
#define BUTTON_HEIGHT 27

@interface RRSharingCell ()
{
    NSString *_numberStr;
}

@property (nonatomic, retain) UILabel *numberLabel;

@end

@implementation RRSharingCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self)
    {
        self.numberLabel = [[[UILabel alloc] initWithFrame:CGRectMake(NUMBER_LEFT_OFFSET,
                                                                      NUMBER_TOP_OFFSET,
                                                                      NUMBER_WIDTH,
                                                                      NUMBER_HEIGHT)] autorelease];
        self.numberLabel.backgroundColor = [UIColor clearColor];
        self.numberLabel.font = NUMBER_FONT;
        [self addSubview:self.numberLabel];
        
        UIButton *shareButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        [shareButton addTarget:self action:@selector(shareButtonClicked) forControlEvents:UIControlEventTouchUpInside];
        shareButton.frame = CGRectMake(self.frame.size.width - BUTTON_WIDTH - BUTTON_RIGHT_OFFSET,
                                       BUTTON_TOP_OFFSET,
                                       BUTTON_WIDTH,
                                       BUTTON_HEIGHT);
        [shareButton setImage:[UIImage imageNamed:@"share_btn_normal"] forState:UIControlStateNormal];
        [self addSubview:shareButton];
    }
    return self;
}

- (void)setNumberStr:(NSString *)numberStr
{
    if (numberStr != _numberStr)
    {
        [_numberStr release];
        _numberStr = [numberStr retain];
        
        self.numberLabel.text = self.numberStr;
    }
}

- (void)shareButtonClicked
{
    [self.delegate shareItemWithTag:self.buttonTag];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:NO animated:animated];
}

- (void)dealloc
{
    self.delegate = nil;
    self.numberStr = nil;
    self.numberLabel = nil;
    
    [super dealloc];
}

@end
