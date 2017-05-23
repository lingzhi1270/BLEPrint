//
//  ViewController.m
//  PrintDemo
//
//  Created by lingzhi on 2017/4/27.
//  Copyright © 2017年 lingzhi. All rights reserved.
//

#import "ViewController.h"

#import "SVProgressHUD.h"
#import "CustomBLECell.h"

#define SCREEN_WIDTH  [[UIScreen mainScreen] bounds].size.width
#define SCREEN_HEIGTH [[UIScreen mainScreen] bounds].size.height
#define MAX_CHARACTERISTIC_VALUE_SIZE 20

@interface ViewController ()<UITableViewDelegate,UITableViewDataSource>
{
    BOOL isSelected;
    BOOL isConnected;

}
@property (nonatomic,strong)UITableView *tableView;


@property (nonatomic,strong)NSMutableArray *blueToothArray;

@property (nonatomic,strong)NSMutableArray *peripheralArray;

@property (nonatomic,strong)NSMutableArray *connectedBLEArray;


@end

@implementation ViewController


//懒加载
- (UITableView *)tableView
{
    if (_tableView == nil) {
        _tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
        _tableView.delegate = self;
        _tableView.dataSource = self;
        [_tableView registerNib:[UINib nibWithNibName:@"CustomBLECell" bundle:[NSBundle mainBundle]] forCellReuseIdentifier:@"CustomBLECell"];
    }
    return _tableView;
}

- (NSMutableArray *)blueToothArray
{
    if (_blueToothArray == nil) {
        _blueToothArray = [[NSMutableArray alloc] initWithCapacity:0];
    }
    return _blueToothArray;
}

- (NSMutableArray *)peripheralArray
{
    if (_peripheralArray == nil) {
        _peripheralArray = [[NSMutableArray alloc] initWithCapacity:0];

    }
    return _peripheralArray;
}

- (NSMutableArray *)connectedBLEArray
{
    if (_connectedBLEArray == nil) {
        _connectedBLEArray = [[NSMutableArray alloc] initWithCapacity:0];
    }
    return _connectedBLEArray;
}



- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    //先断开所有连接设备
    [self.baby cancelAllPeripheralsConnection];
    [self.connectedBLEArray removeAllObjects];
    [self.blueToothArray removeAllObjects];
    [self.peripheralArray removeAllObjects];
    
   
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"打印" style:UIBarButtonItemStylePlain target:self action:@selector(printAction)];
    
    
    //实例化baby
    self.baby = [BabyBluetooth shareBabyBluetooth];
    //配置委托
    [self babyDelegate];
    //开始扫描
   self.baby.scanForPeripherals().begin();

   

}

- (void)viewDidLoad {
    [super viewDidLoad];
    isSelected = NO;
    isConnected = NO;
    [self.view addSubview:self.tableView];
    
   
}

- (void)printAction
{
    if (isConnected)
    {
        NSString *textString = @"测试打印-测试打印-测试打印-测试打印测试打印-测试打印-测试打印-测试打印-测试打印-测试打印-测试打印";
        if ([textString length]) {
            NSString *printed = [textString stringByAppendingFormat:@"%c%c%c%c",'\n','\n','\n','\n'];
            [self printerWithFormat:Align_Center CharZoom:Char_Normal content:printed];
        }
      }
    else
    {
        [SVProgressHUD showInfoWithStatus:@"未连接打印机"];
    }
    
}
#pragma mark - 打印

- (void)printerWithFormat:(Align_Type_e)eAlignType CharZoom:(Char_Zoom_Num_e)eCharZoomNum content:(NSString *)printContent
{
    NSData *data = nil;
    NSUInteger strLength;
    
    NSStringEncoding enc = CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingGB_18030_2000);
    
    Byte caPrintFmt[500];
    /*初始化命令：ESC @ 即0x1b,0x40*/
    //caPrintFmt[0] = 0x1b;
    //caPrintFmt[1] = 0x40;
    
    /*字符设置命令：ESC ! n即0x1b,0x21,n*/
    caPrintFmt[0] = 0x1d;
    caPrintFmt[1] = 0x21;
    
    caPrintFmt[2] = (eCharZoomNum<<4) | eCharZoomNum;
    
    caPrintFmt[3] = 0x1b;
    caPrintFmt[4] = 0x61;
    caPrintFmt[5] = eAlignType;
    
    
    NSData *printData = [printContent dataUsingEncoding:enc];
    Byte *printByte = (Byte *)[printData bytes];
    
    strLength = [printData length];
    if (strLength < 1) {
        return;
    }
    
    for (int i = 0; i<strLength; i++) {
        caPrintFmt[6+i] = *(printByte+i);
    }
    
    data = [NSData dataWithBytes:caPrintFmt length:6+strLength];
    
    [self printLongData:data];
}

