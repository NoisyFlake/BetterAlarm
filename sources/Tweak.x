#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import "QRScanView.h"
#import "Headers.h"
#import "ColorUtils.h"
#include <dlfcn.h>

NSUserDefaults *preferences;

BOOL isAlarmActive = NO;
BOOL isTimerActive = NO;
BOOL isQRScanActive = NO;
NSString *currentCategory = nil;
NSString *alarmId = nil;
NSInteger snoozeCount = 0;

UIFont *regularFont;
UIFont *emphasizedFont;
BOOL showsNextAlarm = NO;

CSFullscreenNotificationViewController *currentCS;
AVCaptureSession *captureSession;

NCNotificationAction *stopAction;
id stopName;

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
		formatter.dateStyle = NSDateFormatterNoStyle;
		formatter.timeStyle = NSDateFormatterShortStyle;

		if ([[preferences objectForKey:keyFor(@"ClockTextSize")] isEqual:@""]) [preferences removeObjectForKey:keyFor(@"ClockTextSize")];

		self.currentTime = [[UILabel alloc] initWithFrame:CGRectZero];
		self.currentTime.text = [formatter stringFromDate:[NSDate date]];
		self.currentTime.textAlignment = NSTextAlignmentCenter;
		self.currentTime.font = [UIFont systemFontOfSize:[preferences floatForKey:keyFor(@"ClockTextSize")]];
		self.currentTime.textColor = [UIColor colorFromP3String:[preferences valueForKey:keyFor(@"ClockTextColor")]];
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
		self.alarmTitle.textColor = [UIColor colorFromP3String:[preferences valueForKey:keyFor(@"TitleTextColor")]];
		[self.alarmTitle sizeToFit];
		self.alarmTitle.frame = CGRectMake(0, primaryHeight + labelDistance, kDEVICEWIDTH, self.alarmTitle.frame.size.height);

		[self addSubview:self.alarmTitle];
	}

	dispatch_async(dispatch_get_main_queue(), ^{
		clearScreen(self, YES);
	});
}
%end

