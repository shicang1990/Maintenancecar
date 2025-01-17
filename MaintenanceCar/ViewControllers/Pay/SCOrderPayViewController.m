//
//  SCOrderPayViewController.m
//  MaintenanceCar
//
//  Created by ShiCang on 15/5/21.
//  Copyright (c) 2015年 MaintenanceCar. All rights reserved.
//

#import "SCOrderPayViewController.h"
#import "SCPayOrderMerchandiseSummaryCell.h"
#import "SCPayOderTicketCell.h"
#import "SCPayOrderGroupProductSummaryCell.h"
#import "SCPayOrderEnterCodeCell.h"
#import "SCNoValidCouponCell.h"
#import "SCPayOrderCouponCell.h"
#import "SCPayOrderResultCell.h"
#import <Weixin/WXApi.h>
#import <AlipaySDK/AlipaySDK.h>
#import "SCWeiXinPayOrder.h"
#import "SCAliPayOrder.h"
#import "SCCouponsViewController.h"

typedef NS_ENUM(NSInteger, SCAliPayCode) {
    SCAliPayCodePaySuccess    = 9000,
    SCAliPayCodePayProcessing = 8000,
    SCAliPayCodePayFailure    = 4000,
    SCAliPayCodeUserCancel    = 6001,
    SCAliPayCodeNetworkError  = 6002
};

@interface SCOrderPayViewController () <SCPayOrderMerchandiseSummaryCellDelegate, SCPayOrderGroupProductSummaryCellDelegate, SCPayOrderEnterCodeCellDelegate, SCPayOrderCouponCellDelegate, SCPayOrderResultCellDelegate, SCCouponsViewControllerDelegate> {
    NSMutableArray   *_tickets;
    NSMutableArray   *_coupons;
    SCPayOrderResult *_payResult;
    
    SCPayOrderGroupProductSummaryCell *_groupProductSummaryCell;
    SCPayOrderMerchandiseSummaryCell  *_merchandiseSummaryCell;
    SCPayOrderResultCell              *_payResultCell;
}

@end

@implementation SCOrderPayViewController

#pragma mark - View Controller Life Cycle
- (void)viewWillAppear:(BOOL)animated {
    // 用户行为统计，页面停留时间
    [super viewWillAppear:animated];
    [MobClick beginLogPageView:@"[买单]"];
}

- (void)viewWillDisappear:(BOOL)animated {
    // 用户行为统计，页面停留时间
    [super viewWillDisappear:animated];
    [MobClick endLogPageView:@"[买单]"];
    
    _groupProduct.tickets = nil;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self initConfig];
    [self startValidCouponsRequest];
}

- (void)dealloc {
    [NOTIFICATION_CENTER removeObserver:self name:kWeiXinPaySuccessNotification object:nil];
    [NOTIFICATION_CENTER removeObserver:self name:kWeiXinPayFailureNotification object:nil];
}

#pragma mark - Init Methods
+ (instancetype)instance {
    return [SCStoryBoardManager viewControllerWithClass:self storyBoardName:SCStoryBoardNameOrderPay];
}

#pragma mark - Config Methods
- (void)initConfig {
    _tickets = @[].mutableCopy;
    _coupons = @[].mutableCopy;
    _payResult = [[SCPayOrderResult alloc] init];
    [_payResult setResultProductPrice:(_groupProduct ? _groupProduct.final_price.doubleValue : Zero)];
    
    [NOTIFICATION_CENTER addObserver:self selector:@selector(weiXinPaySuccess) name:kWeiXinPaySuccessNotification object:nil];
    [NOTIFICATION_CENTER addObserver:self selector:@selector(weiXinPayFailure) name:kWeiXinPayFailureNotification object:nil];
}

