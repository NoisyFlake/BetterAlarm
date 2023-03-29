#include "PreferenceHeaders.h"
#import <spawn.h>

@implementation BetterAlarmPreviewController

- (NSArray *)specifiers {
	if (!_specifiers) {
		NSMutableArray *mutableSpecifiers = [[self loadSpecifiersFromPlistName:@"Preview" target:self] mutableCopy];

		NSUserDefaults *preferences = [[NSUserDefaults alloc] initWithSuiteName:@"com.noisyflake.betteralarm"];

		for (PSSpecifier *spec in [mutableSpecifiers reverseObjectEnumerator]) {
			if (!spec.properties[@"isMainToggle"]) {
				if ([[preferences valueForKey:@"alarmAsCarrier"] isEqual:@"disabled"]) [mutableSpecifiers removeObject:spec];
			}

            if ([spec.properties[@"key"] isEqual:@"alarmAsCarrierCustomText"]) {
				if (![preferences boolForKey:@"alarmAsCarrierCustom"]) [mutableSpecifiers removeObject:spec];
			}
		}

		_specifiers = mutableSpecifiers;
	}

	return _specifiers;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    UIBarButtonItem *applyButton = [[UIBarButtonItem alloc] initWithTitle:@"Respring" style:UIBarButtonItemStylePlain target:self action:@selector(respring)];
	self.navigationItem.rightBarButtonItem = applyButton;
}

- (void)setWithReload:(id)value specifier:(PSSpecifier*)specifier {
	[super setPreferenceValue:value specifier:specifier];
	[self reloadSpecifiers];
}

- (void)setCustomText:(id)value specifier:(PSSpecifier*)specifier {
	[super setPreferenceValue:value specifier:specifier];

	if ([value boolValue] == YES) {
		if ([self specifierForID:@"alarmAsCarrierCustomText"] == nil) {
			NSArray *specifiers = [self loadSpecifiersFromPlistName:@"Preview" target:self];
			for (PSSpecifier *spec in specifiers) {
				if ([spec.properties[@"id"] isEqual:@"alarmAsCarrierCustomText"]) {
					[self insertSpecifier:spec afterSpecifierID:@"alarmAsCarrierCustom" animated:YES];
					break;
				}
			}
		}
	} else {
		[self removeSpecifierID:@"alarmAsCarrierCustomText" animated:YES];
	}
}

-(void)respring {
	[self.view endEditing:YES];

	pid_t pid;
	const char* args[] = {"sbreload", NULL};
	posix_spawn(&pid, ROOT_PATH("/usr/bin/sbreload"), NULL, NULL, (char* const*)args, NULL);
}

@end