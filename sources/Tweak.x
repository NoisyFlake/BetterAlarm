#import "Headers.h"
#import "ColorUtils.h"

NSUserDefaults *preferences;

BOOL isAlarmActive = NO;
NSString *currentCategory = nil;
NSString *alarmId = nil;
NSInteger snoozeCount = 0;

%ctor {
	// [[NSUserDefaults standardUserDefaults] removePersistentDomainForName:@"com.noisyflake.betteralarm"];
	preferences = [[NSUserDefaults alloc] initWithSuiteName:@"com.noisyflake.betteralarm"];

	[preferences registerDefaults:@{
		@"enabled": @YES,

		@"timerSwapButtons": @YES,
		@"timerSmartSnooze": @NO, // can't be changed via Settings
		@"timerPrimaryPercent": @30,
		@"timerPrimaryBackgroundColor": @"#4292FB:1.00",
		@"timerPrimaryTextColor": @"#FFFFFF:1.00",
		@"timerPrimaryTextSize": @48,

		@"timerSecondaryBackgroundColor": @"#000000:0.0",
		@"timerSecondaryTextColor": @"#FFFFFF:1.00",
		@"timerSecondaryTextSize": @48,

		@"timerClockTextColor": @"#FFFFFF:0.75",
		@"timerClockTextSize": @38,
		
		@"timerTitleTextColor": @"#FFFFFF:0.75",
		@"timerTitleTextSize": @24,

		@"alarmSwapButtons": @NO,
		@"alarmBlockHardwareButtons": @NO,
		@"alarmSmartSnooze": @NO,
		@"alarmSmartSnoozeAmount": @3,
		@"alarmPrimaryPercent": @30,
		@"alarmPrimaryBackgroundColor": @"#000000:0.00",
		@"alarmPrimaryTextColor": @"#FFFFFF:1.00",
		@"alarmPrimaryTextSize": @48,

		@"alarmSecondaryBackgroundColor": @"#A81B1D:1.00",
		@"alarmSecondaryTextColor": @"#FFFFFF:1.00",
		@"alarmSecondaryTextSize": @48,

		@"alarmClockTextColor": @"#FFFFFF:0.75",
		@"alarmClockTextSize": @38,
		
		@"alarmTitleTextColor": @"#FFFFFF:0.75",
		@"alarmTitleTextSize": @24,
	}];
}

%hook CSFullscreenNotificationView
%property (retain, nonatomic) UILabel * currentTime;
%property (retain, nonatomic) UILabel * alarmTitle;

-(void)didMoveToWindow {
	%orig;

	returnIfNotEnabled();
	returnIfCategoryUnknown();

	// This works because [CSModalButton layoutSubviews] is called before this method
	CGFloat primaryHeight = [preferences boolForKey:keyFor(@"SwapButtons")] ? self.primaryActionButton.superview.frame.origin.y : self.primaryActionButton.superview.frame.size.height;

	// Adjust for when there is no second button
	if (primaryHeight == 0) {
		primaryHeight = 150;
	} else if (primaryHeight == [[UIScreen mainScreen] bounds].size.height) {
		primaryHeight = [[UIScreen mainScreen] bounds].size.height - 150;
	}

	CGFloat labelDistance = 15;

	if (!self.currentTime) {
		NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
		NSTimeZone *zone = [NSTimeZone localTimeZone];
		[formatter setTimeZone:zone];
		[formatter setDateFormat:@"HH:mm"];

		if ([[preferences objectForKey:keyFor(@"ClockTextSize")] isEqual:@""]) [preferences removeObjectForKey:keyFor(@"ClockTextSize")];

		self.currentTime = [[UILabel alloc] initWithFrame:CGRectZero];
		self.currentTime.text = [formatter stringFromDate:[NSDate date]];
		self.currentTime.textAlignment = NSTextAlignmentCenter;
		self.currentTime.font = [UIFont systemFontOfSize:[preferences floatForKey:keyFor(@"ClockTextSize")]];
		self.currentTime.textColor = [UIColor betterAlarmRGBAColorFromHexString:[preferences valueForKey:keyFor(@"ClockTextColor")]];
		[self.currentTime sizeToFit];
		self.currentTime.frame = CGRectMake(0, primaryHeight - labelDistance - self.currentTime.frame.size.height, kDEVICEWIDTH, self.currentTime.frame.size.height);

		[self addSubview:self.currentTime];
	}

	self.titleLabel.alpha = 0; // hide the original label

	if (!self.alarmTitle) {
		if ([[preferences objectForKey:keyFor(@"TitleTextSize")] isEqual:@""]) [preferences removeObjectForKey:keyFor(@"TitleTextSize")];

		self.alarmTitle = [[UILabel alloc] initWithFrame:CGRectZero];
		self.alarmTitle.text = self.titleLabel.text;
		self.alarmTitle.textAlignment = NSTextAlignmentCenter;
		self.alarmTitle.numberOfLines = 0;
		self.alarmTitle.font = [UIFont systemFontOfSize:[preferences floatForKey:keyFor(@"TitleTextSize")]];
		self.alarmTitle.textColor = [UIColor betterAlarmRGBAColorFromHexString:[preferences valueForKey:keyFor(@"TitleTextColor")]];
		[self.alarmTitle sizeToFit];
		self.alarmTitle.frame = CGRectMake(0, primaryHeight + labelDistance, kDEVICEWIDTH, self.alarmTitle.frame.size.height);

		[self addSubview:self.alarmTitle];
	}

	clearScreen(self, YES);
}
%end