#pragma mark - Table View Data Source Methods
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return ( _orderDetail || _groupProduct) ? 3 : Zero;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if ( _orderDetail || _groupProduct) {
        switch (section) {
            case 0: {
                return (_tickets.count ? (_tickets.count + 1) : 1);
                break;
            }
            case 1: {
                return (_coupons.count ? (_coupons.count + 1) : 2);
                break;
            }
            case 2: {
                return 1;
                break;
            }
        }
    }
    return Zero;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = nil;
    if ( _orderDetail || _groupProduct) {
        switch (indexPath.section) {
            case 0: {
                if (_orderDetail) {
                    cell = [tableView dequeueReusableCellWithIdentifier:CLASS_NAME(SCPayOrderMerchandiseSummaryCell) forIndexPath:indexPath];
                    [(SCPayOrderMerchandiseSummaryCell *)cell displayCellWithDetail:_orderDetail];
                } else if (_groupProduct) {
                    if (!indexPath.row) {
                        cell = [tableView dequeueReusableCellWithIdentifier:CLASS_NAME(SCPayOrderGroupProductSummaryCell) forIndexPath:indexPath];
                        [(SCPayOrderGroupProductSummaryCell *)cell displayCellWithProduct:_groupProduct];
                    } else {
                        cell = [tableView dequeueReusableCellWithIdentifier:CLASS_NAME(SCPayOderTicketCell) forIndexPath:indexPath];
                        [(SCPayOderTicketCell *)cell displayCellWithTickets:_tickets index:(indexPath.row - 1)];
                    }
                }
                break;
            }
            case 1: {
                if (indexPath.row) {
                    if (_coupons.count) {
                        cell = [tableView dequeueReusableCellWithIdentifier:CLASS_NAME(SCPayOrderCouponCell) forIndexPath:indexPath];
                        [(SCPayOrderCouponCell *)cell displayCellWithCoupons:_coupons index:(indexPath.row - 1) couponCode:_payResult.couponCode];
                    } else {
                        cell = [tableView dequeueReusableCellWithIdentifier:CLASS_NAME(SCNoValidCouponCell) forIndexPath:indexPath];
                        [(SCNoValidCouponCell *)cell displayWithPriceConfirm:_payResult.priceConfirm];
                    }
                } else {
                    cell = [tableView dequeueReusableCellWithIdentifier:CLASS_NAME(SCPayOrderEnterCodeCell) forIndexPath:indexPath];
                    [(SCPayOrderEnterCodeCell *)cell displayCellWithPaySucceed:_payResult.canPay];
                }
                break;
            }
            case 2: {
                cell = [tableView dequeueReusableCellWithIdentifier:CLASS_NAME(SCPayOrderResultCell) forIndexPath:indexPath];
                [(SCPayOrderResultCell *)cell displayCellWithResult:_payResult];
            }
                break;
        }
    }
    return cell;
}

#pragma mark - Table View Delegate Methods
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    CGFloat height = 10.0f;
    if ( _orderDetail || _groupProduct) {
        switch (indexPath.section) {
            case 0: {
                if (_orderDetail) {
                    height += [tableView fd_heightForCellWithIdentifier:CLASS_NAME(SCPayOrderMerchandiseSummaryCell) cacheByIndexPath:indexPath configuration:^(SCPayOrderMerchandiseSummaryCell *cell) {
                        [cell displayCellWithDetail:_orderDetail];
                    }];
                } else if (_groupProduct) {
                    if (!indexPath.row) {
                        height += [tableView fd_heightForCellWithIdentifier:CLASS_NAME(SCPayOrderGroupProductSummaryCell) cacheByIndexPath:indexPath configuration:^(SCPayOrderGroupProductSummaryCell *cell) {
                            [cell displayCellWithProduct:_groupProduct];
                        }];
                    } else {
                        height = 44.0f;
                    }
                }
                break;
            }
            case 1: {
                if (indexPath.row) {
                    if (_coupons.count) {
                        height = [tableView fd_heightForCellWithIdentifier:CLASS_NAME(SCPayOrderCouponCell) cacheByIndexPath:indexPath configuration:^(SCPayOrderCouponCell *cell) {
                            [cell displayCellWithCoupons:_coupons index:(indexPath.row - 1) couponCode:_payResult.couponCode];
                        }];
                    } else {
                        height = 44.0f;
                    }
                }
                else {
                    height = 70.0f;
                }
                break;
            }
            case 2: {
                height += [tableView fd_heightForCellWithIdentifier:CLASS_NAME(SCPayOrderResultCell) cacheByIndexPath:indexPath configuration:^(SCPayOrderResultCell *cell) {
                    [cell displayCellWithResult:_payResult];
                }];
                break;
            }
        }
    }
    return height;
}

