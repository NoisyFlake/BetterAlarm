#include "PreferenceHeaders.h"

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

@end