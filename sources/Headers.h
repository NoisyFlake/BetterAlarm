#ifdef DEBUG
#define NSLog(fmt, ...) NSLog((@"[BetterAlarm] " fmt), ##__VA_ARGS__)
#else
#define NSLog(fmt, ...)
#endif

#define returnIfNotEnabled() if (![preferences boolForKey:@"enabled"]) return
#define kDEVICEWIDTH [[UIScreen mainScreen] bounds].size.width

@interface UIView (BetterAlarm)
-(id)_viewControllerForAncestor;
@end

@interface CSModalButton : UIButton
@property (nonatomic, strong, readwrite) UIVisualEffect *visualEffect;
@property (retain, nonatomic) UIView * blurView;
@end

@interface CSModalView : UIView
@property(retain, nonatomic, getter=_primaryActionButton, setter=_setPrimaryActionButton:) CSModalButton *primaryActionButton;
@property(retain, nonatomic, getter=_secondaryActionButton, setter=_setsecondaryActionButton:) CSModalButton *secondaryActionButton;
@property(retain, nonatomic, getter=_titleLabel, setter=_setTitleLabel:) UILabel *titleLabel;
@end

@interface CSFullscreenNotificationView : CSModalView
@property (retain, nonatomic) UILabel * currentTime;
@property (retain, nonatomic) UILabel * alarmTitle;
@end

@interface NCNotificationRequest : NSObject
@property (nonatomic,copy,readonly) NSString * sectionIdentifier;
@property (nonatomic,copy,readonly) NSString * categoryIdentifier;
@end

@interface CSFullscreenNotificationViewController : UIViewController
@property (nonatomic, strong, readwrite) NCNotificationRequest *notificationRequest;
@end

@interface CSTeachableMomentsContainerView : UIView
@end

@interface SBUIBackgroundView : UIView
@end

@interface CSCoverSheetView : UIView
@property (nonatomic, strong, readwrite) UIView *proudLockContainerView;
@property (nonatomic, strong, readwrite) CSTeachableMomentsContainerView *teachableMomentsContainerView;
@property (nonatomic, strong, readwrite) SBUIBackgroundView *backgroundView;
@end

static void clearScreen(UIView *view, BOOL clear);
static NSString *keyFor(NSString *key);