#pragma mark - Private Methods
- (void)startValidCouponsRequest {
    if (!_orderDetail.payPrice.doubleValue && _payResult.totalPrice.doubleValue) {
        WEAK_SELF(weakSelf);
        [self showHUDOnViewController:self.navigationController];
        // 配置请求参数
        NSDictionary *parameters = @{@"user_id": [SCUserInfo share].userID,
                                  @"company_id": (_orderDetail ? _orderDetail.companyID : (_groupProduct ? _groupProduct.company_id : @"")),
                                  @"reserve_id": (_orderDetail ? _orderDetail.reserveID : @""),
                                  @"product_id": (_groupProduct ? _groupProduct.product_id : @""),
                                       @"price": _payResult.totalPrice,
                              @"is_group_order": (_groupProduct ? @"Y" : @"N"),
                                 @"sort_method": @"amount"};
        [[SCAppApiRequest manager] startValidCouponsAPIRequestWithParameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
            [weakSelf hideHUDOnViewController:weakSelf.navigationController];
            if (operation.response.statusCode == SCApiRequestStatusCodeGETSuccess) {
                NSInteger statusCode    = [responseObject[@"status_code"] integerValue];
                NSString *statusMessage = responseObject[@"status_message"];
                switch (statusCode) {
                    case SCAppApiRequestErrorCodeNoError: {
                        [weakSelf handleCoupons:responseObject[@"data"]];
                        [weakSelf.tableView reloadData];
                    }
                        break;
                }
                if (statusMessage.length) {
                    [weakSelf showHUDAlertToViewController:weakSelf text:statusMessage];
                }
            }
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            [weakSelf hanleFailureResponseWtihOperation:operation];
            [weakSelf hideHUDOnViewController:weakSelf.navigationController];
        }];
    }
}

- (void)handleCoupons:(NSArray *)responseData {
    [_coupons removeAllObjects];
    __block SCCoupon *maxCoupon = nil;
    [responseData enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        SCCoupon *coupon = [SCCoupon objectWithKeyValues:obj];
        [_coupons addObject:coupon];
        if (coupon.amountMax.doubleValue > maxCoupon.amountMax.doubleValue) {
            maxCoupon = coupon;
        }
    }];
    maxCoupon.maxAmount = YES;
}

- (void)weiXinPayWithParameters:(NSDictionary *)parameters {
    if ([SCUserInfo share].loginState) {
        if ([WXApi isWXAppInstalled]) {
            WEAK_SELF(weakSelf);
            [self showHUDOnViewController:self.navigationController];
            if (_orderDetail) {
                [[SCAppApiRequest manager] startWeiXinPayOrderAPIRequestWithParameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
                    [weakSelf weiXinPayRequestSuccessWithOperation:operation];
                } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                    [weakSelf payFailureWithOperation:operation];
                }];
            } else if (_groupProduct) {
                [[SCAppApiRequest manager] startWeiXinOrderAPIRequestWithParameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
                    [weakSelf weiXinPayRequestSuccessWithOperation:operation];
                } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                    [weakSelf payFailureWithOperation:operation];
                }];
            }
        } else {
            [self showWeiXinInstallAlert];
        }
    } else {
        [self showShoulLoginAlert];
    }
}

- (void)aliPayWithParameters:(NSDictionary *)parameters {
    if ([SCUserInfo share].loginState) {
        WEAK_SELF(weakSelf);
        [self showHUDOnViewController:self.navigationController];
        if (_orderDetail) {
            [[SCAppApiRequest manager] startAliPayOrderAPIRequestWithParameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
                [weakSelf aliPayRequestSuccessWithOperation:operation];
            } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                [weakSelf payFailureWithOperation:operation];
            }];
        } else if (_groupProduct) {
            [[SCAppApiRequest manager] startAliOrderAPIRequestWithParameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
                [weakSelf aliPayRequestSuccessWithOperation:operation];
            } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                [weakSelf payFailureWithOperation:operation];
            }];
        }
    } else {
        [self showShoulLoginAlert];
    }
}

- (void)weiXinPayRequestSuccessWithOperation:(AFHTTPRequestOperation *)operation {
    id responseObject = operation.responseObject;
    if (operation.response.statusCode == SCApiRequestStatusCodePOSTSuccess) {
        NSInteger statusCode    = [responseObject[@"status_code"] integerValue];
        NSString *statusMessage = responseObject[@"status_message"];
        switch (statusCode) {
            case SCAppApiRequestErrorCodeNoError: {
                NSDictionary *data = responseObject[@"data"];
                BOOL zeroPay = [data[@"zero_pay"] boolValue];
                if (zeroPay) {
                    _payResult.outTradeNo = data[@"order_id"];
                    [self weiXinPaySuccess];
                } else {
                    [self sendWeiXinPay:[[SCWeiXinPayOrder alloc] initWithDictionary:data error:nil]];
                }
                break;
            }
        }
        if (statusMessage.length) {
            [self showHUDAlertToViewController:self text:statusMessage];
        }
    }
}

