#import "Headers.h"

NSUserDefaults *preferences;
CGFloat primaryPercent = 80;

%ctor {
	preferences = [[NSUserDefaults alloc] initWithSuiteName:@"com.noisyflake.betteralarm"];

	[preferences registerDefaults:@{
		@"enabled": @YES,
	}];
}

%hook CSFullscreenNotificationView
%property (retain, nonatomic) UILabel * currentTime;
%property (retain, nonatomic) UILabel * alarmTitle;

-(void)didMoveToWindow {
	%orig;

	returnIfNotEnabled();

	CGFloat primaryHeight = [[UIScreen mainScreen] bounds].size.height * (primaryPercent / 100);
	CGFloat width = [[UIScreen mainScreen] bounds].size.width;

	CGFloat labelHeight = 38;
	CGFloat labelDistance = 15;

	if (!self.currentTime) {
		NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
		NSTimeZone *zone = [NSTimeZone localTimeZone];
		[formatter setTimeZone:zone];
		[formatter setDateFormat:@"HH:mm"];

		self.currentTime = [[UILabel alloc] initWithFrame:CGRectMake(0, primaryHeight - labelDistance - labelHeight, width, labelHeight)];
		self.currentTime.text = [formatter stringFromDate:[NSDate date]];
		self.currentTime.font = [UIFont systemFontOfSize:38];
		self.currentTime.textColor = [UIColor.whiteColor colorWithAlphaComponent:0.5];
		self.currentTime.textAlignment = NSTextAlignmentCenter;
		self.currentTime.numberOfLines = 0;

		[self addSubview:self.currentTime];
	}

	if (!self.alarmTitle) {
		self.titleLabel.alpha = 0; // hide the original label

		self.alarmTitle = [[UILabel alloc] initWithFrame:CGRectMake(0, primaryHeight + labelDistance, width, labelHeight)];
		self.alarmTitle.text = self.titleLabel.text;
		self.alarmTitle.font = [UIFont systemFontOfSize:24];
		self.alarmTitle.textColor = [UIColor.whiteColor colorWithAlphaComponent:0.5];
		self.alarmTitle.textAlignment = NSTextAlignmentCenter;
		self.alarmTitle.numberOfLines = 0;

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

	CGFloat primaryHeight = [[UIScreen mainScreen] bounds].size.height * (primaryPercent / 100);
	CGFloat secondaryHeight = [[UIScreen mainScreen] bounds].size.height - primaryHeight;
	CGFloat width = [[UIScreen mainScreen] bounds].size.width;

	if (self == mainView.primaryActionButton) {

		self.layer.cornerRadius = 0;
		self.frame = CGRectMake(0, 0, width, primaryHeight);
		self.superview.frame = self.frame;
		self.backgroundColor = [UIColor colorWithRed: 0.42 green: 0.18 blue: 0.24 alpha: 1.00];
		self.titleLabel.center = self.center;
		self.titleLabel.font = [UIFont systemFontOfSize:48];

		// if (!self.blurView) {

		// 	UIBlurEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
		// 	UIVisualEffectView *blurEffectView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
		// 	//always fill the view
		// 	blurEffectView.frame = self.bounds;
		// 	blurEffectView.backgroundColor = [UIColor colorWithRed: 0.37 green: 0.13 blue: 0.16 alpha: 0.5];
		// 	blurEffectView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
		// 	blurEffectView.userInteractionEnabled = NO;

		// 	[self insertSubview:blurEffectView belowSubview:self.titleLabel];

		// 	self.blurView = blurEffectView;
		// }

	} else if (self == mainView.secondaryActionButton) {

		self.layer.cornerRadius = 0;
		self.frame = CGRectMake(0, primaryHeight, width, secondaryHeight);
		self.backgroundColor = UIColor.clearColor;
		self.titleLabel.font = [UIFont systemFontOfSize:48];
		self.visualEffect = nil;

		if (!self.blurView) {

			UIBlurEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
			UIVisualEffectView *blurEffectView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
			//always fill the view
			blurEffectView.frame = self.bounds;
			blurEffectView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
			blurEffectView.userInteractionEnabled = NO;

			[self insertSubview:blurEffectView belowSubview:self.titleLabel];

			self.blurView = blurEffectView;
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
%end

static void clearScreen(UIView *view, BOOL clear) {
	while (view != nil && ![view isKindOfClass:%c(CSCoverSheetView)]) {
		view = view.superview;
	}

	if (view == nil) return;

	CSCoverSheetView *sheetView = (CSCoverSheetView *)view;

	sheetView.proudLockContainerView.hidden = clear;
	sheetView.teachableMomentsContainerView.hidden = clear;
}