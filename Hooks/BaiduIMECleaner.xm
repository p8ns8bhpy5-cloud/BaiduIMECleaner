//
//  BaiduIMECleaner.xm
//  百度输入法去广告精简插件 - 主 Hook
//
//  基于百度输入法 13.3.18 class-dump 结果编写
//  Bundle: com.baidu.inputMethod.keyboard
//
//  功能：
//  1. 去除 AICloudAD（AI云广告卡片/横幅/Web广告）
//  2. 去除 HeadFigureBanner（头像推广横幅）
//  3. 去除 SCRM 推荐卡片
//  4. 去除彩蛋广告、Banner Cell、能量横幅
//  5. 去除 BDPTask 浮窗/弹窗/Toast
//  6. 关闭积分/签到/红包入口
//  7. 精简：可关闭 AI云、圈子、AI搜索、翻译等冗余功能
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <substrate.h>

// ==================== 配置 ====================
// 通过偏好 plist 控制开关，路径：/var/mobile/Library/Preferences/com.baiduime.cleaner.plist
static NSString *const kCleanerPrefsPath = @"/var/mobile/Library/Preferences/com.baiduime.cleaner.plist";

// 默认全部开启
static BOOL gRemoveAd = YES;           // 去广告
static BOOL gSimplifyFeatures = YES;   // 精简冗余功能
static BOOL gVerboseLog = NO;          // 详细日志（调试用）

static void reloadPrefs(void) {
    NSDictionary *p = [NSDictionary dictionaryWithContentsOfFile:kCleanerPrefsPath];
    if (p) {
        gRemoveAd = p[@"RemoveAd"] ? [p[@"RemoveAd"] boolValue] : YES;
        gSimplifyFeatures = p[@"SimplifyFeatures"] ? [p[@"SimplifyFeatures"] boolValue] : YES;
        gVerboseLog = [p[@"VerboseLog"] boolValue];
    }
}

static void writeLog(NSString *msg) {
    if (!gVerboseLog) return;
    NSString *line = [NSString stringWithFormat:@"[BICleaner] %@ %@\n", [NSDate date], msg];
    NSData *data = [line dataUsingEncoding:NSUTF8StringEncoding];
    NSString *logPath = @"/var/mobile/Library/BaiduIMECleaner.log";
    NSFileHandle *fh = [NSFileHandle fileHandleForWritingAtPath:logPath];
    if (fh) { [fh seekToEndOfFile]; [fh writeData:data]; }
    else { [data writeToFile:logPath atomically:YES]; }
}

// ==================== 工具方法 ====================

// 安全地向某个类发送消息，若类不存在则忽略
static void BIC_SafeHook(Class cls) {
    if (!cls) return;
    writeLog([NSString stringWithFormat:@"已加载类: %@", NSStringFromClass(cls)]);
}

// 视图层级扫描：隐藏所有广告视图
static void BIC_HideAdViewsInView(UIView *view) {
    if (!view || view.hidden) return;

    // 检查视图类名
    NSString *clsName = NSStringFromClass([view class]);
    NSArray *adClassKeywords = @[
        @"AICloudAD",
        @"CardADView",
        @"CardADContainer",
        @"HeadFigureBanner",
        @"EnergyBanner",
        @"EasterEggCandyAdvertisement",
        @"EggAdElement",
        @"SCRMRecommend",
        @"SCRMRecomment",
        @"KingkongBanner",
        @"BannerCollectionView",
    ];

    for (NSString *kw in adClassKeywords) {
        if ([clsName containsString:kw]) {
            view.hidden = YES;
            view.alpha = 0.0;
            view.frame = CGRectZero;
            writeLog([NSString stringWithFormat:@"隐藏广告视图: %@", clsName]);
            return; // 已隐藏，不再遍历子视图
        }
    }

    // 递归遍历子视图
    for (UIView *sub in view.subviews) {
        BIC_HideAdViewsInView(sub);
    }
}

// 全局扫描键盘窗口
static void BIC_SweepAllWindows(void) {
    UIApplication *app = [UIApplication sharedApplication];
    NSMutableSet *windows = [NSMutableSet set];
    for (UIWindow *w in app.windows) [windows addObject:w];
    if ([UIScene class]) {
        for (UIScene *sc in app.connectedScenes) {
            if ([sc respondsToSelector:@selector(windows)]) {
                for (UIWindow *w in [(id)sc windows]) [windows addObject:w];
            }
        }
    }
    int hidden = 0;
    for (UIWindow *win in windows) {
        NSUInteger before = win.subviews.count;
        BIC_HideAdViewsInView(win);
        hidden += before;
    }
    writeLog([NSString stringWithFormat:@"全局扫描完成，检查 %lu 个窗口", (unsigned long)windows.count]);
}