- (void)aliPayRequestSuccessWithOperation:(AFHTTPRequestOperation *)operation {
    id responseObject = operation.responseObject;
    if (operation.response.statusCode == SCApiRequestStatusCodePOSTSuccess) {
        NSInteger statusCode    = [responseObject[@"status_code"] integerValue];
        NSString *statusMessage = responseObject[@"status_message"];
        switch (statusCode) {
            case SCAppApiRequestErrorCodeNoError: {
                NSDictionary *data = responseObject[@"data"];
                BOOL zeroPay = [data[@"zero_pay"] boolValue];
                if (zeroPay) {
                    _payResult.outTradeNo = data[@"order_id"];
                    [self alipayResult:@{@"resultStatus": @(9000)}];
                } else {
                    [self sendAliPay:[[SCAliPayOrder alloc] initWithDictionary:data error:nil]];
                }
                break;
            }
        }
        if (statusMessage.length) {
            [self showHUDAlertToViewController:self text:statusMessage];
        }
    }
}

- (void)payFailureWithOperation:(AFHTTPRequestOperation *)operation {
    [self orderFailureWithMessage:operation.responseObject[@"message"]];
}

- (void)orderFailureWithMessage:(NSString *)message {
    [self showPromptWithText:message];
}

- (void)sendWeiXinPay:(SCWeiXinPayOrder *)order {
    _payResult.outTradeNo = order.outTradeNo;
    PayReq *request = [[PayReq alloc] init];
    request.partnerId = order.partnerid;
    request.prepayId  = order.prepayid;
    request.package   = order.package;
    request.nonceStr  = order.noncestr;
    request.timeStamp = (UInt32)order.timestamp;
    request.sign      = order.sign;
    [WXApi sendReq:request];
}

- (void)sendAliPay:(SCAliPayOrder *)order {
    WEAK_SELF(weakSelf);
    _payResult.outTradeNo = order.outTradeNo;
    [self hideHUDOnViewController:self.navigationController];
    [[AlipaySDK defaultService] payOrder:[order requestString] fromScheme:@"com.YJCL.XiuYang" callback:^(NSDictionary *resultDic) {
        [weakSelf alipayResult:resultDic];
    }];
}

- (void)weiXinPaySuccess {
    _payResult.canPay = NO;
    if (_orderDetail) {
        [self orderPaySuccess];
    } else if (_groupProduct) {
        [self groupProductPaySuccess];
    }
}

- (void)weiXinPayFailure {
    [self showPromptWithText:@"支付失败，请重试..."];
}

- (void)alipayResult:(NSDictionary *)reslut {
    SCAliPayCode code = [reslut[@"resultStatus"] integerValue];
    switch (code) {
        case SCAliPayCodePaySuccess: {
            _payResult.canPay = NO;
            if (_orderDetail) {
                [self orderPaySuccess];
            } else if (_groupProduct) {
                [self groupProductPaySuccess];
            }
            break;
        }
        case SCAliPayCodePayProcessing: {
            [self showPromptWithText:@"交易进行中"];
            break;
        }
        case SCAliPayCodePayFailure: {
            [self showPromptWithText:@"支付失败"];
            break;
        }
        case SCAliPayCodeUserCancel: {
            [self showPromptWithText:@"用户取消"];
            break;
        }
        case SCAliPayCodeNetworkError: {
            [self showPromptWithText:@"网络错误"];
            break;
        }
    }
}

- (void)restoreInitState {
    [_coupons removeAllObjects];
    [self.tableView reloadData];
    [self.tableView setContentOffset:CGPointMake(Zero, Zero)];
}

- (void)orderPaySuccess {
    _orderDetail.payPrice = _payResult.payPrice;
    [self restoreInitState];
    [self showPromptWithText:@"支付成功"];
    if (_delegate && [_delegate respondsToSelector:@selector(orderPaySucceed)])
        [_delegate orderPaySucceed];
}

- (void)groupProductPaySuccess {
    [self showPromptWithText:@"恭喜您团购成功！"];
    [self startOrderTikcetsReuqest];
}

- (void)showWeiXinInstallAlert {
    [self showAlertWithMessage:@"您的手机还没有安装微信，请先安装微信再使用微信支付，谢谢！"];
}

- (void)showPromptWithText:(NSString *)text {
    [self hideHUDOnViewController:self.navigationController];
    [self showHUDAlertToViewController:self.navigationController text:text delay:1.0f];
}

