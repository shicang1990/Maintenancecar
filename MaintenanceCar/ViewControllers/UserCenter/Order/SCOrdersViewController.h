//
//  SCOrdersViewController.h
//  MaintenanceCar
//
//  Created by ShiCang on 15/4/20.
//  Copyright (c) 2015年 MaintenanceCar. All rights reserved.
//

#import "SCNavigationTableViewController.h"

typedef NS_ENUM(NSInteger, SCOrdersReuqest) {
    SCOrdersReuqestProgress,
    SCOrdersReuqestFinished
};

@protocol SCOrdersViewControllerDelegate <NSObject>

@optional
- (void)shouldShowMenu;
- (void)shouldSupportPanGesture:(BOOL)support;

@end

@class SCOrder;
@class SCOrderCell;

@interface SCOrdersViewController : SCNavigationTableViewController <UITableViewDataSource, UITableViewDelegate> {
    SCOrder         *_order;
    SCOrderCell     *_orderCell;
    SCOrdersReuqest  _ordersRequest;
    
    NSInteger        _progressOffset;
    NSInteger        _finishedOffset;
    NSMutableArray  *_progressDataList;
    NSMutableArray  *_finishedDateList;
}

@property (weak, nonatomic) IBOutlet  UIView *promptView;
@property (weak, nonatomic) IBOutlet UILabel *promptLabel;

@property (nonatomic, weak) id  <SCOrdersViewControllerDelegate>delegate;

- (IBAction)menuButtonPressed;

+ (UINavigationController *)navigationInstance;
+ (instancetype)instance;

@end
