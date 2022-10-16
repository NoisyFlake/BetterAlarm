#import <UIKit/UIKit.h>
#import "QRScanView.h"

@implementation QRScanView

- (instancetype)initWithScanRect:(CGRect)rect {
	self = [super initWithFrame:[UIScreen mainScreen].bounds];
	if (self) {
		self.backgroundColor = UIColor.clearColor;
		_scanRect = rect;

        _statusLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, rect.size.width, 20)];
        _statusLabel.center = CGPointMake(self.frame.size.width / 2, rect.origin.y - 25);
        _statusLabel.textAlignment = NSTextAlignmentCenter;
        _statusLabel.font = [UIFont systemFontOfSize:16];
		_statusLabel.backgroundColor = UIColor.clearColor;
		_statusLabel.textColor = UIColor.whiteColor;
		_statusLabel.text = @"Scan QR Code:";

        [self addSubview:_statusLabel];

		_scanBorder = [[UIView alloc] initWithFrame:rect];
		_scanBorder.layer.borderColor = UIColor.whiteColor.CGColor;
		_scanBorder.layer.borderWidth = 1;
		
		[self addSubview:_scanBorder];

		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(scanFailed) name:@"com.noisyflake.betteralarm/scanInvalid" object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(scanSuccessful) name:@"com.noisyflake.betteralarm/scanValid" object:nil];
	}
	return self;
}

-(void)scanSuccessful {
	dispatch_async(dispatch_get_main_queue(), ^{
		_statusLabel.text = @"";
		_scanBorder.layer.borderColor = UIColor.greenColor.CGColor;
	});
}

- (void)scanFailed {
	dispatch_async(dispatch_get_main_queue(), ^{
		// Cancel the previous reset request
		[NSObject cancelPreviousPerformRequestsWithTarget:self];

		_statusLabel.text = @"Code Invalid";
		_scanBorder.layer.borderColor = UIColor.redColor.CGColor;

		[self performSelector:@selector(resetView) withObject:nil afterDelay:1.0];
	});
}

- (void)resetView {
	dispatch_async(dispatch_get_main_queue(), ^{
		_statusLabel.text = @"Scan QR Code:";
		_scanBorder.layer.borderColor = UIColor.whiteColor.CGColor;
	});
}

- (void)drawRect:(CGRect)rect {
	CGContextRef ctx = UIGraphicsGetCurrentContext();

	[[[UIColor blackColor] colorWithAlphaComponent:0.7] setFill];

	CGMutablePathRef screenPath = CGPathCreateMutable();
	CGPathAddRect(screenPath, NULL, self.bounds);

	CGMutablePathRef scanPath = CGPathCreateMutable();
	CGPathAddRect(scanPath, NULL, self.scanRect);

	CGMutablePathRef path = CGPathCreateMutable();
	CGPathAddPath(path, NULL, screenPath);
	CGPathAddPath(path, NULL, scanPath);

	CGContextAddPath(ctx, path);
	CGContextDrawPath(ctx, kCGPathEOFill);

	CGPathRelease(screenPath);
	CGPathRelease(scanPath);
	CGPathRelease(path);
}

@end