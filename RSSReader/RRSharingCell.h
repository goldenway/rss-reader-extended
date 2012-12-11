//
//  RRSharingCell.h
//  RSSReader
//
//  Created by goldenway on 12/7/12.
//  Copyright (c) 2012 goldenway. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol RRSharingCellDelegate <NSObject>

- (void)shareItemWithTag:(int)tag;

@end

@interface RRSharingCell : UITableViewCell

@property (nonatomic, assign) id <RRSharingCellDelegate> delegate;
@property (nonatomic, retain) NSString *numberStr;
@property (nonatomic) int buttonTag;

@end
