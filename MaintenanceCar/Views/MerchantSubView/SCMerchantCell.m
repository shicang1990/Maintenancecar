//
//  SCMerchantCell.m
//  MaintenanceCar
//
//  Created by ShiCang on 15/1/30.
//  Copyright (c) 2015年 MaintenanceCar. All rights reserved.
//

#import "SCMerchantCell.h"
#import <HexColors/HexColor.h>
#import "MicroCommon.h"
#import "SCStarView.h"
#import "SCMerchant.h"
#import "SCMerchantFlagCell.h"
#import "SCAllDictionary.h"

@interface SCMerchantCell () <UICollectionViewDataSource>
{
    NSDictionary *_colors;
    NSArray      *_merchantFlags;
}

@end

@implementation SCMerchantCell

#pragma mark - Init Methods
- (void)awakeFromNib
{
    [self initConfig];
}

#pragma mark - Private Methods
- (void)initConfig
{
    _flagView.dataSource = self;
    // 圆角和颜色处理
    _specialLabel.layer.cornerRadius = 2.0f;
    _specialLabel.layer.borderWidth = 1.0f;
    _specialLabel.layer.borderColor = UIColorWithRGBA(230.0f, 109.0f, 81.0f, 1.0f).CGColor;
}

- (UIColor *)iconColorWithName:(NSString *)name
{
    NSString *hexString = _colors[name];
    return hexString ? [UIColor colorWithHexString:_colors[name]] : [UIColor clearColor];
}

#pragma mark - Public Methods
- (void)handelWithMerchant:(SCMerchant *)merchant
{
    _merchantNameLabel.text = merchant.name;
    _distanceLabel.text     = merchant.distance;
    _starView.startValue    = merchant.star;
    _specialLabel.text      = merchant.tags.length ? merchant.tags : @"价格实惠";
    
    [[SCAllDictionary share] requestColors:^(NSDictionary *colors) {
        _colors        = colors;
        _merchantFlags = merchant.merchantFlags;
        
        _flagViewWidthConstraint.constant = _merchantFlags.count * 16.0f;
        [_flagView needsUpdateConstraints];
        [_flagView layoutIfNeeded];
        [_flagView reloadData];
    }];
}

#pragma mark - Collection View Data Source Methods
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return _merchantFlags.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    SCMerchantFlagCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"SCMerchantFlagCell" forIndexPath:indexPath];
    NSString *flag = _merchantFlags[indexPath.row];
    cell.textLabel.text = flag;
    cell.textLabel.backgroundColor = [self iconColorWithName:flag];
    return cell;
}

@end
