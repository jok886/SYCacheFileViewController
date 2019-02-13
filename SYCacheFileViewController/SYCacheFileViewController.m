//
//  SYCacheFileViewController.m
//  zhangshaoyu
//
//  Created by zhangshaoyu on 17/6/27.
//  Copyright © 2017年 zhangshaoyu. All rights reserved.
//

#import "SYCacheFileViewController.h"
#import "SYCacheFileTable.h"
#import "SYCacheFileManager.h"
#import "SYCacheFileModel.h"
#import "SYCacheFileRead.h"

@interface SYCacheFileViewController ()

@property (nonatomic, strong) SYCacheFileTable *cacheTable;
@property (nonatomic, strong) SYCacheFileRead *fileRead;

@end

@implementation SYCacheFileViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.navigationItem.title = (_cacheTitle ? _cacheTitle : SYCacheFileTitle);
    
    [self setUI];
    [self loadData];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)loadView
{
    [super loadView];
    self.view.backgroundColor = [UIColor colorWithWhite:0.5 alpha:0.1];
    if ([self respondsToSelector:@selector(setEdgesForExtendedLayout:)]) {
        self.edgesForExtendedLayout = UIRectEdgeNone;
    }
}

- (void)dealloc
{
    NSLog(@"<--- %@ 被释放了 --->", [self class]);
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    if (self.fileRead) {
        [self.fileRead releaseSYCacheFileRead];
    }
}

#pragma mark - 视图

- (void)setUI
{
    typeof(self) __weak weakSelf = self;
    
    [self.view addSubview:self.cacheTable];
    self.cacheTable.frame = self.view.bounds;
    
    // 点击
    self.cacheTable.itemClick = ^(NSIndexPath *indexPath) {
        
        if (weakSelf.cacheTable.isEditing) {
            return ;
        }
        
        if (indexPath.row > weakSelf.cacheArray.count - 1) {
            return;
        }
        SYCacheFileModel *model = weakSelf.cacheArray[indexPath.row];
        NSString *path = model.filePath; // 路径
        SYCacheFileType type = model.fileType; // 类型
        if (SYCacheFileTypeUnknow == type) {
            // 标题
            NSString *title = model.fileName;
            // 子目录文件
            NSArray *files = [[SYCacheFileManager shareManager] fileModelsWithFilePath:path];
            SYCacheFileViewController *cacheVC = [SYCacheFileViewController new];
            cacheVC.cacheTitle = title;
            cacheVC.cacheArray = (NSMutableArray *)files;
            [weakSelf.navigationController pushViewController:cacheVC animated:YES];
        } else {
            if (type == SYCacheFileTypeImage) {
                [SYCacheFileManager shareManager].indexImage = indexPath.row;
            }
            [weakSelf.fileRead fileReadWithFilePath:path target:weakSelf];
        }
    };
    // 长按
    self.cacheTable.longPress = ^(SYCacheFileTable *tableView, NSIndexPath *indexPath) {
        if (indexPath.row > weakSelf.cacheArray.count - 1) {
            return;
        }
        //
        SYCacheFileModel *model = weakSelf.cacheArray[indexPath.row];
        SYCacheFileType type = model.fileType;
        //
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:NULL];
        [alertController addAction:cancelAction];
        if (type == SYCacheFileTypeVideo || type == SYCacheFileTypeImage) {
            UIAlertAction *cacheAction = [UIAlertAction actionWithTitle:@"保存到相册" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                if (type == SYCacheFileTypeVideo) {
                    UISaveVideoAtPathToSavedPhotosAlbum(model.filePath, weakSelf, @selector(video:didFinishSavingWithError: contextInfo:), nil);
                } else if (type == SYCacheFileTypeImage) {
                    UIImage *image = [UIImage imageWithContentsOfFile:model.filePath];
                    UIImageWriteToSavedPhotosAlbum(image, weakSelf, @selector(image:didFinishSavingWithError:contextInfo:), nil);
                }
            }];
            [alertController addAction:cacheAction];
        }
        UIAlertAction *deleteAction = [UIAlertAction actionWithTitle:@"删除" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [tableView deleItemAtIndex:indexPath];
        }];
        [alertController addAction:deleteAction];
        [weakSelf presentViewController:alertController animated:YES completion:NULL];
    };
}

#pragma mark - 视频图片保存

- (void)video:(NSString *)videoPath didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo
{
    NSString *message = @"保存视频到相册成功";
    if (error) {
        message = @"保存视频到相册失败";
    }
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil message:message preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        
    }];
    [alertController addAction:cancelAction];
    [self presentViewController:alertController animated:YES completion:NULL];
}

- (void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo
{
    NSString *message = @"保存图片到相册成功";
    if (error) {
        message = @"保存图片到相册失败";
    }
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil message:message preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        
    }];
    [alertController addAction:cancelAction];
    [self presentViewController:alertController animated:YES completion:NULL];
}

#pragma mark - 响应

#pragma mark - 数据 

- (void)loadData
{
    if (self.cacheArray == nil) {
        // 初始化，首次显示总目录
        NSString *path = [SYCacheFileManager homeDirectoryPath];
        NSArray *array = [[SYCacheFileManager shareManager] fileModelsWithFilePath:path];
        self.cacheArray = [NSMutableArray arrayWithArray:array];
    }
    
    if (self.cacheArray && 0 < self.cacheArray.count) {
        self.cacheTable.cacheDatas = self.cacheArray;
        [self.cacheTable reloadData];
    }
}

#pragma mark - getter

- (SYCacheFileTable *)cacheTable
{
    if (_cacheTable == nil) {
        _cacheTable = [[SYCacheFileTable alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
        _cacheTable.backgroundColor = [UIColor clearColor];
        _cacheTable.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    }
    return _cacheTable;
}

- (SYCacheFileRead *)fileRead
{
    if (_fileRead == nil) {
        _fileRead = [[SYCacheFileRead alloc] init];
    }
    return _fileRead;
}

@end
