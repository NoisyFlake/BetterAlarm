#include "PreferenceHeaders.h"

@implementation BetterAlarmQRController

- (NSArray *)specifiers {
	if (!_specifiers) {
		_specifiers = [self loadSpecifiersFromPlistName:@"QR" target:self];
	}

	return _specifiers;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

	UIBarButtonItem *testButton = [[UIBarButtonItem alloc] initWithTitle:@"Save" style:UIBarButtonItemStylePlain target:self action:@selector(saveImage)];
	self.navigationItem.rightBarButtonItem = testButton;

    [self setupHeader];
}

- (void)setupHeader {
	UIImage *image = [[UIImage alloc] initWithContentsOfFile:ROOT_PATH_NS_VAR(@"/Library/PreferenceBundles/BetterAlarm.bundle/qrcode.png")];

	CGFloat size = self.view.bounds.size.width - 30;
    UIView *header = [[UIView alloc] initWithFrame:CGRectMake(0, 0, size, size + 50)];
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(15, 5, size, size + 50)];
    imageView.contentMode = UIViewContentModeScaleAspectFit;
    [imageView setImage:image];

    [header addSubview:imageView];

	// Ugly workaround for devices where it whould overlap the selector
	header.layer.zPosition = -1;

    [self.table setTableHeaderView:header];
}

-(void)saveImage{
	UIImage *image = [[UIImage alloc] initWithContentsOfFile:ROOT_PATH_NS_VAR(@"/Library/PreferenceBundles/BetterAlarm.bundle/qrcode.png")];
	UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil);

	UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Image saved"
									message: @"QR code was saved to Photos app"
									preferredStyle:UIAlertControllerStyleAlert];

		[alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];

		[self presentViewController:alert animated:YES completion:nil];
}

@end