%hook UIButton
%property (retain, nonatomic) UIView * betterAlarmBlurView;
%property (retain, nonatomic) CAGradientLayer * betterAlarmGradientLayer;

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
		[self setTitleColor:[UIColor colorFromP3String:[preferences valueForKey:keyFor(@"PrimaryTextColor")]] forState:UIControlStateNormal];
		[self.titleLabel sizeToFit];

		UIColor *backgroundColor = [UIColor colorFromP3String:[preferences valueForKey:keyFor(@"PrimaryBackgroundColor")]];
		CGFloat alpha = 0.0;
		[backgroundColor getRed:nil green:nil blue:nil alpha:&alpha];

		self.backgroundColor = alpha < 1 ? UIColor.clearColor : backgroundColor;

		if (alpha < 1 && !self.betterAlarmBlurView) {
			UIBlurEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
			UIVisualEffectView *blurEffectView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
			blurEffectView.frame = CGRectMake(0, 0, self.frame.size.width, self.frame.size.height + 1);
			blurEffectView.backgroundColor = backgroundColor;
			blurEffectView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
			blurEffectView.userInteractionEnabled = NO;

			[self insertSubview:blurEffectView belowSubview:self.titleLabel];

			self.betterAlarmBlurView = blurEffectView;
		}

		if ([preferences boolForKey:keyFor(@"PrimaryGradient")] && !self.betterAlarmGradientLayer) {
			CAGradientLayer *gradient = [CAGradientLayer layer];
			gradient.colors = [NSArray arrayWithObjects: (id)[backgroundColor betterAlarmLighterColor].CGColor, (id)backgroundColor.CGColor, nil];
			gradient.frame = self.bounds;
			gradient.type = kCAGradientLayerRadial;

			gradient.startPoint = CGPointMake(0.5, 0.5);
			if (self.bounds.size.width < self.bounds.size.height) {
				gradient.endPoint = CGPointMake(0.5 + 0.5 * (self.bounds.size.height / self.bounds.size.width), 1);
			} else {
				gradient.endPoint = CGPointMake(1, 0.5 + 0.5 * (self.bounds.size.width / self.bounds.size.height));
			}

			if (self.betterAlarmBlurView) {
				[[self.betterAlarmBlurView layer] insertSublayer:gradient atIndex:0];
			} else {
				[[self layer] insertSublayer:gradient atIndex:0];
			}

			self.betterAlarmGradientLayer = gradient;
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
		[self setTitleColor:[UIColor colorFromP3String:[preferences valueForKey:keyFor(@"SecondaryTextColor")]] forState:UIControlStateNormal];
		self.titleLabel.alpha = (secondaryHeight == 0) ? 0 : 1;
		[self.titleLabel sizeToFit];

		// On modern devices it's a CSModalButton, on older devices like the SE it's just a UI button.
		if ([self isKindOfClass:%c(CSModalButton)]) {
			((CSModalButton *)self).visualEffect = nil;
		} else {
			// For some reason we have to manually adjust the frame here
			self.titleLabel.frame = CGRectMake((self.frame.size.width / 2) - (self.titleLabel.frame.size.width / 2), (self.frame.size.height / 2) - (self.titleLabel.frame.size.height / 2), self.titleLabel.frame.size.width, self.titleLabel.frame.size.height);
		}
		
		UIColor *backgroundColor = [UIColor colorFromP3String:[preferences valueForKey:keyFor(@"SecondaryBackgroundColor")]];
		CGFloat alpha = 0.0;
		[backgroundColor getRed:nil green:nil blue:nil alpha:&alpha];

		self.backgroundColor = alpha < 1 ? UIColor.clearColor : backgroundColor;

		if (alpha < 1 && !self.betterAlarmBlurView) {
			UIBlurEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
			UIVisualEffectView *blurEffectView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
			blurEffectView.frame = CGRectMake(0, 0, self.frame.size.width, self.frame.size.height + 1);
			blurEffectView.backgroundColor = backgroundColor;
			blurEffectView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
			blurEffectView.userInteractionEnabled = NO;

			[self insertSubview:blurEffectView belowSubview:self.titleLabel];

			self.betterAlarmBlurView = blurEffectView;
		}

		if ([preferences boolForKey:keyFor(@"SecondaryGradient")] && !self.betterAlarmGradientLayer) {
			CAGradientLayer *gradient = [CAGradientLayer layer];
			gradient.colors = [NSArray arrayWithObjects: (id)[backgroundColor betterAlarmLighterColor].CGColor, (id)backgroundColor.CGColor, nil];
			gradient.frame = self.bounds;
			gradient.type = kCAGradientLayerRadial;

			gradient.startPoint = CGPointMake(0.5, 0.5);
			if (self.bounds.size.width < self.bounds.size.height) {
				gradient.endPoint = CGPointMake(0.5 + 0.5 * (self.bounds.size.height / self.bounds.size.width), 1);
			} else {
				gradient.endPoint = CGPointMake(1, 0.5 + 0.5 * (self.bounds.size.width / self.bounds.size.height));
			}

			if (self.betterAlarmBlurView) {
				[[self.betterAlarmBlurView layer] insertSublayer:gradient atIndex:0];
			} else {
				[[self layer] insertSublayer:gradient atIndex:0];
			}

			self.betterAlarmGradientLayer = gradient;
		}

	} else if (isAlarmWithoutSnooze) {
		// This is a primary button, but we need the settings for the secondary (AKA stop) button
		self.layer.cornerRadius = 0;
		self.superview.frame = CGRectMake(0, 0, kDEVICEWIDTH, primaryHeight);
		self.frame = CGRectMake(0, 0, kDEVICEWIDTH, primaryHeight);

		if ([[preferences objectForKey:keyFor(@"SecondaryTextSize")] isEqual:@""]) [preferences removeObjectForKey:keyFor(@"SecondaryTextSize")];

		self.titleLabel.center = self.center;
		self.titleLabel.font = [UIFont systemFontOfSize:[preferences floatForKey:keyFor(@"SecondaryTextSize")]];
		[self setTitleColor:[UIColor colorFromP3String:[preferences valueForKey:keyFor(@"SecondaryTextColor")]] forState:UIControlStateNormal];
		[self.titleLabel sizeToFit];

		UIColor *backgroundColor = [UIColor colorFromP3String:[preferences valueForKey:keyFor(@"SecondaryBackgroundColor")]];
		CGFloat alpha = 0.0;
		[backgroundColor getRed:nil green:nil blue:nil alpha:&alpha];

		self.backgroundColor = alpha < 1 ? UIColor.clearColor : backgroundColor;

		if (alpha < 1 && !self.betterAlarmBlurView) {
			UIBlurEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
			UIVisualEffectView *blurEffectView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
			blurEffectView.frame = CGRectMake(0, 0, self.frame.size.width, self.frame.size.height + 1);
			blurEffectView.backgroundColor = backgroundColor;
			blurEffectView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
			blurEffectView.userInteractionEnabled = NO;

			[self insertSubview:blurEffectView belowSubview:self.titleLabel];

			self.betterAlarmBlurView = blurEffectView;
		}

		if ([preferences boolForKey:keyFor(@"SecondaryGradient")] && !self.betterAlarmGradientLayer) {
			CAGradientLayer *gradient = [CAGradientLayer layer];
			gradient.colors = [NSArray arrayWithObjects: (id)[backgroundColor betterAlarmLighterColor].CGColor, (id)backgroundColor.CGColor, nil];
			gradient.frame = self.bounds;
			gradient.type = kCAGradientLayerRadial;

			gradient.startPoint = CGPointMake(0.5, 0.5);
			if (self.bounds.size.width < self.bounds.size.height) {
				gradient.endPoint = CGPointMake(0.5 + 0.5 * (self.bounds.size.height / self.bounds.size.width), 1);
			} else {
				gradient.endPoint = CGPointMake(1, 0.5 + 0.5 * (self.bounds.size.width / self.bounds.size.height));
			}

			if (self.betterAlarmBlurView) {
				[[self.betterAlarmBlurView layer] insertSublayer:gradient atIndex:0];
			} else {
				[[self layer] insertSublayer:gradient atIndex:0];
			}

			self.betterAlarmGradientLayer = gradient;
		}
	}
}
%end

