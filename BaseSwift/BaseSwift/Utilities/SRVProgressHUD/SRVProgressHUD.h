//
//  SRVProgressHUD.h
//  BaseSwift
//
//  Created by Gary on 2017/8/28.
//  Copyright © 2017年 shadowR. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <SVProgressHUD/SVProgressHUD.h>
#import <SVProgressHUD/SVRadialGradientLayer.h>
#import <SVProgressHUD/SVIndefiniteAnimatedView.h>
#import <SVProgressHUD/SVProgressAnimatedView.h>

// A more clean and lightweight SRVProgressHUD(https://github.com/SRVProgressHUD/SRVProgressHUD)
// not use single instance design pattern
@interface SRVProgressHUD : UIView

#pragma mark - Customization
@property (assign, nonatomic) SVProgressHUDStyle defaultStyle UI_APPEARANCE_SELECTOR; // default is SRVProgressHUDStyleLight
@property (assign, nonatomic) SVProgressHUDMaskType defaultMaskType UI_APPEARANCE_SELECTOR; // default is SRVProgressHUDMaskTypeNone
@property (assign, nonatomic) SVProgressHUDAnimationType defaultAnimationType UI_APPEARANCE_SELECTOR; // default is SRVProgressHUDAnimationTypeFlat
@property (strong, nonatomic, nullable) UIView *containerView; // if nil then use default window level
@property (assign, nonatomic) CGSize minimumSize UI_APPEARANCE_SELECTOR; // default is CGSizeZero, can be used to avoid resizing for a larger message
@property (assign, nonatomic) CGFloat ringThickness UI_APPEARANCE_SELECTOR;    // default is 2 pt
@property (assign, nonatomic) CGFloat ringRadius UI_APPEARANCE_SELECTOR;       // default is 18 pt
@property (assign, nonatomic) CGFloat ringNoTextRadius UI_APPEARANCE_SELECTOR; // default is 24 pt
@property (assign, nonatomic) CGFloat cornerRadius UI_APPEARANCE_SELECTOR;     // default is 14 pt
@property (strong, nonatomic, nonnull) UIFont *font UI_APPEARANCE_SELECTOR; // default is [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline]
@property (strong, nonatomic, nonnull) UIColor *backgroundColor UI_APPEARANCE_SELECTOR; // default is [UIColor whiteColor]
@property (strong, nonatomic, nonnull) UIColor *foregroundColor UI_APPEARANCE_SELECTOR; // default is [UIColor blackColor]
@property (strong, nonatomic, nonnull) UIColor *backgroundLayerColor UI_APPEARANCE_SELECTOR; // default is [UIColor colorWithWhite:0 alpha:0.4]
@property (assign, nonatomic) CGSize imageViewSize UI_APPEARANCE_SELECTOR; // default is 28x28 pt
@property (strong, nonatomic, nonnull) UIImage *infoImage UI_APPEARANCE_SELECTOR; // default is the bundled info image provided by Freepik
@property (strong, nonatomic, nonnull) UIImage *successImage UI_APPEARANCE_SELECTOR; // default is the bundled success image provided by Freepik
@property (strong, nonatomic, nonnull) UIImage *errorImage UI_APPEARANCE_SELECTOR; // default is the bundled error image provided by Freepik
@property (strong, nonatomic, nonnull) UIView *viewForExtension UI_APPEARANCE_SELECTOR; // default is nil, only used if #define SV_APP_EXTENSIONS is set
@property (assign, nonatomic) NSTimeInterval minimumDismissTimeInterval; // default is 5.0 seconds
@property (assign, nonatomic) NSTimeInterval maximumDismissTimeInterval; // default is CGFLOAT_MAX

@property (assign, nonatomic) UIOffset offsetFromCenter UI_APPEARANCE_SELECTOR; // default is 0, 0

@property (assign, nonatomic) NSTimeInterval fadeInAnimationDuration UI_APPEARANCE_SELECTOR; // default is 0.15
@property (assign, nonatomic) NSTimeInterval fadeOutAnimationDuration UI_APPEARANCE_SELECTOR; // default is 0.15

@property (assign, nonatomic) UIWindowLevel maxSupportedWindowLevel; // default is UIWindowLevelNormal

@property (assign, nonatomic) BOOL hapticsEnabled; // default is NO

#pragma mark - Custom added by Shadow

@property (assign, nonatomic) BOOL flatHud; // default is NO

- (void)show;
- (void)showProgress:(float)progress;
- (void)showProgress:(float)progress status:(NSString *_Nullable)status;
- (void)dismiss;
- (void)dismiss:(BOOL)animated;
- (void)updateHUDFrame;
@end
