//
//  SCUserViewController.m
//  MaintenanceCar
//
//  Created by ShiCang on 14/12/19.
//  Copyright (c) 2014年 MaintenanceCar. All rights reserved.
//

#import "SCUserViewController.h"
#import <UMengAnalytics/MobClick.h>
#import "MicroCommon.h"
#import "SCUserInfo.h"
#import "SCLoginViewController.h"
#import "SCMyFavoriteTableViewController.h"
#import "SCMyReservationTableViewController.h"
#import "SCAddCarViewController.h"

typedef NS_ENUM(NSInteger, SCUserCenterRow) {
    SCUserCenterRowMyOrder = 0,
    SCUserCenterRowMyCollection,
    SCUserCenterRowMyCustomers,
    SCUserCenterRowMyReservation,
};

@interface SCUserViewController () <UIAlertViewDelegate, SCAddCarViewControllerDelegate>

@end

@implementation SCUserViewController

#pragma mark - View Controller Life Cycle
- (void)viewWillAppear:(BOOL)animated
{
    // 用户行为统计，页面停留时间
    [super viewWillAppear:animated];
    [MobClick beginLogPageView:@"[我] - 个人中心"];
}

- (void)viewWillDisappear:(BOOL)animated
{
    // 用户行为统计，页面停留时间
    [super viewWillDisappear:animated];
    [MobClick endLogPageView:@"[我] - 个人中心"];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table View Delegate Methods
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    // 检查用户是否登陆，在进行相应页面跳转
    if ([SCUserInfo share].loginStatus)
    {
        @try {
            switch (indexPath.row)
            {
                case SCUserCenterRowMyOrder:
                {
                    SCMyReservationTableViewController *myReservationTableViewController = [STORY_BOARD(@"Main") instantiateViewControllerWithIdentifier:@"SCMyReservationTableViewController"];
                    [self pushToSubViewControllerWithController:myReservationTableViewController];
                }
                    break;
                case SCUserCenterRowMyCollection:
                {
                    SCMyFavoriteTableViewController *myFavoriteTableViewController = [STORY_BOARD(@"Main") instantiateViewControllerWithIdentifier:@"SCMyFavoriteTableViewController"];
                    [self pushToSubViewControllerWithController:myFavoriteTableViewController];
                }
                    break;
                    
                default:
                    break;
            }
        }
        @catch (NSException *exception) {
            NSLog(@"User Center Push Controller Error:%@", exception.reason);
        }
        @finally {
        }
    }
    else
        [self showShoulLoginAlert];
}

#pragma mark - Button Action Methods
- (IBAction)loginButtonPressed:(UIButton *)sender
{
//    [self checkShouldLogin];
    [SCUserInfo logout];
}

#pragma mark - Private Methods
- (void)viewConfig
{
}

/**
 *  Push到一个页面，带动画
 *
 *  @param viewController 需要Push到的页面
 */
- (void)pushToSubViewControllerWithController:(UIViewController *)viewController
{
    [self.navigationController pushViewController:viewController animated:YES];
}

/**
 *  检查用户是否需要登陆，需要则跳转到登陆页面
 */
- (void)checkShouldLogin
{
    if (![SCUserInfo share].loginStatus)
    {
        [NOTIFICATION_CENTER postNotificationName:kUserNeedLoginNotification object:nil];
    }
}

/**
 *  提示用户登陆的警告框
 */
- (void)showShoulLoginAlert
{
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"您还没有登陆"
                                                        message:nil
                                                       delegate:self
                                              cancelButtonTitle:@"取消"
                                              otherButtonTitles:@"登陆", nil];
    [alertView show];
}

#pragma mark - Alert View Delegate Methods
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    // 用户选择是否登陆
    if (buttonIndex != alertView.cancelButtonIndex)
    {
        [self checkShouldLogin];
    }
}

// [添加车辆]按钮被点击，跳转到添加车辆页面
- (IBAction)addCarItemPressed:(UIBarButtonItem *)sender
{
    if ([SCUserInfo share].loginStatus)
    {
        @try {
            UINavigationController *addCarViewNavigationControler = [STORY_BOARD(@"Main") instantiateViewControllerWithIdentifier:@"SCAddCarViewNavigationController"];
            SCAddCarViewController *addCarViewController = (SCAddCarViewController *)addCarViewNavigationControler.topViewController;
            addCarViewController.delegate = self;
            [self presentViewController:addCarViewNavigationControler animated:YES completion:nil];
        }
        @catch (NSException *exception) {
            NSLog(@"SCMyReservationTableViewController Go to the SCAddCarViewNavigationControler exception reasion:%@", exception.reason);
        }
        @finally {
        }
    }
    else
        [self showShoulLoginAlert];
}

#pragma mark - SCAddCarViewController Delegate Methods
- (void)addCarSuccessWith:(NSString *)userCarID
{
    // 车辆添加成功的回调方法，车辆添加成功以后需要刷新个人中心，展示出用户最新添加的车辆
    [[SCUserInfo share] userCarsReuqest:nil];
}

@end