%hook UIButton
%property (retain, nonatomic) UIView * betterAlarmBlurView;

- (void)layoutSubviews {
	%orig;

	returnIfNotEnabled();
	returnIfCategoryUnknown();

	UIViewController *controller = self._viewControllerForAncestor;
	if (![controller.view isKindOfClass:%c(CSFullscreenNotificationView)]) return;

	CSFullscreenNotificationView *mainView = (CSFullscreenNotificationView *)controller.view;

	BOOL isAlarmWithoutSnooze = [currentCategory isEqual:@"MTAlarmNoSnoozeCategory"];
	CGFloat primaryHeight;

	if (isAlarmWithoutSnooze) {
		primaryHeight = [[UIScreen mainScreen] bounds].size.height;
	} else if ([preferences boolForKey:keyFor(@"SmartSnooze")]) {
		// This is not the alarm that was snoozed before, so our best option is to just reset the counter to 0
		if (![alarmId isEqual:((CSFullscreenNotificationViewController *)controller).notificationRequest.notificationIdentifier]) snoozeCount = 0;

		CGFloat percentage = (snoozeCount + 1) / ([preferences floatForKey:@"alarmSmartSnoozeAmount"] + 1);
		if (percentage > 0 && percentage < 0.2) percentage = 0.2;
		if (percentage < 1 && percentage > 0.8) percentage = 0.8;
		primaryHeight = [[UIScreen mainScreen] bounds].size.height * (1 - percentage);
	} else {
		primaryHeight = [[UIScreen mainScreen] bounds].size.height * ((100 - [preferences floatForKey:keyFor(@"PrimaryPercent")]) / 100);
	}
	
	CGFloat secondaryHeight = [[UIScreen mainScreen] bounds].size.height - primaryHeight;

	// Fix for very small devices like the SE where the text would overlap on default settings
	if ([[UIScreen mainScreen] bounds].size.height <= 568) {
		if (primaryHeight < 175) {
			primaryHeight = 185;
			secondaryHeight = [[UIScreen mainScreen] bounds].size.height - primaryHeight;
		} else if (secondaryHeight < 175) {
			secondaryHeight = 185;
			primaryHeight = [[UIScreen mainScreen] bounds].size.height - secondaryHeight;
		}
	}

	if (self == mainView.primaryActionButton && !isAlarmWithoutSnooze) {
		self.layer.cornerRadius = 0;
		if ([preferences boolForKey:keyFor(@"SwapButtons")]) {
			self.superview.frame = CGRectMake(0, secondaryHeight, kDEVICEWIDTH, primaryHeight);
		} else {
			self.superview.frame = CGRectMake(0, 0, kDEVICEWIDTH, primaryHeight);
		}
		self.frame = CGRectMake(0, 0, kDEVICEWIDTH, primaryHeight);

		if ([[preferences objectForKey:keyFor(@"PrimaryTextSize")] isEqual:@""]) [preferences removeObjectForKey:keyFor(@"PrimaryTextSize")];

		self.titleLabel.center = self.center;
		self.titleLabel.font = [UIFont systemFontOfSize:[preferences floatForKey:keyFor(@"PrimaryTextSize")]];
		[self setTitleColor:[UIColor betterAlarmRGBAColorFromHexString:[preferences valueForKey:keyFor(@"PrimaryTextColor")]] forState:UIControlStateNormal];
		[self.titleLabel sizeToFit];

		UIColor *backgroundColor = [UIColor betterAlarmRGBAColorFromHexString:[preferences valueForKey:keyFor(@"PrimaryBackgroundColor")]];
		CGFloat alpha = 0.0;
		[backgroundColor getRed:nil green:nil blue:nil alpha:&alpha];

		if (alpha < 1 && !self.betterAlarmBlurView) {
			self.backgroundColor = UIColor.clearColor;

			UIBlurEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
			UIVisualEffectView *blurEffectView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
			blurEffectView.frame = CGRectMake(0, 0, self.frame.size.width, self.frame.size.height + 1);
			blurEffectView.backgroundColor = backgroundColor;
			blurEffectView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
			blurEffectView.userInteractionEnabled = NO;

			[self insertSubview:blurEffectView belowSubview:self.titleLabel];

			self.betterAlarmBlurView = blurEffectView;
		} else {
			self.backgroundColor = backgroundColor;
		}

	} else if (self == mainView.secondaryActionButton && !isAlarmWithoutSnooze) {
		self.layer.cornerRadius = 0;
		if ([preferences boolForKey:keyFor(@"SwapButtons")]) {
			self.frame = CGRectMake(0, 0, kDEVICEWIDTH, secondaryHeight);
		} else {
			self.frame = CGRectMake(0, primaryHeight, kDEVICEWIDTH, secondaryHeight);
		}

		if ([[preferences objectForKey:keyFor(@"SecondaryTextSize")] isEqual:@""]) [preferences removeObjectForKey:keyFor(@"SecondaryTextSize")];
		
		self.titleLabel.font = [UIFont systemFontOfSize:[preferences floatForKey:keyFor(@"SecondaryTextSize")]];
		[self setTitleColor:[UIColor betterAlarmRGBAColorFromHexString:[preferences valueForKey:keyFor(@"SecondaryTextColor")]] forState:UIControlStateNormal];
		self.titleLabel.alpha = (secondaryHeight == 0) ? 0 : 1;
		[self.titleLabel sizeToFit];

		// On modern devices it's a CSModalButton, on older devices like the SE it's just a UI button.
		if ([self isKindOfClass:%c(CSModalButton)]) {
			((CSModalButton *)self).visualEffect = nil;
		} else {
			// For some reason we have to manually adjust the frame here
			self.titleLabel.frame = CGRectMake((self.frame.size.width / 2) - (self.titleLabel.frame.size.width / 2), (self.frame.size.height / 2) - (self.titleLabel.frame.size.height / 2), self.titleLabel.frame.size.width, self.titleLabel.frame.size.height);
		}
		
		UIColor *backgroundColor = [UIColor betterAlarmRGBAColorFromHexString:[preferences valueForKey:keyFor(@"SecondaryBackgroundColor")]];
		CGFloat alpha = 0.0;
		[backgroundColor getRed:nil green:nil blue:nil alpha:&alpha];

		if (alpha < 1 && !self.betterAlarmBlurView) {
			self.backgroundColor = UIColor.clearColor;

			UIBlurEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
			UIVisualEffectView *blurEffectView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
			blurEffectView.frame = CGRectMake(0, 0, self.frame.size.width, self.frame.size.height + 1);
			blurEffectView.backgroundColor = backgroundColor;
			blurEffectView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
			blurEffectView.userInteractionEnabled = NO;

			[self insertSubview:blurEffectView belowSubview:self.titleLabel];

			self.betterAlarmBlurView = blurEffectView;
		} else {
			self.backgroundColor = backgroundColor;
		}

	} else if (isAlarmWithoutSnooze) {
		// This is a primary button, but we need the settings for the secondary (AKA stop) button
		self.layer.cornerRadius = 0;
		self.superview.frame = CGRectMake(0, 0, kDEVICEWIDTH, primaryHeight);
		self.frame = CGRectMake(0, 0, kDEVICEWIDTH, primaryHeight);

		if ([[preferences objectForKey:keyFor(@"SecondaryTextSize")] isEqual:@""]) [preferences removeObjectForKey:keyFor(@"SecondaryTextSize")];

		self.titleLabel.center = self.center;
		self.titleLabel.font = [UIFont systemFontOfSize:[preferences floatForKey:keyFor(@"SecondaryTextSize")]];
		[self setTitleColor:[UIColor betterAlarmRGBAColorFromHexString:[preferences valueForKey:keyFor(@"SecondaryTextColor")]] forState:UIControlStateNormal];
		[self.titleLabel sizeToFit];

		UIColor *backgroundColor = [UIColor betterAlarmRGBAColorFromHexString:[preferences valueForKey:keyFor(@"SecondaryBackgroundColor")]];
		CGFloat alpha = 0.0;
		[backgroundColor getRed:nil green:nil blue:nil alpha:&alpha];

		if (alpha < 1 && !self.betterAlarmBlurView) {
			self.backgroundColor = UIColor.clearColor;

			UIBlurEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
			UIVisualEffectView *blurEffectView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
			blurEffectView.frame = CGRectMake(0, 0, self.frame.size.width, self.frame.size.height + 1);
			blurEffectView.backgroundColor = backgroundColor;
			blurEffectView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
			blurEffectView.userInteractionEnabled = NO;

			[self insertSubview:blurEffectView belowSubview:self.titleLabel];

			self.betterAlarmBlurView = blurEffectView;
		} else {
			self.backgroundColor = backgroundColor;
		}
	}
}
%end