%hook CSFullscreenNotificationViewController
%property CGRect scanRect;

- (void)_handleAction:(NCNotificationAction *)action withName:(id)name {

	if (![preferences boolForKey:@"enabled"] || ![self isMemberOfClass:%c(CSFullscreenNotificationViewController)]) {
		%orig;
		return;
	}

	// Save for later use
	stopAction = action;
	stopName = name;

	BOOL wantsAlarmStop = [action.identifier isEqual:@"MTAlarmDismissAction"] || (isAlarmActive && [action.identifier isEqual:@"com.apple.UNNotificationDismissActionIdentifier"]);
	BOOL wantsAlarmSnooze = [action.identifier isEqual:@"MTAlarmSnoozeAction"] || (isAlarmActive && [action.identifier isEqual:@"com.apple.UNNotificationSilenceActionIdentifier"]);

	NSString *confirmation = wantsAlarmStop ? [preferences valueForKey:@"alarmStopConfirmationType"] : wantsAlarmSnooze ? [preferences valueForKey:@"alarmSnoozeConfirmationType"] : @"none";

	if ([confirmation isEqual:@"simple"] || [confirmation isEqual:@"math"]) {
		[self betterAlarmShowAlertFor:action withName:name];
	} else if ([confirmation isEqual:@"qrcode"]) {
		if (!isQRScanActive) {
			[self startQRCapture];
		}
	} else {
		[self _handleOrigAction:action withName:name];
	}

}

