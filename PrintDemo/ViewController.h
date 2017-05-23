//
//  ViewController.h
//  PrintDemo
//
//  Created by lingzhi on 2017/4/27.
//  Copyright © 2017年 lingzhi. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BabyBluetooth.h"

typedef enum : NSUInteger {
    Align_Left = 0x00,
    Align_Center,
    Align_Right
} Align_Type_e;

typedef enum : NSUInteger {
    Char_Normal = 0x00,
    Char_Zoom_2,
    Char_Zoom_3,
    Char_Zoom_4
} Char_Zoom_Num_e;

@interface ViewController : UIViewController

@property (nonatomic,strong) BabyBluetooth *baby;

 //保存连接的设备和特征
@property (nonatomic,strong)CBPeripheral *connectedPeripheral;

@property (nonatomic,strong)CBCharacteristic *characteristic;

@end