- (void)printLongData:(NSData *)printContent
{
    NSUInteger i;
    NSUInteger strLength;
    NSUInteger cellCount;
    NSUInteger cellMin;
    NSUInteger cellLen;
    
    strLength = [printContent length];
    if (strLength<1) {
        return;
    }
    
    cellCount = (strLength%MAX_CHARACTERISTIC_VALUE_SIZE)?(strLength/MAX_CHARACTERISTIC_VALUE_SIZE +1):(strLength/MAX_CHARACTERISTIC_VALUE_SIZE);
    
    for (i=0; i<cellCount; i++) {
        cellMin = i*MAX_CHARACTERISTIC_VALUE_SIZE;
        if (cellMin + MAX_CHARACTERISTIC_VALUE_SIZE > strLength) {
            cellLen = strLength - cellMin;
        }
        else {
            cellLen = MAX_CHARACTERISTIC_VALUE_SIZE;
        }
        
        NSLog(@"print:总长-%lu,行数-%lu,前面的长度-%lu,当前行的长度-%lu",(unsigned long)strLength,(unsigned long)cellCount,(unsigned long)cellMin,(unsigned long)cellLen);
        
        // 截取当前行的打印内容
        NSRange range = NSMakeRange(cellMin, cellLen);
        NSData *subData = [printContent subdataWithRange:range];
        
        NSLog(@"当前打印内容:%@",subData);
        
        
        [self writeCharacteristic:self.connectedPeripheral characteristic:self.characteristic value:subData];
    }
}

-(void)writeCharacteristic:(CBPeripheral *)peripheral
            characteristic:(CBCharacteristic *)characteristic
                     value:(NSData *)value{
    
    NSLog(@"%lu", (unsigned long)characteristic.properties);
    
    
    //只有 characteristic.properties 有write的权限才可以写
    if(characteristic.properties & CBCharacteristicPropertyWrite){
        /*
         最好一个type参数可以为CBCharacteristicWriteWithResponse或type:CBCharacteristicWriteWithResponse,区别是是否会有反馈
         */
        [peripheral writeValue:value forCharacteristic:characteristic type:CBCharacteristicWriteWithoutResponse];
        
    
    }else{
        NSLog(@"该字段不可写！");
        [SVProgressHUD showErrorWithStatus:@"该字段不可写！"];
    }
    
    
}


