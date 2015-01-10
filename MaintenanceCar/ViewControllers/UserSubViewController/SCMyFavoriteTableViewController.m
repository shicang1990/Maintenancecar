//
//  SCMyFavoriteTableViewController.m
//  MaintenanceCar
//
//  Created by ShiCang on 15/1/5.
//  Copyright (c) 2015年 MaintenanceCar. All rights reserved.
//

#import "SCMyFavoriteTableViewController.h"
#import "MicroCommon.h"
#import "SCAPIRequest.h"
#import "SCUserInfo.h"
#import "SCMerchant.h"
#import "SCMerchantTableViewCell.h"
#import "SCMerchantDetailViewController.h"

@interface SCMyFavoriteTableViewController ()

@end

@implementation SCMyFavoriteTableViewController

#pragma mark - View Controller Life Cycle
- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table View Data Source Methods
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _dataList.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    SCMerchantTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:MerchantCellReuseIdentifier forIndexPath:indexPath];
    
    // 刷新商户列表
    SCMerchant *merchant = _dataList[indexPath.row];
    cell.merchantNameLabel.text = merchant.name;
    cell.distanceLabel.text = merchant.distance;
    cell.reservationButton.tag = indexPath.row;
    
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete)
    {
        _deleteDataCache = _dataList[indexPath.row];
        [_dataList removeObjectAtIndex:indexPath.row];
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
        [self startCancelCollectionMerchantRequestWithIndex:indexPath.row];
    }
}

#pragma mark - Table View Delegate Methods
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // 跳转到预约页面
    @try {
        SCMerchantDetailViewController *merchantDetialViewControler = [STORY_BOARD(@"Main") instantiateViewControllerWithIdentifier:MerchantDetailViewControllerStoryBoardID];
        merchantDetialViewControler.companyID = ((SCMerchant *)_dataList[indexPath.row]).company_id;
        [self.navigationController pushViewController:merchantDetialViewControler animated:YES];
    }
    @catch (NSException *exception) {
        SCException(@"SCMyFavoriteTableViewController Go to the SCMerchantDetailViewController exception reasion:%@", exception.reason);
    }
    @finally {
    }
}

#pragma mark - Private Methods
- (void)startDownRefreshReuqest
{
    [super startDownRefreshReuqest];
    
    self.offset = Zero;
    self.requestType = SCFavoriteListRequestTypeDown;
    [self startMerchantCollectionListRequest];
}

- (void)startUpRefreshRequest
{
    [super startUpRefreshRequest];
    
    self.requestType = SCFavoriteListRequestTypeUp;
    [self startMerchantCollectionListRequest];
}

#pragma mark - Private Methods
/**
 *  收藏列表数据请求方法，必选参数：user_id，limit，offset
 */
- (void)startMerchantCollectionListRequest
{
    __weak typeof(self) weakSelf = self;
    // 配置请求参数
    NSDictionary *parameters = @{@"user_id": [SCUserInfo share].userID,
                                 @"limit"  : @(MerchantListLimit),
                                 @"offset" : @(self.offset)};
    [[SCAPIRequest manager] startGetCollectionMerchantAPIRequestWithParameters:parameters Success:^(AFHTTPRequestOperation *operation, id responseObject) {
        // 关闭上拉刷新或者下拉刷新
        [weakSelf.tableView headerEndRefreshing];
        [weakSelf.tableView footerEndRefreshing];
        if (operation.response.statusCode == SCAPIRequestStatusCodeGETSuccess)
        {
            // 如果是下拉刷新数据，先清空列表，在做数据处理
            if (weakSelf.requestType == SCFavoriteListRequestTypeDown)
            {
                [weakSelf clearListData];
            }
            
            SCLog(@"Collection Merchent List Request Data:%@", responseObject);
            // 遍历请求回来的商户数据，生成SCMerchant用于商户列表显示
            [responseObject enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                NSError *error       = nil;
                SCMerchant *merchant = [[SCMerchant alloc] initWithDictionary:obj error:&error];
                SCFailure(@"weather model parse error:%@", error);
                [_dataList addObject:merchant];
            }];
            
            [MBProgressHUD hideHUDForView:weakSelf.navigationController.view animated:YES];             // 请求完成，移除响应式控件
            
            [weakSelf.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:weakSelf.offset ? UITableViewRowAnimationTop : UITableViewRowAnimationFade];                                                           // 数据配置完成，刷新商户列表
            weakSelf.offset += MerchantListLimit;                                                       // 偏移量请求参数递增
        }
        else
        {
            [MBProgressHUD hideHUDForView:weakSelf.navigationController.view animated:YES];
            SCFailure(@"status code error:%@", [NSHTTPURLResponse localizedStringForStatusCode:operation.response.statusCode]);
            ShowPromptHUDWithText(weakSelf.navigationController.view, responseObject[@"error"], 1.0f);
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        SCFailure(@"Get merchant list request error:%@", error);
        // 关闭上拉刷新或者下拉刷新
        [weakSelf.tableView headerEndRefreshing];
        [weakSelf.tableView footerEndRefreshing];
        [MBProgressHUD hideHUDForView:weakSelf.navigationController.view animated:YES];
        ShowPromptHUDWithText(weakSelf.navigationController.view, @"网络错误，请重试！", 1.0f);
    }];
}

/**
 *  取消收藏商户请求方法，必选参数：company_id，user_id
 */
- (void)startCancelCollectionMerchantRequestWithIndex:(NSInteger)index
{
    __weak typeof(self) weakSelf = self;
    NSDictionary *paramters = @{@"company_id": ((SCMerchant *)_deleteDataCache).company_id,
                                   @"user_id": [SCUserInfo share].userID};
    [[SCAPIRequest manager] startCancelCollectionAPIRequestWithParameters:paramters Success:^(AFHTTPRequestOperation *operation, id responseObject) {
        // 根据返回结果进行相应提示
        if (operation.response.statusCode == SCAPIRequestStatusCodeGETSuccess)
        {
            ShowPromptHUDWithText(weakSelf.navigationController.view, @"删除成功", 1.0f);
        }
        else
        {
            [weakSelf deleteFailureAtIndex:index];
            ShowPromptHUDWithText(weakSelf.navigationController.view, @"删除失败，请重试", 1.0f);
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [weakSelf deleteFailureAtIndex:index];
        ShowPromptHUDWithText(weakSelf.navigationController.view, @"删除失败，请检查网络", 1.0f);
    }];
}

@end
