#ifdef DEBUG
#define NSLog(fmt, ...) NSLog((@"[BetterAlarm] " fmt), ##__VA_ARGS__)
#else
#define NSLog(fmt, ...)
#endif

#define returnIfNotEnabled() if (![preferences boolForKey:@"enabled"]) return
#define returnIfCategoryUnknown() if (!([currentCategory isEqual:@"MTAlarmCategory"] || [currentCategory isEqual:@"MTAlarmNoSnoozeCategory"] || [currentCategory isEqual:@"MTWakeUpAlarmCategory"] || [currentCategory isEqual:@"MTTimerCategory"])) return
#define kDEVICEWIDTH [[UIScreen mainScreen] bounds].size.width

@interface UIView (BetterAlarm)
-(id)_viewControllerForAncestor;
@end

@interface CSModalButton : UIButton
@property (nonatomic, strong, readwrite) UIVisualEffect *visualEffect;
@end

@interface UIButton (BetterAlarm)
@property (retain, nonatomic) UIView * betterAlarmBlurView;
@end

@interface CSModalView : UIView
@property(retain, nonatomic, getter=_primaryActionButton, setter=_setPrimaryActionButton:) CSModalButton *primaryActionButton;
@property(retain, nonatomic, getter=_secondaryActionButton, setter=_setsecondaryActionButton:) UIButton *secondaryActionButton;
@property(retain, nonatomic, getter=_titleLabel, setter=_setTitleLabel:) UILabel *titleLabel;
@end

@interface CSFullscreenNotificationView : CSModalView
@property (retain, nonatomic) UILabel * currentTime;
@property (retain, nonatomic) UILabel * alarmTitle;
@end

@interface NCNotificationAction : NSObject
@property (nonatomic,copy,readonly) NSString * identifier;
@property (nonatomic,copy,readonly) NSString * title;
@end

@interface NCNotificationRequest : NSObject
@property (nonatomic,copy,readonly) NSString * sectionIdentifier;
@property (nonatomic,copy,readonly) NSString * categoryIdentifier;
@property (nonatomic,copy,readonly) NSString * notificationIdentifier;
@end

@interface CSFullscreenNotificationViewController : UIViewController
@property (nonatomic, strong, readwrite) NCNotificationRequest *notificationRequest;
- (void)betterAlarmShowAlertFor:action withName:name;
- (void)_handleOrigAction:(NCNotificationAction *)action withName:(id)name;
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

@interface SBBacklightController : NSObject
@property (nonatomic,readonly) BOOL screenIsOn;
+(id)sharedInstance;
@end

@interface SBLockScreenManager : NSObject
+(id)sharedInstance;
-(BOOL)unlockUIFromSource:(int)arg1 withOptions:(id)arg2 ;
@end

@interface DDNotificationView : UIView
-(void)requestDestruction;
@end

static void clearScreen(UIView *view, BOOL clear);
static NSString *keyFor(NSString *key);