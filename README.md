# BaiduIMECleaner（百度输入法去广告精简插件）

基于 Theos 开发的 iOS 越狱 Tweak，针对百度输入法 13.3.18 版本，去除广告、精简冗余功能。

## 功能

### 去广告
- **AICloudAD（AI云广告）**：拦截 AI 云广告卡片、横幅、Web 广告页
- **HeadFigureBanner（头像推广横幅）**：隐藏候选栏上方的头像推广横幅
- **SCRM 推荐卡片**：阻止社交推荐卡片弹出
- **彩蛋广告**：隐藏 BIEasterEggCandyAdvertisement
- **能量横幅**：隐藏 BIAICloudEnergyBannerViewController
- **Banner Cell**：隐藏 BIBannerCollectionViewCell / BIKingkongBannerCell
- **BDPTask 浮窗/弹窗/Toast**：隐藏任务中心浮窗和弹窗

### 精简功能
- 关闭圈子（Circle）
- 关闭 AI 搜索 Web
- 关闭 SOP 改写
- 关闭翻译
- 关闭 MSBank（妙笔 Bank）

## 目标 Bundle

| 进程 | Bundle ID |
|------|-----------|
| 键盘扩展（主） | `com.baidu.inputMethod.keyboard` |
| 主 App | `com.baidu.inputMethod` |
| LiveActivity 扩展 | `com.baidu.inputMethod.liveactivity` |
| 通知内容扩展 | `com.baidu.inputMethod.notificationcontent` |
| 通知服务扩展 | `com.baidu.inputMethod.notificationservice` |

## Hook 的类清单

### 广告视图类（直接隐藏）
- `BIAICloudADView`
- `BIAICloudADScrollView`
- `BIAICloudCardADView`
- `BIAICloudCardADContainerView`
- `BIAICloudADWebViewController`
- `BIHeadFigureBannerViewController`
- `BIEasterEggCandyAdvertisement`
- `BIEggAdElementView`
- `BIAICloudEnergyBannerViewController`
- `BIKingkongBannerCell`
- `BIBannerCollectionViewCell`
- `BDPTaskBuoyView`
- `BDPTaskAlertView`
- `BDPTaskToastView`

### 输入状态类（阻止切换）
- `BIKBInputStatusAICloudAD`
- `BIKBInputStatusPanelAndHeadFigure`
- `BIKBInputStatusPanelAndAICloundCandHeadFigure`
- `BIKBInputStatusPanelAndLoveKBHeadFigure`
- `BIKBInputStatusPanelHeadFigureAndSug`
- `BIKBInputStatusSCRMCard`
- `BIKBInputStatusSCRMRecommendCard`
- `BIKBInputStatusCircle`
- `BIKBInputStatusAISearchWeb`
- `BIKBInputStatusSOPRewrite`
- `BIKBInputStatusTranslation`
- `BIKBInputStatusMSBank`

## 编译方法

### 方式一：GitHub Actions（推荐）

1. 新建 GitHub 仓库，把本目录所有文件上传到根目录
2. GitHub 自动触发 Actions，在 artifacts 里下载 `*.deb`
3. 用 Sileo / Zebra 安装，respring

### 方式二：本地编译

```bash
# 安装 Theos
export THEOS=/opt/theos
git clone --recursive https://github.com/theos/theos.git $THEOS

# 编译 rootless（多巴胺 / palera1n rootless）
./build.sh rootless

# 编译 rootful
./build.sh rootful

# 全平台编译
./build.sh all
```

产物在 `packages/` 目录。

## 配置

偏好 plist 路径：`/var/mobile/Library/Preferences/com.baiduime.cleaner.plist`

| 键 | 类型 | 默认 | 说明 |
|----|------|------|------|
| `RemoveAd` | Bool | YES | 去广告总开关 |
| `SimplifyFeatures` | Bool | YES | 精简冗余功能 |
| `VerboseLog` | Bool | NO | 详细日志（写到 `/var/mobile/Library/BaiduIMECleaner.log`） |

## 目录结构

```
BaiduIMECleaner/
├── Makefile                          # Theos 主 Makefile
├── BaiduIMECleaner_Build.mk          # 构建参数（架构、iOS 版本）
├── BaiduIMECleaner.plist             # Filter：注入到哪些进程
├── control                           # deb 包信息
├── build.sh                          # 本地构建脚本
├── Hooks/
│   └── BaiduIMECleaner.xm            # 主 Hook 代码（Logos 语法）
├── Sources/                          # 工具类（预留）
├── layout/                           # 安装路径布局
└── .github/workflows/build.yml       # GitHub Actions CI
```

## 适配说明

- 基于 **百度输入法 13.3.18** class-dump 结果编写
- 架构：arm64 + arm64e
- 最低 iOS：rootless 15.0 / rootful 14.0
- 若后续版本类名变更，在 `Hooks/BaiduIMECleaner.xm` 中补充新类名即可

## 后续扩展计划

- [ ] 网络层拦截广告域名（注册自定义 URLProtocol）
- [ ] 设置面板（Preference Bundle），可视化开关
- [ ] 皮肤商店去广告
- [ ] 剪切板广告拦截
- [ ] 云输入/遥测上报关闭