%hook CSFullscreenNotificationViewController

- (void)_handleAction:(NCNotificationAction *)action withName:(id)name {

	if (![preferences boolForKey:@"enabled"]) {
		%orig;
		return;
	}
	
	if ([preferences boolForKey:keyFor(@"SmartSnooze")]) {
		if ([action.identifier isEqual:@"MTAlarmSnoozeAction"]) {
			if (snoozeCount >= [preferences floatForKey:@"alarmSmartSnoozeAmount"]) {
				// Block snoozing via hardware buttons when no snooze left
				return;
			}

			snoozeCount++;
			alarmId = self.notificationRequest.notificationIdentifier;
		} else if ([action.identifier isEqual:@"MTAlarmDismissAction"]) {
			snoozeCount = 0;
		}
	}

	%orig;

	isAlarmActive = NO;
	clearScreen(self.view, NO);
}

- (void)loadView {
	%orig;

	currentCategory = nil;
	if (self.notificationRequest && [self.notificationRequest.sectionIdentifier isEqual:@"com.apple.mobiletimer"]) {
		currentCategory = self.notificationRequest.categoryIdentifier;

		if ([currentCategory isEqual:@"MTAlarmCategory"] || [currentCategory isEqual:@"MTAlarmNoSnoozeCategory"] || [currentCategory isEqual:@"MTWakeUpAlarmCategory"]) {
			isAlarmActive = YES;
		}
	}
	
}
%end

