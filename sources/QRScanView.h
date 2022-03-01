@interface QRScanView : UIView
@property (nonatomic, assign) CGRect scanRect;
@property (strong, nonatomic) UILabel *statusLabel;
@property (strong, nonatomic) UIView *scanBorder;
- (void)scanSuccessful;
- (void)scanFailed;
- (void)resetView;
- (instancetype)initWithScanRect:(CGRect)rect;
@end