//设置蓝牙委托
- (void)babyDelegate{
    
    __weak typeof(self) weakSelf = self;
    
    //检测center蓝牙状态
    [self.baby setBlockOnCentralManagerDidUpdateState:^(CBCentralManager *central) {
        if(central.state == CBCentralManagerStatePoweredOn)
        {
            [SVProgressHUD showInfoWithStatus:@"设备打开成功，开始扫描设备"];
        }
        else
        {
            [SVProgressHUD showInfoWithStatus:@"蓝牙未打开，请在手机设置-蓝牙-打开蓝牙中打开"];
        }
    }];

    //设置扫描到设备的委托
    [self.baby setBlockOnDiscoverToPeripherals:^(CBCentralManager *central, CBPeripheral *peripheral, NSDictionary *advertisementData, NSNumber *RSSI) {
        NSLog(@"搜索到外围设备:%@",peripheral.name);
    
        if(![weakSelf.blueToothArray containsObject:peripheral.name] && peripheral.name!=nil)
        {
            [weakSelf.blueToothArray addObject:peripheral.name];
            [weakSelf.peripheralArray addObject:peripheral];
            
            //刷新表
            [weakSelf.tableView reloadData];
        }
       
        
    }];
    

    //连接成功
    [self.baby setBlockOnConnected:^(CBCentralManager *central, CBPeripheral *peripheral) {
        
        [SVProgressHUD showInfoWithStatus:@"连接成功！"];
    
        
        [weakSelf.blueToothArray removeObject:peripheral.name];
        if (weakSelf.connectedBLEArray.count == 0 && peripheral.name) {
             [weakSelf.connectedBLEArray addObject:peripheral.name];
        }
       
        [weakSelf.tableView reloadData];
        isConnected = YES;
        
    }];
    
   //连接失败
    [self.baby setBlockOnFailToConnect:^(CBCentralManager *central, CBPeripheral *peripheral, NSError *error) {
        
        [SVProgressHUD showInfoWithStatus:@"连接失败"];
    }];
    
    
    //断开连接
    [self.baby setBlockOnCancelAllPeripheralsConnectionBlock:^(CBCentralManager *centralManager) {
        
    }];
    
    //设置发现设备的Services的委托
    [self.baby setBlockOnDiscoverServices:^(CBPeripheral *peripheral, NSError *error) {
        for (CBService *service in peripheral.services) {
            NSLog(@"搜索到服务:%@",service.UUID.UUIDString);
        }
    }];
       //设置发现设service的Characteristics的委托
        [self.baby setBlockOnDiscoverCharacteristics:^(CBPeripheral *peripheral, CBService *service, NSError *error) {
    
            for (CBCharacteristic *c in service.characteristics) {
                NSLog(@"特征之一：%@",c.UUID.UUIDString);
//                if ([c.UUID.UUIDString isEqualToString:@"49535343-1E4D-4BD9-BA61-23C647249616"]) {
//                    weakSelf.characteristic = c;
//                }
            
                                // 这是一个枚举类型的属性
                                CBCharacteristicProperties properties = c.properties;
                                if (properties & CBCharacteristicPropertyWrite) {
                                    
                                    //如果具备写入值不需要响应的特性
                                    //这里保存这个可以写的特性，便于后面往这个特性中写数据
                                    weakSelf.characteristic = c;
                           
                    
                                }
            }
        }];

    
    //设置读取characteristics的委托
    [self.baby setBlockOnReadValueForCharacteristic:^(CBPeripheral *peripheral, CBCharacteristic *characteristics, NSError *error) {
        NSLog(@"characteristic name:%@ value is:%@",characteristics.UUID,characteristics.value);
    }];
    //设置发现characteristics的descriptors的委托
    [self.baby setBlockOnDiscoverDescriptorsForCharacteristic:^(CBPeripheral *peripheral, CBCharacteristic *characteristic, NSError *error) {
        NSLog(@"===characteristic name:%@",characteristic.service.UUID);
        for (CBDescriptor *d in characteristic.descriptors) {
            NSLog(@"CBDescriptor name is :%@",d.UUID);
        }
    }];
    //设置读取Descriptor的委托
    [self.baby setBlockOnReadValueForDescriptors:^(CBPeripheral *peripheral, CBDescriptor *descriptor, NSError *error) {
        NSLog(@"Descriptor name:%@ value is:%@",descriptor.characteristic.UUID, descriptor.value);
    }];
    

}

- (void)cancelConnectedAction:(UIButton *)button
{
    isSelected = NO;
    
    CBPeripheral *periphral = (CBPeripheral *)self.peripheralArray[button.tag];
    //取消连接
    [self.baby cancelPeripheralConnection:periphral];
}


#pragma mark-
#pragma mark- UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == 0) {
        return self.connectedBLEArray.count;
    }
    else
    {
         return self.blueToothArray.count;
    }
}

- (nullable NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (section == 0) {
        NSString *string = @"已连接";
        return string;
    }
    else
    {
        NSString *string = @"发现设备";
        return string;
    }
    
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    CustomBLECell *cell = [_tableView dequeueReusableCellWithIdentifier:@"CustomBLECell"];
    
    if (indexPath.section == 0) {
       cell.NameLabel.text = [NSString stringWithFormat:@"%@",self.connectedBLEArray[indexPath.row]];
    }
    else
    {
        cell.NameLabel.text = [NSString stringWithFormat:@"%@",self.blueToothArray[indexPath.row]];
    }
    
    if (isSelected == NO) {
        [cell.cancelBtn setTitle:@"" forState:UIControlStateNormal];
        [cell.cancelBtn setTitleColor:[UIColor clearColor] forState:UIControlStateNormal];
    }
    else
    {
        cell.cancelBtn.tag = indexPath.row;
        [cell.cancelBtn setTitle:@"取消" forState:UIControlStateNormal];
        [cell.cancelBtn setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
        [cell.cancelBtn addTarget:self action:@selector(cancelConnectedAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    return cell;
}



#pragma mark-
#pragma mark- UITableViewDelegate
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}




- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 44.0;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    //停止扫描
    [self.baby cancelScan];

    //记录连接的设备
   self.connectedPeripheral = self.peripheralArray[indexPath.row];
    
    //连接设备
    if (self.connectedBLEArray.count == 0)
    {
        self.baby.having(self.connectedPeripheral).connectToPeripherals().discoverServices()
            .discoverCharacteristics().readValueForCharacteristic().discoverDescriptorsForCharacteristic()
            .readValueForDescriptors().begin();
    }
}


@end
