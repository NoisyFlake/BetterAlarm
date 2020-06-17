#import "Headers.h"
#import "ColorUtils.h"

NSUserDefaults *preferences;
NSString *currentCategory = nil; // Possible values: MTAlarmCategory, MTTimerCategory

%ctor {
	// [[NSUserDefaults standardUserDefaults] removePersistentDomainForName:@"com.noisyflake.betteralarm"];
	preferences = [[NSUserDefaults alloc] initWithSuiteName:@"com.noisyflake.betteralarm"];

	[preferences registerDefaults:@{
		@"enabled": @YES,

		@"timerSwapButtons": @YES,
		@"timerPrimaryPercent": @30,
		@"timerPrimaryBackgroundColor": @"#FB7B42:1.00",
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
		@"alarmPrimaryPercent": @70,
		@"alarmPrimaryBackgroundColor": @"#000000:0.00",
		@"alarmPrimaryTextColor": @"#FFFFFF:1.00",
		@"alarmPrimaryTextSize": @48,

		@"alarmSecondaryBackgroundColor": @"#FB7B42:1.00",
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

	// This works because [CSModalButton layoutSubviews] is called before this method
	CGFloat primaryHeight = [preferences boolForKey:keyFor(@"SwapButtons")] ? self.primaryActionButton.superview.frame.origin.y : self.primaryActionButton.superview.frame.size.height;

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

%hook CSModalButton
%property (retain, nonatomic) UIView * blurView;

- (void)layoutSubviews {
	%orig;

	returnIfNotEnabled();
	
	UIViewController *controller = self._viewControllerForAncestor;
	if (![controller.view isKindOfClass:%c(CSFullscreenNotificationView)]) return;

	CSFullscreenNotificationView *mainView = (CSFullscreenNotificationView *)controller.view;

	CGFloat primaryHeight = [[UIScreen mainScreen] bounds].size.height * ((100 - [preferences floatForKey:keyFor(@"PrimaryPercent")]) / 100);
	CGFloat secondaryHeight = [[UIScreen mainScreen] bounds].size.height - primaryHeight;

	if (self == mainView.primaryActionButton) {

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
		self.titleLabel.textColor = [UIColor betterAlarmRGBAColorFromHexString:[preferences valueForKey:keyFor(@"PrimaryTextColor")]];
		[self.titleLabel sizeToFit];

		UIColor *backgroundColor = [UIColor betterAlarmRGBAColorFromHexString:[preferences valueForKey:keyFor(@"PrimaryBackgroundColor")]];
		CGFloat alpha = 0.0;
		[backgroundColor getRed:nil green:nil blue:nil alpha:&alpha];

		if (alpha < 1 && !self.blurView) {
			self.backgroundColor = UIColor.clearColor;

			UIBlurEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
			UIVisualEffectView *blurEffectView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
			blurEffectView.frame = self.bounds;
			blurEffectView.backgroundColor = backgroundColor;
			blurEffectView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
			blurEffectView.userInteractionEnabled = NO;

			[self insertSubview:blurEffectView belowSubview:self.titleLabel];

			self.blurView = blurEffectView;
		} else {
			self.backgroundColor = backgroundColor;
		}

	} else if (self == mainView.secondaryActionButton) {

		self.layer.cornerRadius = 0;
		if ([preferences boolForKey:keyFor(@"SwapButtons")]) {
			self.frame = CGRectMake(0, 0, kDEVICEWIDTH, secondaryHeight);
		} else {
			self.frame = CGRectMake(0, primaryHeight, kDEVICEWIDTH, secondaryHeight);
		}

		if ([[preferences objectForKey:keyFor(@"SecondaryTextSize")] isEqual:@""]) [preferences removeObjectForKey:keyFor(@"SecondaryTextSize")];

		self.visualEffect = nil;
		self.titleLabel.font = [UIFont systemFontOfSize:[preferences floatForKey:keyFor(@"SecondaryTextSize")]];
		self.titleLabel.textColor = [UIColor betterAlarmRGBAColorFromHexString:[preferences valueForKey:keyFor(@"SecondaryTextColor")]];
		[self.titleLabel sizeToFit];
		
		UIColor *backgroundColor = [UIColor betterAlarmRGBAColorFromHexString:[preferences valueForKey:keyFor(@"SecondaryBackgroundColor")]];
		CGFloat alpha = 0.0;
		[backgroundColor getRed:nil green:nil blue:nil alpha:&alpha];

		if (alpha < 1 && !self.blurView) {
			self.backgroundColor = UIColor.clearColor;

			UIBlurEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
			UIVisualEffectView *blurEffectView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
			blurEffectView.frame = self.bounds;
			blurEffectView.backgroundColor = backgroundColor;
			blurEffectView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
			blurEffectView.userInteractionEnabled = NO;

			[self insertSubview:blurEffectView belowSubview:self.titleLabel];

			self.blurView = blurEffectView;
		} else {
			self.backgroundColor = backgroundColor;
		}

	}
}
%end

%hook CSFullscreenNotificationViewController
- (void)_handleAction:(id)action withName:(id)name {
	%orig;

	returnIfNotEnabled();

	clearScreen(self.view, NO);
}

- (void)loadView {
	%orig;

	currentCategory = nil;
	if (self.notificationRequest && [self.notificationRequest.sectionIdentifier isEqual:@"com.apple.mobiletimer"]) {
		currentCategory = self.notificationRequest.categoryIdentifier;
	}
	
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
	if ([currentCategory isEqual:@"MTAlarmCategory"]) return [NSString stringWithFormat:@"alarm%@", key];
	if ([currentCategory isEqual:@"MTTimerCategory"]) return [NSString stringWithFormat:@"timer%@", key];

	return nil;
}