%hook SpringBoard
-(BOOL)_handlePhysicalButtonEvent:(UIPressesEvent *)arg1 {
	if (isAlarmActive && arg1 && [arg1 allPresses]) {
		int type = [[[arg1 allPresses] allObjects][0] type];

		if ([preferences boolForKey:@"alarmBlockHardwareButtons"]) {
			if (type == 101 || type == 102 || type == 103 || type == 104) {

				SBBacklightController *backlight = [%c(SBBacklightController) sharedInstance];
				if (!backlight.screenIsOn) {
					// Wake up the screen
					SBLockScreenManager *manager = (SBLockScreenManager *)[%c(SBLockScreenManager) sharedInstance];
					NSDictionary *options = @{ @"SBUIUnlockOptionsTurnOnScreenFirstKey" : [NSNumber numberWithBool:YES] };
					[manager unlockUIFromSource:6 withOptions:options];
				}

				return NO;
			}
		}
	}
	
	return %orig;
}
%end

static void clearScreen(UIView *view, BOOL clear) {
	while (view != nil && ![view isKindOfClass:%c(CSCoverSheetView)]) {
		view = view.superview;
	}

	if (view == nil) return;

	CSCoverSheetView *sheetView = (CSCoverSheetView *)view;

	sheetView.proudLockContainerView.hidden = clear;
	sheetView.teachableMomentsContainerView.hidden = clear;
	sheetView.backgroundView.hidden = clear;
}

static NSString *keyFor(NSString *key) {
	if ([currentCategory isEqual:@"MTAlarmCategory"] || [currentCategory isEqual:@"MTAlarmNoSnoozeCategory"] || [currentCategory isEqual:@"MTWakeUpAlarmCategory"]) return [NSString stringWithFormat:@"alarm%@", key];
	if ([currentCategory isEqual:@"MTTimerCategory"]) return [NSString stringWithFormat:@"timer%@", key];

	return nil;
}