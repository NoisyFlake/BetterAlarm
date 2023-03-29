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
@property (retain, nonatomic) CAGradientLayer * betterAlarmGradientLayer;
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

@interface CSFullscreenNotificationViewController : UIViewController <AVCaptureMetadataOutputObjectsDelegate>
@property (nonatomic, assign) CGRect scanRect;
@property (nonatomic, strong, readwrite) NCNotificationRequest *notificationRequest;
- (void)betterAlarmShowAlertFor:action withName:name;
- (void)_handleOrigAction:(NCNotificationAction *)action withName:(id)name;
- (void)startQRCapture;
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
-(BOOL)unlockUIFromSource:(int)arg1 withOptions:(id)arg2;
-(BOOL)isUILocked;
-(void)lockScreenViewControllerRequestsUnlock;
@end

@interface DDNotificationView : UIView
-(void)requestDestruction;
@end

@interface _UIStatusBarStyleAttributes : NSObject
@property (nonatomic,copy) UIFont * font;
@property (nonatomic,copy) UIFont * emphasizedFont;
@end

@interface _UIStatusBarStringView : UILabel
@property (nonatomic,copy) NSString * originalText;
-(void)applyStyleAttributes:(_UIStatusBarStyleAttributes *)arg1;
@end

@interface MTAlarm : NSObject
@property (nonatomic,readonly) NSDate * nextFireDate;
@property (assign,getter=isEnabled,nonatomic) BOOL enabled;
@property (nonatomic,readonly) BOOL repeats;
@property (nonatomic,copy) NSDate * keepOffUntilDate;
@property (assign,nonatomic) BOOL sleepSchedule;
@end

@interface MTAlarmCache : NSObject
@property (nonatomic,retain) MTAlarm * nextAlarm;
@end

@interface MTAlarmManager : NSObject
@property (nonatomic,retain) MTAlarmCache * cache;
-(id)updateAlarm:(id)arg1 ;
@end

@interface _UIStatusBarItem : NSObject
@end

@interface _UIStatusBarCellularItem : _UIStatusBarItem
@property (nonatomic,retain) _UIStatusBarStringView * serviceNameView;
@end

@interface _UIStatusBarIndicatorItem : _UIStatusBarItem
@end

@interface BetterAlarmStatusBarStringView : _UIStatusBarStringView
@end

@interface UIImage (BetterAlarm)
- (UIImage *)scaleImageToSize:(CGSize)newSize;
@end

@interface FigCaptureClientSessionMonitor : NSObject
@property (readonly) NSString * applicationID; 
@end

@interface FigCaptureClientSessionMonitorClient : NSObject
@property (nonatomic,readonly) NSString * applicationID;
@end

@interface SpringBoard : UIApplication
-(void)applicationOpenURL:(id)arg1;
@end

static void clearScreen(UIView *view, BOOL clear);
static NSString *keyFor(NSString *key);

#define iconAlarm @"data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAGAAAABgCAYAAADimHc4AAAFaUlEQVR4Ae3dA7QjWxaH8Xfbtm1r2cazbdto27Zt27Zt27pJ253a841nTi5SVadSucn51votc//j97r7GZPLTKay+AwTsBWHcB43kYwdmIFGaIAkxHLV8TNmYAtO4e6/HMMaTMTPqABfyoeWOAqx6TK6oipipZroiXMQm/ahLQrD8/KiOYIQDXrCz5IwHaLBLbRAbnjS80iGaHIUReF31XAJoslVvAKtNUUIosl5VIil133NI1hoAdflwjSIRhdQBUpxNgIwFTnhqEyY68Px422E2cgE2/X14fjxOkJv2OqtGDl+RbyEPzEMa3AAZxHEEzxGAGdxAGswDH/iRVTw/Y0ZeA0RVQCXfTp+KXyCMTgH0eQsRuNjlPRphIvIj3TrH+Xj58GnWAkL4rEQVuAT5HE3gv6XoqJ4EKXjV8NI3IP45C5GoGqURriHwki1NlE4fj1MQQgSI0KYjLpRGKElUu2sh8cvhrGwIDHKwhgU9XCE40ixOh4dPxN+wA1IBhHEd8jk0Qg1EFYjD45fHpshGdRGlIM6wkWIC78jrImaj/8qgpAMLoCXNY8wGmFt13T8TOgJiTPdkUnTCJsRVrKG42fHDEicmoZsGka4jLBuuzx+PqyCxLmVyOtyhADCuuPy+DsgUbQApVAaiyBRtN3lCLcQVsDFy44fj/zS+HdlIVG2wsXL0WWEtd3JG65Pr/kW/rckiA+mOnxj3oKwpjj4qNkTkrADAN0cfESdgrAaO/icL2aAZyy8ZHOE3xFWPZvfcIMwAwABm9+Y6yDFzkf4285miBng/2xApghGOI9U6x7Br5o/QMwAKfoWauoIHZFqNSL4SfmGGSBVQRSFWkUch4UqSLPJqIKUGgsxA9j/oY2KoRccVw+WGSBdFmpDe1MgZoCITITWqiFkBojYU1SBtkZCzAC2DIeW8uCeGcC2u8gN130KMQM48jFct9IM4NhyuKoULDOAYyGUgOM+gZgBXPkQjhtjBnBtJBx31gzg2mk4qiLEDKBFOdjuJTOANs/Ddn+aAbT5DbYbZgbQZjBst8YMoM0q2O6AGUCbvbH8EdRyIJTBBjgF2wWj9P92ui/2B7gO2z2GeKgUKCEGeBiLA5SBrsrF4wABiIcWoxwyuVQeS+LxJegMxPDvTXg/xPDvY+hqiBbGSthuKMTw76eIPyCGfz/GvQjRwngOtqsA0cIoC/Ljo6hxCo4bBXHFGAHHfQRxxfgAjiuJEMQRI4TicNUKiCPGUrjuE4gjxodwXW7chRi23EEuaGk4xLBlKLRVBU8hRkSeojK0NgliRGQ8tFcHFiRNhoVa8KTREJfMN18XFUUQkiIjGYXhad9CUmR8Dc/LhA2Q/2OsQxKiUlkEIP9gJKMMotpLsCAJzsIL8KWukATXGb6VCVMhCWoSkuBr2RL0J+tlyIqYKC+2QRLEFuSBr+VAUWWE5YnwyFeOXwzZ/Tj+EhxACeXlaEo8v+YrLzslcQiLkD3axxcITqCC8sbcFRYkTljorLzhVsRJCKCM4PXxlQNfQA38by8iOU6+ZKmf82vhojKQOoL3x1ckow7Ub8zrM/jPC+o33HoIQAD3I7g9vgXBfGSDWhK+QSCDPeq/RhLUsmMhBJb+ETQeX6kIRmaAf8htBApDzZcRsmOp2+Mr1cIEPIXEiKcYj5pQcjXCYmSD47rpPL5SZQzDHYhP7mAIKkFJ2wid4bgrEN3HV8qFj7AMoSg92pfiQ+SCksYRgEs6B1CPr7vi+AAjcAqiyUkMx/soDr0pI+gcoDNEoRzf08riOfyKwViJPTiJa3jwL9dwEnuwAoPwK55DWXibMoKiIxyXDZ1w4V86IhtMkd8rK2I1098AFIGjP4SNpa4AAAAASUVORK5CYII="