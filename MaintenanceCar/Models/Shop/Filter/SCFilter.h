//
//  SCFilter.h
//  MaintenanceCar
//
//  Created by ShiCang on 15/6/26.
//  Copyright (c) 2015年 MaintenanceCar. All rights reserved.
//

#import <MJExtension/MJExtension.h>

@interface SCFilterCategoryItem : NSObject

@property (nonatomic, copy)  NSString *title;
@property (nonatomic, copy)  NSString *filterTitle;
@property (nonatomic, copy)  NSString *program;
@property (nonatomic, copy)  NSString *value;
@property (nonatomic, strong) NSArray *subItems;

@end

@interface SCFilterCategory : NSObject

@property (nonatomic, assign)      BOOL  haveSubItems;
@property (nonatomic, assign) NSInteger  selectedIndex;
@property (nonatomic, assign) NSInteger  maxCount;
@property (nonatomic, copy)   NSString *program;
@property (nonatomic, copy)   NSString *value;
@property (nonatomic, strong)  NSArray *items;

@end

@interface SCCarModelFilterCategory : SCFilterCategory

@property (nonatomic, assign)  double  myCarsViewHeight;
@property (nonatomic, assign)  double  otherCarsViewHeight;
@property (nonatomic, strong) NSArray *myCars;
@property (nonatomic, strong) NSArray *otherCars;

@end

@interface SCFilter : NSObject

@property (nonatomic, strong) SCFilterCategory         *serviceCategory;
@property (nonatomic, strong) SCFilterCategory         *regionCategory;
@property (nonatomic, strong) SCFilterCategory         *sortCategory;
@property (nonatomic, strong) SCCarModelFilterCategory *carModelCategory;

@end
