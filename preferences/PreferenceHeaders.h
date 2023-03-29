#import <Preferences/Preferences.h>
#import <rootless.h>

#define kBETTERALARMCOLOR [UIColor colorWithRed: 0.26 green: 0.57 blue: 0.98 alpha: 1.00] // #4292FB
#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)

@interface NSTask : NSObject
- (instancetype)init;
- (void)setLaunchPath:(NSString *)path;
- (void)setArguments:(NSArray *)arguments;
- (void)setStandardOutput:(id)output;
- (void)launch;
- (void)waitUntilExit;
@end

@interface CALayer(Private)
@property BOOL continuousCorners;
@end

@interface PSListController (BetterAlarm)
-(void)_returnKeyPressed:(id)arg1;
@end

@interface UIView (BetterAlarm)
-(id)_viewControllerForAncestor;
@end

@interface UINavigationItem (BetterAlarm)
@property (assign,nonatomic) UINavigationBar * navigationBar;
@end

@interface BetterAlarmButton : PSTableCell
@end

@interface BetterAlarmSlider : PSSliderTableCell
@property (nonatomic, retain) UILabel *leftLabel;
@property (nonatomic, retain) UILabel *rightLabel;
@end

@interface BetterAlarmInput : PSEditableTableCell
@end

@interface BetterAlarmToggle : PSSwitchTableCell
@end

@interface BetterAlarmBaseController : PSListController
@end

@interface BetterAlarmRootListController : BetterAlarmBaseController
@end

@interface BetterAlarmTimerController : BetterAlarmBaseController
@end

@interface BetterAlarmPreviewController : BetterAlarmBaseController
@end

@interface BetterAlarmAlarmsController : BetterAlarmBaseController
@end

@interface BetterAlarmQRController : BetterAlarmBaseController
@end

@interface BetterAlarmListItemsController : PSListItemsController
@end

@interface BetterAlarmColorPicker : PSTableCell <UIColorPickerViewControllerDelegate>
@property (nonatomic, retain) UIView *cellColorDisplay;
@property (nonatomic, retain) UIColor *selectedColor;
-(void)openColorPicker;
@end