%new
- (void)betterAlarmShowAlertFor:(NCNotificationAction *)action withName:(id)name {
	BOOL wantsMath = NO;

	if (([action.identifier isEqual:@"MTAlarmDismissAction"] || [action.identifier isEqual:@"com.apple.UNNotificationDismissActionIdentifier"]) && [[preferences valueForKey:@"alarmStopConfirmationType"] isEqual:@"math"]) {
		wantsMath = YES;
	} else if (([action.identifier isEqual:@"MTAlarmSnoozeAction"] || [action.identifier isEqual:@"com.apple.UNNotificationSilenceActionIdentifier"]) && [[preferences valueForKey:@"alarmSnoozeConfirmationType"] isEqual:@"math"]) {
		wantsMath = YES;
	}

	NSBundle *uiKitBundle = [NSBundle bundleWithIdentifier:@"com.apple.UIKitCore"];

	int number1 = 0;
	int number2 = 0;
	int operator = 0;
	NSString *operatorSign = nil;

	NSString *question = nil;

	if (wantsMath) {
		operator = arc4random_uniform(3);
		operatorSign = operator == 0 ? @"+" : operator == 1 ? @"-" : @"x";

		if (operator == 0) {
			number1 = arc4random_uniform(99) + 1;
			number2 = arc4random_uniform(99) + 1;
		} else if (operator == 1) {
			number1 = arc4random_uniform(99) + 1;
			number2 = arc4random_uniform(number1-1) + 1;
		} else if (operator == 2) {
			number1 = arc4random_uniform(9) + 2;
			number2 = arc4random_uniform(9) + 2;
		}
		question = [NSString stringWithFormat:@"%u %@ %u", number1, operatorSign, number2];
	}

	UIAlertController * alert = [UIAlertController alertControllerWithTitle:[NSString stringWithFormat:@"%@?", action.title ?: @"Stop"] message:question preferredStyle:UIAlertControllerStyleAlert];

	if (wantsMath) {
		[alert addTextFieldWithConfigurationHandler:^(UITextField *textfield) {
			textfield.keyboardType = UIKeyboardTypeNumberPad;
		}];
	}

	// Saving self here is necessary as apparently for some users "self" would be the alertController in the next block
	currentCS = self;

	[alert addAction:[UIAlertAction actionWithTitle:[uiKitBundle localizedStringForKey:@"OK" value:@"" table:nil] style:UIAlertActionStyleDefault handler:^(UIAlertAction * alertAction) {
		if (!wantsMath) {
			[currentCS _handleOrigAction:action withName:name];
		} else {
			NSString *answer = [alert.textFields objectAtIndex:0].text;
			NSString *solution = nil;

			if (operator == 0) {
				solution = [NSString stringWithFormat:@"%d", number1 + number2];
			} else if (operator == 1) {
				solution = [NSString stringWithFormat:@"%d", number1 - number2];
			} else if (operator == 2) {
				solution = [NSString stringWithFormat:@"%d", number1 * number2];
			}

			if ([answer isEqual:solution]) {
				[currentCS _handleOrigAction:action withName:name];
			} else {
				[currentCS betterAlarmShowAlertFor:action withName:name];
			}
		}
	}]];

	[alert addAction:[UIAlertAction actionWithTitle:[uiKitBundle localizedStringForKey:@"Cancel" value:@"" table:nil] style:UIAlertActionStyleCancel handler:nil]];
	[self presentViewController:alert animated:YES completion:nil];
}

%new
- (void)_handleOrigAction:(NCNotificationAction *)action withName:(id)name {
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

	currentCS = nil;

	// %orig;
	_logos_orig$_ungrouped$CSFullscreenNotificationViewController$_handleAction$withName$(self, _cmd, action, name);

	isAlarmActive = NO;
	isTimerActive = NO;

	dispatch_async(dispatch_get_main_queue(), ^{
		clearScreen(self.view, NO);
	});
	
}

- (void)loadView {
	%orig;

	currentCategory = nil;
	if (self.notificationRequest && [self.notificationRequest.sectionIdentifier isEqual:@"com.apple.mobiletimer"]) {
		currentCategory = self.notificationRequest.categoryIdentifier;

		if ([currentCategory isEqual:@"MTAlarmCategory"] || [currentCategory isEqual:@"MTAlarmNoSnoozeCategory"] || [currentCategory isEqual:@"MTWakeUpAlarmCategory"]) {
			isAlarmActive = YES;
		}

		if ([currentCategory isEqual:@"MTTimerCategory"]) {
			isTimerActive = YES;
		}
	}
	
}

