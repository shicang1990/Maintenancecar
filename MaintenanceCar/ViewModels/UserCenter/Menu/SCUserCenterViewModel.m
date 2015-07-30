//
//  SCUserCenterViewModel.m
//  MaintenanceCar
//
//  Created by Andy on 15/7/23.
//  Copyright (c) 2015年 MaintenanceCar. All rights reserved.
//

#import "SCUserCenterViewModel.h"
#import "SCFileManager.h"
#import "SCUserInfo.h"

static NSString *Prompt = @"请登录";
static NSString *AddCarPrompt = @"点击添加车辆";

static NSString *UserCenterItemsFileName = @"UserCenterData";
static NSString *UserCenterItemsFileType = @"plist";

static NSString *PlaceHolderHeaderImageName = @"UC-HeaderIcon";
static NSString *AddCarIconImageName = @"UC-AddCarIcon";

static NSString *AddCarIconKey = @"Icon";
static NSString *AddCarIconValue = @"Title";


@implementation SCUserCenterViewModel

#pragma mark - Init Methods
+ (instancetype)instance {
    SCUserCenterViewModel *model = [[SCUserCenterViewModel alloc] init];
    return model;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        [self initConfig];
    }
    return self;
}

#pragma mark - Config Methods
- (void)initConfig {
    _placeHolderHeader = PlaceHolderHeaderImageName;
    [self reloadCars];
    NSMutableArray *items = @[].mutableCopy;
    NSArray *userCenterItems = [self loadUserCenterItems];
    for (NSDictionary *dic in userCenterItems) {
        SCUserCenterMenuItem *item = [[SCUserCenterMenuItem alloc] initWithDictionary:dic localData:YES];
        [items addObject:item];
    }
    _userCenterItems = [NSArray arrayWithArray:items];
}

#pragma mark - Setter And Getter
- (NSString *)prompt {
    SCUserInfo *userInfo = [SCUserInfo share];
    return userInfo.loginState ? userInfo.phoneNmber : Prompt;
}

#pragma mark - Public Methods
- (void)reloadCars {
    __weak __typeof(self)weakSelf = self;
    [[SCUserInfo share] userCarsReuqest:^(SCUserInfo *userInfo, BOOL finish) {
        NSArray *cars = userInfo.cars;
        NSMutableArray *items = @[].mutableCopy;
        for (SCUserCar *car in cars) {
            SCUserCenterMenuItem *item = [[SCUserCenterMenuItem alloc] initWithCar:car];
            [items addObject:item];
        }
        _userCarItems = [weakSelf appendAddCarItem:items];
        weakSelf.needRefresh = YES;
    }];
    
}

#pragma mark - Private Methods
- (NSArray *)loadUserCenterItems {
    return [NSArray arrayWithContentsOfFile:[NSFileManager pathForResource:UserCenterItemsFileName ofType:UserCenterItemsFileType]];
}

- (NSArray *)appendAddCarItem:(NSMutableArray *)items {
    if ([SCUserInfo share].loginState) {
        SCUserCenterMenuItem *item = [[SCUserCenterMenuItem alloc] initWithDictionary:@{AddCarIconKey: AddCarIconImageName, AddCarIconValue: AddCarPrompt}
                                                                            localData:YES];
        item.last = YES;
        [items addObject:item];
    } else {
        [items enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            SCUserCenterMenuItem *item = obj;
            if ([item.icon isEqualToString:AddCarIconImageName]) {
                [items removeObject:item];
                return;
            }
        }];
    }
    return [NSArray arrayWithArray:items];
}

@end