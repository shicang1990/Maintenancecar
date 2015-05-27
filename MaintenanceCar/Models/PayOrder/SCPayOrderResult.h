//
//  SCPayOrderResult.h
//  MaintenanceCar
//
//  Created by ShiCang on 15/5/22.
//  Copyright (c) 2015年 MaintenanceCar. All rights reserved.
//

#import <Foundation/Foundation.h>

@class SCCoupon;

typedef NS_ENUM(NSUInteger, SCPayOrderment) {
    SCPayOrdermentWeiXinPay,
    SCPayOrdermentAliPay
};

@interface SCPayOrderResult : NSObject
{
    double _resultProductPrice;
    double _resultDeductiblePrice;
}

@property (nonatomic, assign)             double  purchaseCount;
@property (nonatomic, weak)             SCCoupon *coupon;
@property (nonatomic, strong, readonly) NSString *couponCode;
@property (nonatomic, strong, readonly) NSString *totalPrice;
@property (nonatomic, strong, readonly) NSString *deductiblePrice;
@property (nonatomic, strong, readonly) NSString *payPrice;
@property (nonatomic, strong, readonly) NSString *useCoupon;

- (void)setResultProductPrice:(double)productPrice;

@end