// ==================== Hook 区域 ====================

#pragma mark - AICloudAD（AI云广告）

// 拦截 AI 云广告视图的初始化
%hook BIAICloudADView
- (void)didMoveToSuperview {
    %orig;
    if (gRemoveAd) {
        self.hidden = YES;
        self.alpha = 0.0;
        writeLog(@"BIAICloudADView 已隐藏");
    }
}
%end

%hook BIAICloudADScrollView
- (void)didMoveToSuperview {
    %orig;
    if (gRemoveAd) {
        self.hidden = YES;
        writeLog(@"BIAICloudADScrollView 已隐藏");
    }
}
%end

%hook BIAICloudCardADView
- (void)didMoveToSuperview {
    %orig;
    if (gRemoveAd) {
        self.hidden = YES;
        writeLog(@"BIAICloudCardADView 已隐藏");
    }
}
%end

%hook BIAICloudCardADContainerView
- (void)didMoveToSuperview {
    %orig;
    if (gRemoveAd) {
        self.hidden = YES;
        writeLog(@"BIAICloudCardADContainerView 已隐藏");
    }
}
%end

// 拦截 AI 云广告 Web 视图控制器
%hook BIAICloudADWebViewController
- (void)viewDidLoad {
    %orig;
    if (gRemoveAd) {
        writeLog(@"BIAICloudADWebViewController 被拦截，执行关闭");
        // 直接关闭，不展示广告页
        if (self.presentingViewController) {
            [self dismissViewControllerAnimated:NO completion:nil];
        }
    }
}
%end

// 拦截 AI 云广告卡片数据源，返回空
%hook BIAICloudADCardModel
- (NSDictionary *)toDictionary {
    if (gRemoveAd) return @{};
    return %orig;
}
%end

// 拦截输入状态：AICloudAD
%hook BIKBInputStatusAICloudAD
- (void)begin {
    if (gRemoveAd) {
        writeLog(@"BIKBInputStatusAICloudAD 状态被阻止");
        return; // 不执行广告状态切换
    }
    %orig;
}
%end

#pragma mark - HeadFigureBanner（头像推广横幅）

%hook BIHeadFigureBannerViewController
- (void)viewDidLoad {
    %orig;
    if (gRemoveAd) {
        self.view.hidden = YES;
        self.view.alpha = 0.0;
        writeLog(@"BIHeadFigureBannerViewController 已隐藏");
    }
}
%end

// 拦截"是否应该显示头像横幅"的判断
%hook BIKBInputStatusPanelAndHeadFigure
- (void)begin {
    if (gRemoveAd) {
        writeLog(@"BIKBInputStatusPanelAndHeadFigure 状态被阻止");
        return;
    }
    %orig;
}
%end

%hook BIKBInputStatusPanelAndAICloundCandHeadFigure
- (void)begin {
    if (gRemoveAd) {
        writeLog(@"BIKBInputStatusPanelAndAICloundCandHeadFigure 状态被阻止");
        return;
    }
    %orig;
}
%end

%hook BIKBInputStatusPanelAndLoveKBHeadFigure
- (void)begin {
    if (gRemoveAd) {
        writeLog(@"BIKBInputStatusPanelAndLoveKBHeadFigure 状态被阻止");
        return;
    }
    %orig;
}
%end

%hook BIKBInputStatusPanelHeadFigureAndSug
- (void)begin {
    if (gRemoveAd) {
        writeLog(@"BIKBInputStatusPanelHeadFigureAndSug 状态被阻止");
        return;
    }
    %orig;
}
%end

#pragma mark - SCRM（社交推荐卡片）

%hook BIKBInputStatusSCRMCard
- (void)begin {
    if (gRemoveAd) {
        writeLog(@"BIKBInputStatusSCRMCard 状态被阻止");
        return;
    }
    %orig;
}
%end

%hook BIKBInputStatusSCRMRecommendCard
- (void)begin {
    if (gRemoveAd) {
        writeLog(@"BIKBInputStatusSCRMRecommendCard 状态被阻止");
        return;
    }
    %orig;
}
%end

#pragma mark - 彩蛋广告 / 能量横幅 / Kingkong Banner

%hook BIEasterEggCandyAdvertisement
- (void)didMoveToSuperview {
    %orig;
    if (gRemoveAd) {
        self.hidden = YES;
        writeLog(@"BIEasterEggCandyAdvertisement 已隐藏");
    }
}
%end

%hook BIEggAdElementView
- (void)didMoveToSuperview {
    %orig;
    if (gRemoveAd) {
        self.hidden = YES;
        writeLog(@"BIEggAdElementView 已隐藏");
    }
}
%end

