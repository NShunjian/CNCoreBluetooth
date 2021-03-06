//
//  OpenhistoryVC.m
//  CNCoreBluetooth
//
//  Created by apple on 2018/2/7.
//  Copyright © 2018年 apple. All rights reserved.
//

#import "OpenhistoryVC.h"
#import "OpenHistoryCell.h"
#import "CNBlueCommunication.h"
#import "CNBlueManager.h"
#import "CNDataBase.h"
#import "BlueHelp.h"

@interface OpenhistoryVC ()<UITableViewDelegate,UITableViewDataSource>{
    NSMutableArray *dataArray;
    BOOL isupdate;
}

@end

@implementation OpenhistoryVC

-(void)viewWillDisappear:(BOOL)animated{
    [super viewDidDisappear:animated];
    [self setBackBtnHiden:YES];
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [self setBackBtnHiden:NO];
}

-(void)rotate{
    if ([CommonData deviceIsIpad]) {
        UIButton *leftBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [leftBtn setImage:[UIImage imageNamed:@"back"] forState:UIControlStateNormal];
        if (SCREENWIDTH>SCREENHEIGHT) {
            leftBtn.contentEdgeInsets = UIEdgeInsetsMake(0, edgeDistancePage*2/3.0+5, 0, 0);
        }else{
            leftBtn.contentEdgeInsets = UIEdgeInsetsMake(0, edgeDistancePage*2/3.0, 0, 0);
        }
        [leftBtn addTarget:self action:@selector(back) forControlEvents:UIControlEventTouchUpInside];
        UIBarButtonItem *leftItem = [[UIBarButtonItem alloc] initWithCustomView:leftBtn];
        self.navigationItem.leftBarButtonItem = leftItem;
    }
}

- (void)back{
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    isupdate = YES;

    dataArray = [NSMutableArray array];
    if ([CommonData deviceIsIpad]) {
        UIButton *leftBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [leftBtn setImage:[UIImage imageNamed:@"back"] forState:UIControlStateNormal];
        if (SCREENWIDTH>SCREENHEIGHT) {
            leftBtn.contentEdgeInsets = UIEdgeInsetsMake(0, edgeDistancePage*2/3.0+5, 0, 0);
        }else{
            leftBtn.contentEdgeInsets = UIEdgeInsetsMake(0, edgeDistancePage*2/3.0, 0, 0);
        }
        [leftBtn addTarget:self action:@selector(back) forControlEvents:UIControlEventTouchUpInside];
        UIBarButtonItem *leftItem = [[UIBarButtonItem alloc] initWithCustomView:leftBtn];
        self.navigationItem.leftBarButtonItem = leftItem;
    }
    self.headView.hidden = NO;
    self.headLable.text = @"OPEN HISTORY";
    
    [_myTableView registerNib:[UINib nibWithNibName:@"OpenHistoryCell" bundle:nil] forCellReuseIdentifier:@"OpenHistoryCell"];
    _myTableView.tableFooterView = [[UIView alloc] init];
    
    NSArray *array = [[CNDataBase sharedDataBase] queryOpenLockLog:_lockID];
    [dataArray addObjectsFromArray:array];
    NSString *lastTime = [[CNDataBase sharedDataBase] getLastOpenLockDate:_lockID];
    for (CBPeripheral *peri in [CNBlueManager sharedBlueManager].connectedPeripheralArray) {
        if ([peri.identifier.UUIDString isEqualToString:_lockID]) {
            [CNBlueCommunication cbSendInstruction:ENLookLockLog toPeripheral:peri otherParameter:lastTime finish:^(RespondModel *model) {
                if ([model.state intValue] == 1) {
                    for (RespondModel *myModel in dataArray) {
                        if ([myModel.date isEqualToString:model.date]) {
                            return ;
                        }
                    }
                    model.lockIdentifier = _lockID;
                    [dataArray insertObject:model atIndex:0];
                    [[CNDataBase sharedDataBase] addLog:model];
                    [dataArray sortUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
                        RespondModel *ojg11 = (RespondModel *)obj1;
                        RespondModel *ojg22 = (RespondModel *)obj2;
                        if ([ojg11.date compare:ojg22.date] == NSOrderedAscending) {
                            return NSOrderedDescending;
                        }else{
                            return NSOrderedAscending;
                        }
                    }];
                    
                    [self.myTableView reloadData];
                    
                    if (isupdate) {
                        [[CNDataBase sharedDataBase] updateLockLogQueryTime:_lockID];
                        isupdate = NO;
                    }
                    
                }else{
                    //查询完毕
                    //[model.state intValue] == 0
                }
            }];
            break;
        }
    }
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return dataArray.count;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 60;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    OpenHistoryCell *cell = [tableView dequeueReusableCellWithIdentifier:@"OpenHistoryCell" forIndexPath:indexPath];
    RespondModel *model = dataArray[indexPath.row];
    NSDictionary *dic = [BlueHelp getFormatTime:model.date];
    cell.timeLab.text = [dic objectForKey:@"time"];
    cell.dateLab.text = [dic objectForKey:@"date"];
    cell.macAddress.text = [BlueHelp getFormatAddress:model.IDAddress];
    if (model.lockMethod == ENRFIDMethod) {
        cell.openMethod.text = @"RFID";
    }else if (model.lockMethod == ENTouchMethod){
        cell.openMethod.text = @"Touch";
    }else{
        cell.openMethod.text = @"APP";
    }
    return cell;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
