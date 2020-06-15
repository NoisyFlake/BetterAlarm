#import <Preferences/PSListController.h>
#import <Preferences/PSTableCell.h>
#import <Preferences/PSSpecifier.h>

#define kBETTERALARMCOLOR [UIColor colorWithRed: 0.95 green: 0.58 blue: 0.36 alpha: 1.00]
#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)

@interface NSTask : NSObject
- (instancetype)init;
- (void)setLaunchPath:(NSString *)path;
- (void)setArguments:(NSArray *)arguments;
- (void)setStandardOutput:(id)output;
- (void)launch;
- (void)waitUntilExit;
@end

@interface UINavigationItem (Velvet)
@property (assign,nonatomic) UINavigationBar * navigationBar;
@end

@interface PSControlTableCell : PSTableCell
@property (nonatomic, retain) UIControl *control;
@end

@interface PSSwitchTableCell : PSControlTableCell
- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(id)identifier specifier:(id)specifier;
@end

@interface BetterAlarmToggle : PSSwitchTableCell
@end

@interface BetterAlarmBaseController : PSListController
@end

@interface BetterAlarmRootListController : BetterAlarmBaseController
@end