%new
- (void)startQRCapture {
	isQRScanActive = YES;

	CGFloat scanRectSize = 200;
	self.scanRect = CGRectMake((self.view.frame.size.width / 2) - (scanRectSize / 2), (self.view.frame.size.height / 2) - (scanRectSize / 2), scanRectSize, scanRectSize);

	captureSession = [[AVCaptureSession alloc] init];
	[captureSession beginConfiguration];

	AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
	NSError *error;
	AVCaptureDeviceInput *deviceInput = [AVCaptureDeviceInput deviceInputWithDevice:device error:&error];
	[captureSession addInput:deviceInput];

	AVCaptureVideoPreviewLayer *previewLayer = [AVCaptureVideoPreviewLayer layerWithSession:captureSession];
	previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
	previewLayer.frame = self.view.frame;
	previewLayer.backgroundColor = UIColor.blackColor.CGColor;
	[self.view.layer addSublayer:previewLayer];

	AVCaptureMetadataOutput *metadataOutput = [[AVCaptureMetadataOutput alloc] init];
	[metadataOutput setMetadataObjectsDelegate:(id)self queue:dispatch_queue_create("com.noisyflake.betteralarm/scanMetadata", DISPATCH_QUEUE_SERIAL)];
	[captureSession addOutput:metadataOutput];
	metadataOutput.metadataObjectTypes = @[AVMetadataObjectTypeQRCode];

	__weak typeof(self) weakSelf = self;
	[[NSNotificationCenter defaultCenter] addObserverForName:AVCaptureSessionDidStartRunningNotification
														object:nil
														queue:[NSOperationQueue currentQueue]
													usingBlock: ^(NSNotification *_Nonnull note) {
		metadataOutput.rectOfInterest = [previewLayer metadataOutputRectOfInterestForRect:weakSelf.scanRect];
	}];

	QRScanView *scanView = [[QRScanView alloc] initWithScanRect:self.scanRect];
	[self.view addSubview:scanView];

	dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INTERACTIVE, 0), ^{
		[captureSession commitConfiguration];
		[captureSession startRunning];
	});
}

%new
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection {
	AVMetadataMachineReadableCodeObject *metadataObject = metadataObjects.firstObject;
	NSString *strValue = metadataObject.stringValue;

	// Prevent this from being called while were trying to stop the scanning
	if (!isQRScanActive) return;

	if ([strValue isEqualToString:@"com.noisyflake.betteralarm/stop"]) {
		isQRScanActive = NO;
		[[NSNotificationCenter defaultCenter] postNotificationName:@"com.noisyflake.betteralarm/scanValid" object:self];
		[captureSession stopRunning];

		dispatch_async(dispatch_get_main_queue(), ^{
			[self _handleOrigAction:stopAction withName:stopName];
		});
	} else {
		[[NSNotificationCenter defaultCenter] postNotificationName:@"com.noisyflake.betteralarm/scanInvalid" object:self];
	}
	
}

%end

