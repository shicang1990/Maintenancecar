//
//  SCServiceItem.h
//  MaintenanceCar
//
//  Created by ShiCang on 15/1/22.
//  Copyright (c) 2015年 MaintenanceCar. All rights reserved.
//

#import "JSONModel.h"

@interface SCServiceItem : JSONModel

@property (nonatomic, strong) NSString <Optional>*service_id;     // 服务项目ID
@property (nonatomic, strong) NSString <Optional>*service_name;   // 服务项目名字
@property (nonatomic, strong) NSString <Optional>*memo;           // 可选字段

- (instancetype)initWithServiceID:(NSString *)serviceID;
- (instancetype)initWithServiceID:(NSString *)serviceID serviceName:(NSString *)serviceName;

@end
