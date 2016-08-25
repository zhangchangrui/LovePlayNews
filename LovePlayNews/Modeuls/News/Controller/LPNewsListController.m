//
//  LPNewsListViewController.m
//  LovePlayNews
//
//  Created by tany on 16/8/3.
//  Copyright © 2016年 tany. All rights reserved.
//

#import "LPNewsListController.h"
#import "LPNewsInfoOperation.h"
#import "LPNewsCellNode.h"
#import "LPNewsImageCellNode.h"
#import "LPNewsDetailController.h"
#import "LPRefreshGifHeader.h"

@interface LPNewsListController ()<ASTableDelegate, ASTableDataSource>

// UI
@property (nonatomic, strong) ASTableNode *tableNode;

// Data
@property (nonatomic, strong) NSArray *newsList;

@property (nonatomic, assign) NSInteger curIndexPage;
@property (nonatomic, assign) BOOL haveMore;

@end

@implementation LPNewsListController


#pragma mark - life cycle

- (instancetype)init
{
    if (self = [super initWithNode:[ASDisplayNode new]]) {
        
        [self addTableNode];
    }
    return self;
}

- (void)addTableNode
{
    _tableNode = [[ASTableNode alloc] init];
    _tableNode.backgroundColor = [UIColor whiteColor];
    _tableNode.delegate = self;
    _tableNode.dataSource = self;
    [self.node addSubnode:_tableNode];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.navigationController.navigationBarHidden = YES;
}

- (void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
    _tableNode.frame = self.node.bounds;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    _tableNode.view.tableFooterView = [[UIView alloc]init];
    _tableNode.view.separatorStyle = UITableViewCellSeparatorStyleNone;
    
    [self addRefreshHeader];
}

- (void)addRefreshHeader
{
    LPRefreshGifHeader *header = [LPRefreshGifHeader headerWithRefreshingTarget:self refreshingAction:@selector(loadData)];
    _tableNode.view.mj_header = header;
    [header beginRefreshing];
}

#pragma mark - load Data

- (void)loadData
{
    [self loadMoreDataWithContext:nil];
}

- (void)loadMoreDataWithContext:(ASBatchContext *)context
{
    NSInteger curIndexPage = _curIndexPage;
    if (context) {
        [context beginBatchFetching];
    }else {
        curIndexPage = 0;
        _haveMore = YES;
    }
    
    LPHttpRequest *newsListRequest = [LPNewsInfoOperation requestNewsListWithTopId:_newsTopId pageIndex:curIndexPage];
    [newsListRequest loadWithSuccessBlock:^(LPHttpRequest *request) {
        NSArray *newsList = request.responseObject.data;
        if (context) {
            // 加载更多
            if (newsList.count > 0) {
                NSMutableArray *indexPaths = [NSMutableArray array];
                for (NSInteger row = _newsList.count; row<_newsList.count+newsList.count; ++row) {
                    [indexPaths addObject:[NSIndexPath indexPathForRow:row inSection:0]];
                }
                _newsList = [_newsList arrayByAddingObjectsFromArray:newsList];
                [_tableNode.view insertRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationNone];
                _curIndexPage++;
                _haveMore = YES;
            }else {
                _haveMore = NO;
            }
        }else {
            // 加载最新
            if (_newsList.count == 0) {
                _newsList = request.responseObject.data;
                [_tableNode.view reloadData];
                _curIndexPage++;
            }else {
                LPNewsInfoModel *infoModel = _newsList.firstObject;
                NSMutableArray *indexPaths = [NSMutableArray array];
                NSInteger index = 0;
                for (LPNewsInfoModel *newInfoModel in newsList) {
                    if ([newInfoModel.docid isEqualToString:infoModel.docid]) {
                        break;
                    }
                    [indexPaths addObject:[NSIndexPath indexPathForRow:index inSection:0]];
                    ++index;
                }
                
                if (indexPaths.count > 0) {
                    NSArray *newAddList = [newsList objectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, index)]];
                    _newsList = [newAddList arrayByAddingObjectsFromArray:_newsList];
                    [_tableNode.view insertRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationTop];
                }
            }
            _haveMore = YES;
        }
        
        if (context) {
            [context completeBatchFetching:YES];
        }else {
            [_tableNode.view.mj_header endRefreshing];
        }
    } failureBlock:^(id<TYRequestProtocol> request, NSError *error) {
        if (context) {
            [context completeBatchFetching:YES];
        }else {
            [_tableNode.view.mj_header endRefreshing];
        }
    }];
}

#pragma mark - ASTableDataSource

- (BOOL)shouldBatchFetchForTableView:(ASTableView *)tableView
{
    return _newsList.count && _haveMore;
}

- (void)tableView:(ASTableView *)tableView willBeginBatchFetchWithContext:(ASBatchContext *)context
{
    [self loadMoreDataWithContext:context];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _newsList.count;
}

- (ASCellNodeBlock)tableView:(ASTableView *)tableView nodeBlockForRowAtIndexPath:(NSIndexPath *)indexPath
{
    LPNewsInfoModel *newsInfo = _newsList[indexPath.row];
    ASCellNode *(^cellNodeBlock)() = ^ASCellNode *() {
        LPNewsBaseCellNode *cellNode = nil;
        switch (newsInfo.showType) {
            case 2:
                cellNode = [[LPNewsImageCellNode alloc] initWithNewsInfo:newsInfo];
                break;
            default:
                cellNode = [[LPNewsCellNode alloc] initWithNewsInfo:newsInfo];
                break;
        }
        return cellNode;
    };
    return cellNodeBlock;
}

#pragma mark - ASTableDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    LPNewsInfoModel *newsInfo = _newsList[indexPath.row];
    LPNewsDetailController *detail = [[LPNewsDetailController alloc]init];
    detail.newsId = newsInfo.docid;
    [self.navigationController pushViewController:detail animated:YES];
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