%hook SpringBoard
-(BOOL)_handlePhysicalButtonEvent:(UIPressesEvent *)arg1 {
	if (![preferences boolForKey:@"enabled"]) {
		return %orig;
	}

	if (isAlarmActive && arg1 && [arg1 allPresses]) {
		int type = [[[arg1 allPresses] allObjects][0] type];

		BOOL hasStopConfirmation = ![[preferences valueForKey:@"alarmStopConfirmationType"] isEqualToString:@"none"];
		BOOL hasSnoozeConfirmation = ![[preferences valueForKey:@"alarmSnoozeConfirmationType"] isEqualToString:@"none"];

		// Home: 101/105 (OFF)
		// Power: 104 (SNOOZE)
		// VolDown: 103 (SNOOZE)
		// VolUp: 102 (SNOOZE)

		BOOL shouldBlock = (hasStopConfirmation && (type == 101 || type == 105)) || (hasSnoozeConfirmation && (type == 102 || type == 103 || type == 104));

		if (shouldBlock || isQRScanActive) {
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
	
	return %orig;
}
%end

%hook DDNotificationView
-(void)_presentNotification:(id)notification indefinitely:(BOOL)indefinitely {
	%orig;

	returnIfNotEnabled();

	if (isAlarmActive || isTimerActive) {
		[self requestDestruction];
	}
}
%end

%hook SparkAutoUnlockX 
-(BOOL)externalBlocksUnlock { 
	if (isAlarmActive || isTimerActive) {
		return YES;
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

// -------------------- ALARM AS CARRIER ----------------------- //

%group CarrierAlarm

@implementation BetterAlarmStatusBarStringView
-(void)didMoveToWindow {
	[super didMoveToWindow];
	
	UITapGestureRecognizer *singlePress = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleBetterAlarmTap)];
	[self setUserInteractionEnabled:YES];
	[self addGestureRecognizer:singlePress];
}

-(void)applyStyleAttributes:(_UIStatusBarStyleAttributes *)arg1 {
	[super applyStyleAttributes:arg1];

	if (showsNextAlarm) {
		NSMutableAttributedString *attrString = [self.attributedText mutableCopy];
		[attrString addAttribute:NSFontAttributeName value:arg1.emphasizedFont range:NSMakeRange(0, attrString.length)];

		self.attributedText = attrString;
	}
}

-(void)handleBetterAlarmTap {
	if (!showsNextAlarm) return;

	NSBundle *sleepBundle = [NSBundle bundleWithPath:@"/Applications/SleepLockScreen.app"];
	NSBundle *timerFramework = [NSBundle bundleWithIdentifier:@"com.apple.mobiletimer-framework"];

	MTAlarmManager *manager = [[%c(SBScheduledAlarmObserver) sharedInstance] valueForKey:@"_alarmManager"];
	MTAlarm *nextAlarm = manager.cache.nextAlarm;
	NSString *alarmTime = [NSDateFormatter localizedStringFromDate:nextAlarm.nextFireDate dateStyle:NSDateFormatterNoStyle timeStyle:NSDateFormatterShortStyle];

	NSString *title = [NSString stringWithFormat:[sleepBundle localizedStringForKey:@"UPCOMING_ALARM_FORMAT" value:@"%@" table:nil], alarmTime];

	UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil message:title preferredStyle:UIAlertControllerStyleActionSheet];

	UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:[sleepBundle localizedStringForKey:@"ALARM_ALERT_CANCEL" value:@"Cancel" table:nil] style:UIAlertActionStyleCancel handler:^(UIAlertAction * action) {}];
	[alertController addAction:cancelAction];

	UIAlertAction *editAction = [UIAlertAction actionWithTitle:[sleepBundle localizedStringForKey:@"ALARM_ALERT_CHANGE" value:@"Change Alarm" table:nil] style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
		SBLockScreenManager *manager = (SBLockScreenManager *)[%c(SBLockScreenManager) sharedInstance];
		if ([manager isUILocked]) {
			[manager lockScreenViewControllerRequestsUnlock];
		}

		if (nextAlarm.sleepSchedule) {
			[(SpringBoard *)[objc_getClass("SpringBoard") sharedApplication] applicationOpenURL:[NSURL URLWithString:@"clock-sleep-alarm:edit"]];
		} else {
			[(SpringBoard *)[objc_getClass("SpringBoard") sharedApplication] applicationOpenURL:[NSURL URLWithString:@"clock-alarm:default"]];
		}
		
		
    }];
	[alertController addAction:editAction];

	if (nextAlarm.repeats || nextAlarm.sleepSchedule) {
		UIAlertActionStyle style = nextAlarm.sleepSchedule ? UIAlertActionStyleDestructive : UIAlertActionStyleDefault;
		UIAlertAction *skipAction = [UIAlertAction actionWithTitle:[sleepBundle localizedStringForKey:@"ALARM_ALERT_SKIP" value:@"Skip Alarm" table:nil] style:style handler:^(UIAlertAction * action) {
			nextAlarm.keepOffUntilDate = [nextAlarm.nextFireDate dateByAddingTimeInterval:60];
			[manager updateAlarm:nextAlarm];

			dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^(void){
				[self setText:self.originalText];
			});
		}];
		[alertController addAction:skipAction];
	}
	
	if (!nextAlarm.sleepSchedule) {
		UIAlertAction *disableAction = [UIAlertAction actionWithTitle:[timerFramework localizedStringForKey:@"HSPhsP" value:@"Disable Alarm" table:@"AlarmIntents"] style:UIAlertActionStyleDestructive handler:^(UIAlertAction * action) {
			nextAlarm.enabled = NO;
			[manager updateAlarm:nextAlarm];

			dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^(void){
				[self setText:self.originalText];
			});
			
		}];
		[alertController addAction:disableAction];
	}
	
	#pragma clang diagnostic push
	#pragma clang diagnostic ignored "-Wdeprecated-declarations"
	[[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:alertController animated: YES completion: nil];
	#pragma clang diagnostic pop
}

