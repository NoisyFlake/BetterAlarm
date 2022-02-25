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
		
		[self resetLabel];
        [self addSubview:_statusLabel];

		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(setLabelToInvalid) name:@"com.noisyflake.betteralarm/scanInvalid" object:nil];
	}
	return self;
}

- (void)setLabelToInvalid {
	

	dispatch_async(dispatch_get_main_queue(), ^{
		// Cancel the previous reset request
		[NSObject cancelPreviousPerformRequestsWithTarget:self];

		_statusLabel.text = @"Code Invalid";
		_statusLabel.textColor = UIColor.orangeColor;

		[self performSelector:@selector(resetLabel) withObject:nil afterDelay:1.0];
	});
}

- (void)resetLabel {
	dispatch_async(dispatch_get_main_queue(), ^{
		_statusLabel.text = @"Scan QR Code:";
		_statusLabel.textColor = UIColor.whiteColor;
	});
}

- (void)drawRect:(CGRect)rect {
	CGContextRef ctx = UIGraphicsGetCurrentContext();

	[[[UIColor blackColor] colorWithAlphaComponent:0.5] setFill];

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