- (void)startOrderTikcetsReuqest {
    WEAK_SELF(weakSelf);
    [self showHUDOnViewController:self.navigationController];
    // 配置请求参数
    NSDictionary *parameters = @{@"user_id": [SCUserInfo share].userID,
                                @"order_id": _payResult.outTradeNo};
    [[SCAppApiRequest manager] startOrderTicketsAPIRequestWithParameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
        [weakSelf hideHUDOnViewController:weakSelf.navigationController];
        if (operation.response.statusCode == SCApiRequestStatusCodeGETSuccess) {
            NSInteger statusCode    = [responseObject[@"status_code"] integerValue];
            NSString *statusMessage = responseObject[@"status_message"];
            switch (statusCode) {
                case SCAppApiRequestErrorCodeNoError: {
                    [self restoreInitState];
                    [responseObject[@"data"] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                        SCGroupTicket *ticket = [SCGroupTicket objectWithKeyValues:obj];
                        [_tickets addObject:ticket];
                    }];
                    
                    _groupProduct.tickets = _tickets;
                    [weakSelf.tableView reloadData];
                    break;
                }
            }
            if (statusMessage.length) {
                [weakSelf showPromptWithText:statusMessage];
            }
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [weakSelf hanleFailureResponseWtihOperation:operation];
        [weakSelf hideHUDOnViewController:weakSelf.navigationController];
    }];
}

#pragma mark - SCPayOrderGroupProductSummaryCellDelegate Methods
- (void)didConfirmProductPrice:(CGFloat)price purchaseCount:(NSInteger)purchaseCount {
    [_payResult setPurchaseCount:purchaseCount];
    [_payResult setResultProductPrice:price];
    [self.tableView reloadData];
    [self startValidCouponsRequest];
}

#pragma mark - SCPayOrderMerchandiseSummaryCellDelegate Methods
- (void)didConfirmMerchantPrice:(CGFloat)price {
    if (price) {
        [_payResult setResultProductPrice:price];
        [self.tableView reloadData];
        [self startValidCouponsRequest];
    } else {
        [self showAlertWithMessage:@"请您输入正确价格！"];
    }
}

#pragma mark - SCPayOrderEnterCodeCellDelegate Methods
- (void)shouldEnterCouponCode {
    SCCouponsViewController *couponsViewController = [SCCouponsViewController instance];
    couponsViewController.delegate = self;
    couponsViewController.payEnter = YES;
    [self.navigationController pushViewController:couponsViewController animated:YES];
}

#pragma mark - SCPayOrderCouponCellDelegate
- (void)payOrderCouponCell:(SCPayOrderCouponCell *)cell {
    if (_payResult.canPay) {
        SCCoupon *coupon = _coupons[cell.tag];
        if (_payResult.coupon && [coupon.code isEqualToString:_payResult.couponCode]) {
            _payResult.coupon = nil;
        } else {
            _payResult.coupon = _coupons[cell.tag];
        }
        cell.checkBoxButton.selected = !cell.checkBoxButton.selected;
        [self.tableView reloadData];
    } else {
        cell.checkBoxButton.selected = NO;
    }
}

- (void)shouldAutoCheckCoupon:(SCCoupon *)coupon {
    _payResult.coupon = coupon;
    coupon.maxAmount = NO;
}

#pragma mark - SCPayOrderResultCellDelegate
- (void)shouldPayForOrderWithPayment:(SCPayOrderment)payment {
    if (_payResult.canPay && [_payResult.totalPrice doubleValue]) {
        SCUserInfo *userInfo = [SCUserInfo share];
        NSMutableDictionary *parameters = @{@"user_id": userInfo.userID,
                                             @"mobile": userInfo.phoneNmber,
                                        @"total_price": _payResult.payPrice,
                                          @"old_price": _payResult.totalPrice,
                                         @"use_coupon": _payResult.useCoupon,
                                        @"coupon_code": _payResult.couponCode}.mutableCopy;
        if (_orderDetail) {
            [parameters setValue:_orderDetail.companyID forKey:@"company_id"];
            [parameters setValue:_orderDetail.reserveID forKey:@"reserve_id"];
        } else if (_groupProduct) {
            [parameters setValue:_groupProduct.company_id forKey:@"company_id"];
            [parameters setValue:_groupProduct.product_id forKey:@"product_id"];
            [parameters setValue:@(_payResult.purchaseCount) forKey:@"how_many"];
        }
        
        switch (payment) {
            case SCPayOrdermentWeiXinPay: {
                [self weiXinPayWithParameters:parameters];
                break;
            }
            case SCPayOrdermentAliPay: {
                [self aliPayWithParameters:parameters];
                break;
            }
        }
    } else {
        [self showAlertWithMessage:@"请先确认您的购买总价是否正确！"];
    }
}

#pragma mark - SCCouponsViewControllerDelegate
- (void)userAddCouponSuccess {
    [self startValidCouponsRequest];
}

@end
