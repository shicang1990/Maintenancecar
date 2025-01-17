//
//  SCAddCarViewController.h
//  MaintenanceCar
//
//  Created by ShiCang on 15/1/11.
//  Copyright (c) 2015年 MaintenanceCar. All rights reserved.
//

#import "SCViewControllerCategory.h"
#import "SCCar.h"

@class SCCarBrandView;
@class SCCarModelView;

@protocol SCAddCarViewControllerDelegate <NSObject>

@optional
- (void)addCarSuccess:(SCCar *)car;

@end

@interface SCAddCarViewController : UIViewController

@property (nonatomic, weak) id  <SCAddCarViewControllerDelegate>delegate;

@property (weak, nonatomic) IBOutlet SCCarBrandView *carBrandView;      // 车辆品牌View
@property (weak, nonatomic) IBOutlet SCCarModelView *carModelView;      // 车辆车型View

// [添加车辆]按钮触发事件
- (IBAction)addCarItemPressed;
// [取消添加]按钮触发事件
- (IBAction)cancelItemPressed;

+ (UINavigationController *)navigationInstance;

@end
