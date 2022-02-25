@interface QRScanView : UIView
@property (nonatomic, assign) CGRect scanRect;
@property (strong, nonatomic) UILabel *statusLabel;
- (void)setLabelToInvalid;
- (instancetype)initWithScanRect:(CGRect)rect;
@end