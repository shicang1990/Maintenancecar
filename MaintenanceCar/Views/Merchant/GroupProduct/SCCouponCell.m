//
//  SCCouponCell.m
//  MaintenanceCar
//
//  Created by ShiCang on 15/3/9.
//  Copyright (c) 2015年 MaintenanceCar. All rights reserved.
//

#import "SCCouponCell.h"
#import "SCCoupon.h"

@implementation SCCouponCell

#pragma mark - Public Methods
- (void)displayCellWithCoupon:(SCCoupon *)coupon index:(NSInteger)index
{
    [super displayCellWithCoupon:coupon index:index];
    
    _productNameLabel.text  = [coupon.title stringByAppendingString:@":"];
    _merchantNameLabel.text = coupon.company_name;
    _couponPriceLabel.text  = coupon.final_price;
    _productPriceLabel.text = coupon.total_price;
    _couponStateLabel.text  = [self codeStateWithCoupon:coupon.state];
    
    _codeLine.hidden = (coupon.state == SCCouponStateUnUse);
    self.codeLabel.textColor = (coupon.state == SCCouponStateUnUse) ? [UIColor orangeColor] : [UIColor lightGrayColor];
}

#pragma mark - Private Methods
- (NSString *)codeStateWithCoupon:(SCCouponState)state
{
    NSString *codeState;
    switch (state)
    {
        case SCCouponStateUnUse:
            codeState = @"未使用";
            break;
        case SCCouponStateUsed:
            codeState = @"已使用";
            break;
        case SCCouponStateCancel:
            codeState = @"已取消";
            break;
        case SCCouponStateExpired:
            codeState = @"已过期";
            break;
        case SCCouponStateRefunding:
            codeState = @"退款中";
            break;
        case SCCouponStateRefunded:
            codeState = @"已退款";
            break;
        case SCCouponStateReserved:
            codeState = @"已预约";
            break;
            
        default:
            codeState = @"-";
            break;
    }
    return codeState;
}

@end
