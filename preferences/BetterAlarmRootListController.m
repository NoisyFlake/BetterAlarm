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

- (void)resetSettings {
	UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Reset Settings"
									message: @"Are you sure you want to reset all settings to the default value?"
									preferredStyle:UIAlertControllerStyleAlert];

	[alert addAction:[UIAlertAction actionWithTitle:@"Yes" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * action) {
		[[NSUserDefaults standardUserDefaults] removePersistentDomainForName:@"com.noisyflake.betteralarm"];

		UIAlertController *success = [UIAlertController alertControllerWithTitle: @"Success" message: @"All settings were reset." preferredStyle:UIAlertControllerStyleAlert];
		[success addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
			[self reload];
		}]];
		[self presentViewController:success animated:YES completion:nil];
	}]];

	[alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];

	[self presentViewController:alert animated:YES completion:nil];
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
	version.text = [NSString stringWithFormat:@"Version %@", PACKAGE_VERSION];

	[header addSubview:tweakName];
	[header addSubview:version];
	[self.table setTableHeaderView:header];
}

@end