-(void)setText:(NSString *)text {
		showsNextAlarm = NO;

		// Save this so we can call setText later when the user manually disabled the alarm
		if (self.originalText == nil) self.originalText = text;

		if ([[preferences valueForKey:@"alarmAsCarrier"] isEqual:@"alarmTime"] || [[preferences valueForKey:@"alarmAsCarrier"] isEqual:@"timeUntilAlarm"]) {
			MTAlarmManager *manager = [[%c(SBScheduledAlarmObserver) sharedInstance] valueForKey:@"_alarmManager"];
			MTAlarm *nextAlarm = manager.cache.nextAlarm;

			// Create an NSDate that points to the time the alarm can be away at max
			NSDate *now = [[NSDate alloc] init];
			NSDateComponents *dateComponents = [[NSDateComponents alloc] init];
			[dateComponents setHour:[preferences integerForKey:@"alarmAsCarrierMaxTime"]];
			NSCalendar *calendar = [NSCalendar currentCalendar];
			NSDate *maxDate = [calendar dateByAddingComponents:dateComponents toDate:now options:0];

			if (nextAlarm != nil && ([maxDate compare:nextAlarm.nextFireDate] == NSOrderedDescending)) {
				NSString *customText = nil;

				NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
				dateFormatter.timeStyle = NSDateFormatterShortStyle;
				customText = [dateFormatter stringFromDate:nextAlarm.nextFireDate];

				if ([[preferences valueForKey:@"alarmAsCarrier"] isEqual:@"timeUntilAlarm"]) {
					unsigned int unitFlags = NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitDay | NSCalendarUnitMonth;
					NSDateComponents *conversionInfo = [calendar components:unitFlags fromDate:now toDate:nextAlarm.nextFireDate options:0];
					int days = [conversionInfo day];
					int hours = [conversionInfo hour];
					int minutes = [conversionInfo minute];

					if (days < 1) {
						customText = [NSString stringWithFormat:@"%d:%02d", hours, minutes];
					} else {
						customText = [NSString stringWithFormat:@"%dd %dh", days, hours];
					}
				}

				NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:customText];

				// Load the alarm icon and scale / color it
				// UIImage *iconImage = [UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:iconAlarm]]];
				UIImage *iconImage = [UIImage systemImageNamed:@"alarm.fill"];
				iconImage = [iconImage scaleImageToSize:CGSizeMake(emphasizedFont.capHeight ?: 10, emphasizedFont.capHeight ?: 10)];
				iconImage = [iconImage imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];

				// Make an attributed string out of the image
				NSTextAttachment *textAttachment = [[NSTextAttachment alloc] init];
				textAttachment.image = iconImage;
				NSAttributedString *attrStringWithImage = [NSAttributedString attributedStringWithAttachment:textAttachment];

				// Prepend the icon and a space to the string
				[attributedString insertAttributedString:[[NSMutableAttributedString alloc] initWithString:@" "] atIndex:0];
				[attributedString insertAttributedString:attrStringWithImage atIndex:0];

				// Set the bold text here. Usually it gets set in applyStyleAttributes, but after a respring setText gets called after that, therefore overwriting the attributes
				NSDictionary *attributesFromString = [self.attributedText attributesAtIndex:0 longestEffectiveRange:nil inRange:NSMakeRange(0, self.attributedText.length)];
				if (attributesFromString[NSFontAttributeName]) {
					[attributedString addAttribute:NSFontAttributeName value:attributesFromString[NSFontAttributeName] range:NSMakeRange(0, attributedString.length)];
				}

				self.attributedText = attributedString;
				showsNextAlarm = YES;

				return;
			} else if ([preferences boolForKey:@"alarmAsCarrierCustom"] && [preferences valueForKey:@"alarmAsCarrierCustomText"]) {
				self.attributedText = [[NSMutableAttributedString alloc] initWithString:[preferences valueForKey:@"alarmAsCarrierCustomText"]];
				return;
			}
		} 

	[super setText:text];
}

