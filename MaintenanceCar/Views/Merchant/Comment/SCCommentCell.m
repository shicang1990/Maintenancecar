//
//  SCCommentCell.m
//  MaintenanceCar
//
//  Created by ShiCang on 15/3/15.
//  Copyright (c) 2015年 MaintenanceCar. All rights reserved.
//

#import "SCCommentCell.h"
#import "SCComment.h"
#import "SCStarView.h"
#import "SCAPIRequest.h"

@implementation SCCommentCell

- (void)awakeFromNib
{
    // Initialization code
}

#pragma mark - Public Methods
- (void)displayCellWithComment:(SCComment *)comment
{
//    [_userIcon setImageWithURL:<#(NSString *)#> defaultImage:<#(NSString *)#>]
    _userNameLabel.text    = [NSString stringWithFormat:@"修养车主（%@）", comment.phone];
    _starView.value        = [@([comment.star integerValue]/2) stringValue];
    _commentDateLabel.text = comment.create_time;
    _contentLabel.text     = comment.detail;
}
@end