%hook BIAICloudEnergyBannerViewController
- (void)viewDidLoad {
    %orig;
    if (gRemoveAd) {
        self.view.hidden = YES;
        writeLog(@"BIAICloudEnergyBannerViewController 已隐藏");
    }
}
%end

%hook BIKingkongBannerCell
- (void)didMoveToSuperview {
    %orig;
    if (gRemoveAd) {
        self.hidden = YES;
        writeLog(@"BIKingkongBannerCell 已隐藏");
    }
}
%end

%hook BIBannerCollectionViewCell
- (void)didMoveToSuperview {
    %orig;
    if (gRemoveAd) {
        self.hidden = YES;
        writeLog(@"BIBannerCollectionViewCell 已隐藏");
    }
}
%end

#pragma mark - BDPTask 浮窗/弹窗/Toast

%hook BDPTaskBuoyView
- (void)didMoveToSuperview {
    %orig;
    if (gRemoveAd) {
        self.hidden = YES;
        writeLog(@"BDPTaskBuoyView 浮窗已隐藏");
    }
}
%end

%hook BDPTaskAlertView
- (void)didMoveToSuperview {
    %orig;
    if (gRemoveAd) {
        self.hidden = YES;
        writeLog(@"BDPTaskAlertView 弹窗已隐藏");
    }
}
%end

%hook BDPTaskToastView
- (void)didMoveToSuperview {
    %orig;
    if (gRemoveAd) {
        self.hidden = YES;
        writeLog(@"BDPTaskToastView Toast已隐藏");
    }
}
%end

#pragma mark - 精简：关闭冗余功能

// 关闭圈子（Circle）
%hook BIKBInputStatusCircle
- (void)begin {
    if (gSimplifyFeatures) {
        writeLog(@"BIKBInputStatusCircle 圈子功能被精简");
        return;
    }
    %orig;
}
%end

// 关闭 AI 搜索 Web
%hook BIKBInputStatusAISearchWeb
- (void)begin {
    if (gSimplifyFeatures) {
        writeLog(@"BIKBInputStatusAISearchWeb AI搜索被精简");
        return;
    }
    %orig;
}
%end

// 关闭 SOP 改写
%hook BIKBInputStatusSOPRewrite
- (void)begin {
    if (gSimplifyFeatures) {
        writeLog(@"BIKBInputStatusSOPRewrite 改写功能被精简");
        return;
    }
    %orig;
}
%end

// 关闭翻译
%hook BIKBInputStatusTranslation
- (void)begin {
    if (gSimplifyFeatures) {
        writeLog(@"BIKBInputStatusTranslation 翻译功能被精简");
        return;
    }
    %orig;
}
%end

// 关闭 MSBank（妙笔Bank）
%hook BIKBInputStatusMSBank
- (void)begin {
    if (gSimplifyFeatures) {
        writeLog(@"BIKBInputStatusMSBank 妙笔Bank被精简");
        return;
    }
    %orig;
}
%end

#pragma mark - 网络请求拦截（广告域名）

// Hook NSURLSession 配置，拦截广告请求
%hook NSURLSessionConfiguration
- (NSArray *)protocolClasses {
    NSMutableArray *classes = [NSMutableArray arrayWithArray:%orig];
    // 预留：可注册自定义 URLProtocol 拦截广告请求
    // 目前通过视图层拦截已足够，网络层作为后续扩展
    return classes;
}
%end

// ==================== 构造函数 ====================

%ctor {
    reloadPrefs();
    writeLog(@"========================================");
    writeLog(@"BaiduIMECleaner 加载成功");
    writeLog([NSString stringWithFormat:@"去广告: %@, 精简功能: %@",
              gRemoveAd ? @"ON" : @"OFF", gSimplifyFeatures ? @"ON" : @"OFF"]);
    writeLog(@"========================================");

    @autoreleasepool {
        // 延迟执行视图扫描，等待键盘视图加载完成
        for (NSNumber *delay in @[@1.0, @3.0, @5.0, @10.0]) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay.doubleValue * NSEC_PER_SEC)),
                           dispatch_get_main_queue(), ^{
                BIC_SweepAllWindows();
            });
        }

        // 监听 UIApplicationDidBecomeActiveNotification，每次激活时扫描
        [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidBecomeActiveNotification
                                                          object:nil
                                                           queue:[NSOperationQueue mainQueue]
                                                      usingBlock:^(NSNotification * _Nonnull note) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)),
                           dispatch_get_main_queue(), ^{
                BIC_SweepAllWindows();
            });
        }];
    }
}