@end
%hook _UIStatusBarCellularItem
-(void)_create_serviceNameView {
	%orig;

	_UIStatusBarStringView *view = [self serviceNameView];
	object_setClass(view, [BetterAlarmStatusBarStringView class]);
}
%end

%hook _UIStatusBarIndicatorItem
-(id)initWithIdentifier:(id)arg1 statusBar:(id)arg2 {
	// Hide the stock alarm icon so that it's not displayed twice in the status bar
	if (([[preferences valueForKey:@"alarmAsCarrier"] isEqual:@"alarmTime"] || [[preferences valueForKey:@"alarmAsCarrier"] isEqual:@"timeUntilAlarm"]) && [self isKindOfClass:%c(_UIStatusBarIndicatorAlarmItem)]) return nil;

	return %orig;
}
%end
%end

%group MediaServerPatch

// Allow background usage of the camera for SpringBoard

// Pre-iOS 16
%hook FigCaptureClientSessionMonitor
-(void)_updateClientStateCondition:(void*)arg1 newValue:(id)arg2  { 
	if ([self.applicationID isEqualToString:@"com.apple.springboard"]) return;
	%orig; 
}
%end

// iOS 16
%hook FigCaptureClientSessionMonitorClient 
-(BOOL)hasBackgroundCameraAccess {
	if ([self.applicationID isEqualToString:@"com.apple.springboard"]) return YES;
	return %orig;
}
%end
%end


%ctor {
	if (![@"SpringBoard" isEqualToString:[NSProcessInfo processInfo].processName]) {
		// We are in mediaserverd
		%init(MediaServerPatch);
		return;
	}

	preferences = [[NSUserDefaults alloc] initWithSuiteName:@"com.noisyflake.betteralarm"];

	[preferences registerDefaults:@{
		@"enabled": @YES,

		@"timerSwapButtons": @YES,
		@"timerSmartSnooze": @NO, // can't be changed via Settings
		@"timerPrimaryPercent": @30,
		@"timerPrimaryBackgroundColor": @"0.28015 0.36935 0.51298 1",
		@"timerPrimaryGradient": @YES,
		@"timerPrimaryTextColor": @"1 1 1 1",
		@"timerPrimaryTextSize": @48,

		@"timerSecondaryBackgroundColor": @"0 0 0 1",
		@"timerSecondaryGradient": @NO,
		@"timerSecondaryTextColor": @"1 1 1 1",
		@"timerSecondaryTextSize": @48,

		@"timerClockTextColor": @"1 1 1 0.75",
		@"timerClockTextSize": @38,
		
		@"timerTitleTextColor": @"1 1 1 0.75",
		@"timerTitleTextSize": @24,

		@"alarmSwapButtons": @NO,
		@"alarmSmartSnooze": @NO,
		@"alarmSmartSnoozeAmount": @3,
		@"alarmPrimaryPercent": @50,
		@"alarmStopConfirmationType": @"none",
		@"alarmSnoozeConfirmationType": @"none",
		@"alarmPrimaryBackgroundColor": @"0.0 0.0 0.0 1.0",
		@"alarmPrimaryGradient": @NO,
		@"alarmPrimaryTextColor": @"1 1 1 1",
		@"alarmPrimaryTextSize": @48,

		@"alarmSecondaryBackgroundColor": @"0.60465 0.16644 0.14586 1",
		@"alarmSecondaryGradient": @YES,
		@"alarmSecondaryTextColor": @"1 1 1 1",
		@"alarmSecondaryTextSize": @48,

		@"alarmClockTextColor": @"1 1 1 0.75",
		@"alarmClockTextSize": @38,
		
		@"alarmTitleTextColor": @"1 1 1 0.75",
		@"alarmTitleTextSize": @24,
		
		@"alarmAsCarrier": @"alarmTime",
		@"alarmAsCarrierMaxTime": @"24",
		@"alarmAsCarrierCustom": @NO,
		@"alarmAsCarrierCustomText": @""
	}];

	%init(_ungrouped);
	if ([[preferences valueForKey:@"alarmAsCarrier"] isEqual:@"alarmTime"] || [[preferences valueForKey:@"alarmAsCarrier"] isEqual:@"timeUntilAlarm"]) {
		%init(CarrierAlarm);
	}
}