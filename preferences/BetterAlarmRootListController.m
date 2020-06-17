#include "PreferenceHeaders.h"

@implementation BetterAlarmRootListController

- (NSArray *)specifiers {
	if (!_specifiers) {
		_specifiers = [self loadSpecifiersFromPlistName:@"Root" target:self];
	}

	return _specifiers;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self setupHeader];
}

- (void)setupHeader {
	UIView *header = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 122)];

	UILabel *tweakName = [[UILabel alloc] initWithFrame:CGRectMake(0, 30, self.view.bounds.size.width, 40)];
	[tweakName layoutIfNeeded];
	tweakName.numberOfLines = 1;
	tweakName.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
	tweakName.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:34.0f];
	tweakName.textColor = kBETTERALARMCOLOR;
	tweakName.textAlignment = NSTextAlignmentCenter;

	NSMutableAttributedString *attrString = [[NSMutableAttributedString alloc] initWithString:@"betterAlarm"];
	[attrString beginEditing];
	[attrString addAttribute:NSFontAttributeName
				value:[UIFont fontWithName:@"HelveticaNeue" size:34.0f]
				range:NSMakeRange(0, 6)];

	[attrString endEditing];
	tweakName.attributedText = attrString;

	UILabel *version = [[UILabel alloc] initWithFrame:CGRectMake(0, 70, self.view.bounds.size.width, 15)];
	version.numberOfLines = 1;
	version.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
	version.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:13.0f];
	version.textColor = UIColor.systemGrayColor;
	version.textAlignment = NSTextAlignmentCenter;
	version.text = @"Version unknown";
	version.alpha = 0;

	[header addSubview:tweakName];
	[header addSubview:version];
	[self.table setTableHeaderView:header];

	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
		NSPipe *pipe = [NSPipe pipe];

		NSTask *task = [[NSTask alloc] init];
		task.arguments = @[@"-c", @"dpkg -s com.noisyflake.betteralarm | grep -i version | cut -d' ' -f2"];
		task.launchPath = @"/bin/sh";
		[task setStandardOutput: pipe];
		[task launch];
		[task waitUntilExit];

		NSFileHandle *file = [pipe fileHandleForReading];
		NSData *output = [file readDataToEndOfFile];
		NSString *outputString = [[NSString alloc] initWithData:output encoding:NSUTF8StringEncoding];
		[file closeFile];

		dispatch_async(dispatch_get_main_queue(), ^(void){
			// Update label on the main queue
			if ([outputString length] > 0) {
				version.text = [NSString stringWithFormat:@"Version %@", outputString];
			}

			[UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
				version.alpha = 1;
			} completion:nil];
		});
	});
}

@end
