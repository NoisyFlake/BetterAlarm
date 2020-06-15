#include "PreferenceHeaders.h"

@implementation BetterAlarmBaseController

- (void)viewDidLayoutSubviews {
	[super viewDidLayoutSubviews];

	self.navigationItem.navigationBar.tintColor = kBETTERALARMCOLOR;

	UITableView *table = [self valueForKey:@"_table"];
	table.separatorStyle = 0;
}

- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];

	if ([self isMemberOfClass:[BetterAlarmRootListController class]] && self.navigationController.viewControllers.count == 1) {
		// Remove the navigationBar tintColor as the user is about to leave our settings area
		self.navigationItem.navigationBar.tintColor = nil;
	}
}

-(long long)tableViewStyle {
	return (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"13.0")) ? 2 : [super tableViewStyle];
}

// -(void)respring {
// 	[self.view endEditing:YES];

// 	pid_t pid;
// 	const char* args[] = {"sbreload", NULL};
// 	posix_spawn(&pid, "/usr/bin/sbreload", NULL, NULL, (char* const*)args, NULL);
// }

// -(void)setWithRespring:(id)value specifier:(PSSpecifier *)specifier {
// 	[self setPreferenceValue:value specifier:specifier];

// 	UIAlertController * alert = [UIAlertController alertControllerWithTitle:@"Respring required" message:@"Changing this option requires a respring. Do you want to respring now?" preferredStyle:UIAlertControllerStyleAlert];

// 	[alert addAction:[UIAlertAction actionWithTitle:@"Yes" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
// 		 [self respring];
// 	}]];

// 	[alert addAction:[UIAlertAction actionWithTitle:@"No" style:UIAlertActionStyleCancel handler:nil]];
// 	[self presentViewController:alert animated:YES completion:nil];
// }

@end
