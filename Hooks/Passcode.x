#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import "../Shared/LGLiveBackdropView.h"
#import "../Shared/LGGlassKit.h"
#import "../Shared/LGSharedSupport.h"
#import "../LGFramework/LGButtonView.h"
#import <objc/runtime.h>
#import <objc/message.h>
#import <dlfcn.h>

@interface TPNumberPadButton : UIControl
@property (retain) UIView *circleView;
- (CALayer *)glyphLayer;
- (CALayer *)highlightedGlyphLayer;
@end

@interface SBPasscodeNumberPadButton : TPNumberPadButton
@end

@interface TPNumberPad : UIControl
@property (retain) NSArray *buttons;
@end

@interface SBNumberPadWithDelegate : TPNumberPad
- (UIView *)buttonForPoint:(CGPoint)point forEvent:(UIEvent *)event;
- (BOOL)touchAtPoint:(CGPoint)point isCloseToButton:(UIView *)button;
@end

@interface CSScrollView : UIScrollView
@end

static const CGFloat kPCRestDarkTint        = 0.12;
static const CGFloat kPCBackgroundDarkTint  = 0.2;

static void *kPCGlassKey          = &kPCGlassKey;
static void *kPCVibranceKey       = &kPCVibranceKey;
static void *kPCExposureKey       = &kPCExposureKey;
static void *kPCTintKey           = &kPCTintKey;
static void *kPCBgTintKey         = &kPCBgTintKey;
static void *kPCHostKey           = &kPCHostKey;
static void *kPCHighlightedKey    = &kPCHighlightedKey;
static void *kPCBgColorKey        = &kPCBgColorKey;
static void *kPCBgAlphaKey        = &kPCBgAlphaKey;
static void *kPCBgOpaqueKey       = &kPCBgOpaqueKey;
static void *kPCTouchStartKey     = &kPCTouchStartKey;
static void *kPCIsPressedKey      = &kPCIsPressedKey;
static void *kPCTouchDownTimeKey  = &kPCTouchDownTimeKey;
static void *kPCTouchCycleIdKey   = &kPCTouchCycleIdKey;
static void *kPCBlockerGestureKey = &kPCBlockerGestureKey;
static void *kPCActiveButtonKey   = &kPCActiveButtonKey;

@interface LGPasscodeVibranceView : UIView
- (void)applyFilters;
@end

@implementation LGPasscodeVibranceView {
    NSString *_groupName;
    BOOL _configured;
}

+ (Class)layerClass {
    return NSClassFromString(@"CABackdropLayer") ?: [CALayer class];
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _groupName = [NSString stringWithFormat:@"dylv.liquidpass.vib.%p.%u", self, arc4random()];
        self.userInteractionEnabled = NO;
        self.backgroundColor = [UIColor clearColor];
        self.opaque = NO;
        self.clipsToBounds = YES;
        self.layer.cornerCurve = kCACornerCurveCircular;
        self.layer.cornerRadius = frame.size.width * 0.5;
        self.layer.masksToBounds = YES;
        [self applyFilters];
    }
    return self;
}

- (void)didMoveToWindow {
    [super didMoveToWindow];
    [self applyFilters];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    [self applyFilters];
}

- (void)applyFilters {
    CALayer *layer = self.layer;
    Class backdropCls = NSClassFromString(@"CABackdropLayer");
    if (!backdropCls || ![layer isKindOfClass:backdropCls]) return;

    @try {
        if (!_configured) {
            [layer setValue:@NO forKey:@"layerUsesCoreImageFilters"];
            [layer setValue:@NO forKey:@"windowServerAware"];
            [layer setValue:_groupName forKey:@"groupName"];
            [layer setValue:@"dylv.liquidglass" forKey:@"groupNamespace"];
            [layer setValue:@YES forKey:@"ignoresScreenClip"];
            [layer setValue:@(1.0) forKey:@"scale"];
            _configured = YES;
        }

        Class filterCls = NSClassFromString(@"CAFilter");
        if (!filterCls) return;

        NSMutableArray *filters = [NSMutableArray array];

        id satFilter = ((id (*)(Class, SEL, NSString *))objc_msgSend)(
            filterCls, NSSelectorFromString(@"filterWithType:"), @"colorSaturate");
        if (satFilter) {
            @try { [satFilter setValue:@(1.85) forKey:@"inputAmount"]; } @catch (...) {}
            [filters addObject:satFilter];
        }

        id contrastFilter = ((id (*)(Class, SEL, NSString *))objc_msgSend)(
            filterCls, NSSelectorFromString(@"filterWithType:"), @"colorContrast");
        if (contrastFilter) {
            @try { [contrastFilter setValue:@(1.06) forKey:@"inputAmount"]; } @catch (...) {}
            [filters addObject:contrastFilter];
        }

        layer.filters = filters;
    } @catch (NSException *e) {}
}

@end

@interface LGPasscodeExposureView : UIView
- (void)applyFilters;
@end

@implementation LGPasscodeExposureView {
    NSString *_groupName;
    BOOL _configured;
}

+ (Class)layerClass {
    return NSClassFromString(@"CABackdropLayer") ?: [CALayer class];
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _groupName = [NSString stringWithFormat:@"dylv.liquidpass.exp.%p.%u", self, arc4random()];
        self.userInteractionEnabled = NO;
        self.backgroundColor = [UIColor clearColor];
        self.opaque = NO;
        self.clipsToBounds = YES;
        self.layer.cornerCurve = kCACornerCurveCircular;
        self.layer.cornerRadius = frame.size.width * 0.5;
        self.layer.masksToBounds = YES;
        self.alpha = 0.0;
        [self applyFilters];
    }
    return self;
}

- (void)didMoveToWindow {
    [super didMoveToWindow];
    [self applyFilters];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    [self applyFilters];
}

- (void)applyFilters {
    CALayer *layer = self.layer;
    Class backdropCls = NSClassFromString(@"CABackdropLayer");
    if (!backdropCls || ![layer isKindOfClass:backdropCls]) return;

    @try {
        if (!_configured) {
            [layer setValue:@NO forKey:@"layerUsesCoreImageFilters"];
            [layer setValue:@NO forKey:@"windowServerAware"];
            [layer setValue:_groupName forKey:@"groupName"];
            [layer setValue:@"dylv.liquidglass" forKey:@"groupNamespace"];
            [layer setValue:@YES forKey:@"ignoresScreenClip"];
            [layer setValue:@(1.0) forKey:@"scale"];
            _configured = YES;
        }

        Class filterCls = NSClassFromString(@"CAFilter");
        if (!filterCls) return;

        NSMutableArray *filters = [NSMutableArray array];

        id brightFilter = ((id (*)(Class, SEL, NSString *))objc_msgSend)(
            filterCls, NSSelectorFromString(@"filterWithType:"), @"colorBrightness");
        if (brightFilter) {
            @try { [brightFilter setValue:@(0.36) forKey:@"inputAmount"]; } @catch (...) {}
            [filters addObject:brightFilter];
        }

        id contrastFilter = ((id (*)(Class, SEL, NSString *))objc_msgSend)(
            filterCls, NSSelectorFromString(@"filterWithType:"), @"colorContrast");
        if (contrastFilter) {
            @try { [contrastFilter setValue:@(1.10) forKey:@"inputAmount"]; } @catch (...) {}
            [filters addObject:contrastFilter];
        }

        layer.filters = filters;
    } @catch (NSException *e) {}
}

@end

static BOOL sPasscodeVisible = NO;

static BOOL isPasscodeBackgroundMaterial(UIView *mat) {
    return isExactClass(mat, @"MTMaterialView") &&
           isExactClass(mat.superview, @"CSPasscodeBackgroundView");
}

static void handlePasscodeBackgroundMaterial(UIView *mat) {
    if (!isPasscodeBackgroundMaterial(mat)) return;
    if (!lgHostEnabled(@"Passcode")) return;
    UIView *host = mat.superview;
    UIView *tint = objc_getAssociatedObject(host, kPCBgTintKey);
    if (!tint) {
        tint = [[UIView alloc] initWithFrame:host.bounds];
        tint.userInteractionEnabled = NO;
        tint.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        tint.backgroundColor = [UIColor colorWithWhite:0.0 alpha:kPCBackgroundDarkTint];
        [host addSubview:tint];
        objc_setAssociatedObject(host, kPCBgTintKey, tint, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    tint.frame = host.bounds;
    [host bringSubviewToFront:tint];

    lgSuppressStock(mat, @"Passcode", YES);
    lgTrackGlass(tint, @"Passcode", nil);
}

static UIView *pcButtonHost(UIView *button) {
    if ([button respondsToSelector:@selector(circleView)]) {
        UIView *cv = [(TPNumberPadButton *)button circleView];
        if (cv) return cv;
    }
    UIView *best = nil; CGFloat bestScore = CGFLOAT_MAX;
    for (UIView *sub in button.subviews) {
        if (!isExactClass(sub, @"UIView") || CGRectIsEmpty(sub.bounds)) continue;
        CGFloat w = CGRectGetWidth(sub.bounds), h = CGRectGetHeight(sub.bounds);
        if (w < 40.0 || h < 40.0) continue;
        CGFloat score = fabs(w - h)
                      + fabs(sub.layer.cornerRadius - fmin(w, h) * 0.5)
                      + fabs(sub.alpha - 0.15) * 100.0
                      + sub.subviews.count * 50.0;
        if (score < bestScore) { best = sub; bestScore = score; }
    }
    return best;
}

static void pcUnclipHierarchy(UIView *view) {
    if (!view) return;
    view.clipsToBounds = NO;
    view.layer.masksToBounds = NO;
    view.layer.zPosition = 9999;

    UIView *cur = view.superview;
    while (cur) {
        if ([cur isKindOfClass:[UIWindow class]]) break;
        cur.clipsToBounds = NO;
        cur.layer.masksToBounds = NO;
        cur = cur.superview;
    }
}

static void pcApplyTransform(UIView *button, UIView *host, CGAffineTransform transform) {
    if (host) host.transform = transform;
    if (button) {
        CALayer *glyph = nil;
        CALayer *hlGlyph = nil;
        if ([button respondsToSelector:@selector(glyphLayer)]) {
            glyph = [(TPNumberPadButton *)button glyphLayer];
        }
        if ([button respondsToSelector:@selector(highlightedGlyphLayer)]) {
            hlGlyph = [(TPNumberPadButton *)button highlightedGlyphLayer];
        }
        if (!glyph) {
            @try { glyph = [button valueForKey:@"_glyphLayer"]; } @catch (...) {}
        }
        if (!hlGlyph) {
            @try { hlGlyph = [button valueForKey:@"_highlightedGlyphLayer"]; } @catch (...) {}
        }
        if (glyph) glyph.affineTransform = transform;
        if (hlGlyph) hlGlyph.affineTransform = transform;
    }
}

static void injectPasscodeButton(UIView *button);

static void pcAnimateLayerSpring(CALayer *layer) {
    if (!layer) return;
    CGAffineTransform current = layer.affineTransform;
    if (CGAffineTransformIsIdentity(current)) return;

    CASpringAnimation *spring = [CASpringAnimation animationWithKeyPath:@"transform"];
    spring.damping = 12.0;
    spring.mass = 1.0;
    spring.stiffness = 150.0;
    spring.initialVelocity = 1.8;
    spring.duration = 0.52;
    spring.fromValue = [NSValue valueWithCATransform3D:layer.transform];
    spring.toValue = [NSValue valueWithCATransform3D:CATransform3DIdentity];
    [layer addAnimation:spring forKey:@"pcBounce"];
    layer.affineTransform = CGAffineTransformIdentity;
}

static void pcHandleTouchDownAtPoint(UIView *button, CGPoint point) {
    if (!button) return;
    BOOL isPressed = [objc_getAssociatedObject(button, kPCIsPressedKey) boolValue];
    if (isPressed) return;

    if (!objc_getAssociatedObject(button, kPCHostKey)) {
        injectPasscodeButton(button);
    }
    UIView *host = objc_getAssociatedObject(button, kPCHostKey) ?: pcButtonHost(button);
    if (!host) return;

    objc_setAssociatedObject(button, kPCIsPressedKey, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    objc_setAssociatedObject(button, kPCTouchStartKey, [NSValue valueWithCGPoint:point], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    objc_setAssociatedObject(button, kPCTouchDownTimeKey, @(CACurrentMediaTime()), OBJC_ASSOCIATION_RETAIN_NONATOMIC);

    uint64_t cycle = [objc_getAssociatedObject(button, kPCTouchCycleIdKey) unsignedLongLongValue] + 1;
    objc_setAssociatedObject(button, kPCTouchCycleIdKey, @(cycle), OBJC_ASSOCIATION_RETAIN_NONATOMIC);

    pcUnclipHierarchy(button);

    if (@available(iOS 13.0, *)) {
        UIImpactFeedbackGenerator *feedback = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleSoft];
        [feedback prepare];
        [feedback impactOccurred];
    }

    LGPasscodeExposureView *exposure = objc_getAssociatedObject(host, kPCExposureKey);
    UIView *tint = objc_getAssociatedObject(host, kPCTintKey);

    [UIView animateWithDuration:0.18 delay:0 usingSpringWithDamping:0.55 initialSpringVelocity:1.2 options:UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionBeginFromCurrentState animations:^{
        pcApplyTransform(button, host, CGAffineTransformMakeScale(1.10, 1.10));
        if (exposure) exposure.alpha = 1.0;
        if (tint) tint.alpha = 0.0;
    } completion:nil];
}

static void pcHandleTouchMovedToPoint(UIView *button, CGPoint point) {
    if (!button) return;
    BOOL isPressed = [objc_getAssociatedObject(button, kPCIsPressedKey) boolValue];
    if (!isPressed) {
        pcHandleTouchDownAtPoint(button, point);
    }

    pcUnclipHierarchy(button);

    UIView *host = objc_getAssociatedObject(button, kPCHostKey) ?: pcButtonHost(button);
    if (!host) return;

    NSValue *startVal = objc_getAssociatedObject(button, kPCTouchStartKey);
    CGPoint startPt = startVal ? startVal.CGPointValue : point;

    CGFloat dx = point.x - startPt.x;
    CGFloat dy = point.y - startPt.y;
    CGFloat dist = sqrt(dx * dx + dy * dy);

    CGAffineTransform transform = CGAffineTransformIdentity;

    if (dist > 0.5) {
        CGFloat angle = atan2(dy, dx);

        CGFloat maxShift = 14.0;
        CGFloat pullFactor = 1.0 - (1.0 / ((dist * 0.03) + 1.0));
        CGFloat currentShift = pullFactor * maxShift;

        CGFloat shiftX = cos(angle) * currentShift;
        CGFloat shiftY = sin(angle) * currentShift;

        CGFloat stretchFactor = 1.10 * (1.0 + (pullFactor * 0.12));
        CGFloat squashFactor  = 1.10 * (1.0 - (pullFactor * 0.04));

        transform = CGAffineTransformMakeTranslation(shiftX, shiftY);
        transform = CGAffineTransformRotate(transform, angle);
        transform = CGAffineTransformScale(transform, stretchFactor, squashFactor);
        transform = CGAffineTransformRotate(transform, -angle);
    } else {
        transform = CGAffineTransformMakeScale(1.10, 1.10);
    }

    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    pcApplyTransform(button, host, transform);
    [CATransaction commit];
}

static void pcHandleTouchEnded(UIView *button) {
    BOOL isPressed = [objc_getAssociatedObject(button, kPCIsPressedKey) boolValue];
    if (!isPressed) return;
    objc_setAssociatedObject(button, kPCIsPressedKey, @NO, OBJC_ASSOCIATION_RETAIN_NONATOMIC);

    UIView *host = objc_getAssociatedObject(button, kPCHostKey) ?: pcButtonHost(button);
    if (!host) {
        button.layer.zPosition = 0;
        return;
    }

    CFTimeInterval touchDownTime = [objc_getAssociatedObject(button, kPCTouchDownTimeKey) doubleValue];
    NSTimeInterval elapsed = CACurrentMediaTime() - touchDownTime;
    NSTimeInterval minPressDuration = 0.12;
    NSTimeInterval delay = (elapsed < minPressDuration) ? (minPressDuration - elapsed) : 0.0;

    uint64_t cycle = [objc_getAssociatedObject(button, kPCTouchCycleIdKey) unsignedLongLongValue];

    LGPasscodeExposureView *exposure = objc_getAssociatedObject(host, kPCExposureKey);
    UIView *tint = objc_getAssociatedObject(host, kPCTintKey);

    void (^performBounceRelease)(void) = ^{
        uint64_t curCycle = [objc_getAssociatedObject(button, kPCTouchCycleIdKey) unsignedLongLongValue];
        BOOL curPressed = [objc_getAssociatedObject(button, kPCIsPressedKey) boolValue];
        if (curCycle != cycle || curPressed) return;

        button.layer.zPosition = 0;

        CALayer *glyph = nil;
        CALayer *hlGlyph = nil;
        if ([button respondsToSelector:@selector(glyphLayer)]) glyph = [(TPNumberPadButton *)button glyphLayer];
        if ([button respondsToSelector:@selector(highlightedGlyphLayer)]) hlGlyph = [(TPNumberPadButton *)button highlightedGlyphLayer];
        if (!glyph) { @try { glyph = [button valueForKey:@"_glyphLayer"]; } @catch (...) {} }
        if (!hlGlyph) { @try { hlGlyph = [button valueForKey:@"_highlightedGlyphLayer"]; } @catch (...) {} }
        pcAnimateLayerSpring(glyph);
        pcAnimateLayerSpring(hlGlyph);

        [UIView animateWithDuration:0.52 delay:0 usingSpringWithDamping:0.44 initialSpringVelocity:1.8 options:UIViewAnimationOptionAllowUserInteraction animations:^{
            pcApplyTransform(button, host, CGAffineTransformIdentity);
            if (exposure) exposure.alpha = 0.0;
            if (tint) {
                tint.alpha = 1.0;
                tint.backgroundColor = [UIColor colorWithWhite:0.0 alpha:kPCRestDarkTint];
            }
        } completion:nil];
    };

    if (delay > 0.001) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), performBounceRelease);
    } else {
        performBounceRelease();
    }
}

static void pcRememberBg(UIView *host) {
    if (!objc_getAssociatedObject(host, kPCBgColorKey))
        objc_setAssociatedObject(host, kPCBgColorKey, host.backgroundColor ?: (id)[NSNull null], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    if (!objc_getAssociatedObject(host, kPCBgAlphaKey))
        objc_setAssociatedObject(host, kPCBgAlphaKey, @(host.alpha), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    if (!objc_getAssociatedObject(host, kPCBgOpaqueKey))
        objc_setAssociatedObject(host, kPCBgOpaqueKey, @(host.opaque), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

static void pcRestoreBg(UIView *host) {
    id color = objc_getAssociatedObject(host, kPCBgColorKey);
    id alpha = objc_getAssociatedObject(host, kPCBgAlphaKey);
    id opaque = objc_getAssociatedObject(host, kPCBgOpaqueKey);
    if (color)  host.backgroundColor = (color == [NSNull null]) ? nil : color;
    if (alpha)  host.alpha  = [alpha doubleValue];
    if (opaque) host.opaque = [opaque boolValue];
}

static void injectPasscodeButton(UIView *button) {
    if (!lgHostEnabled(@"Passcode")) return;
    UIView *host = pcButtonHost(button);
    if (!host) return;

    button.clipsToBounds = NO;
    button.layer.masksToBounds = NO;
    pcUnclipHierarchy(button);

    UIView *prev = objc_getAssociatedObject(button, kPCHostKey);
    if (prev && prev != host) {
        pcApplyTransform(button, prev, CGAffineTransformIdentity);
        pcRestoreBg(prev);
    }

    pcRememberBg(host);
    host.backgroundColor = UIColor.clearColor;
    host.alpha = 1.0;
    host.opaque = NO;
    host.clipsToBounds = YES;
    CGFloat r = fmin(CGRectGetWidth(host.bounds), CGRectGetHeight(host.bounds)) * 0.5;
    host.layer.cornerRadius  = r;
    host.layer.cornerCurve   = kCACornerCurveCircular;
    host.layer.masksToBounds = YES;

    LGLiveBackdropView *glass = objc_getAssociatedObject(host, kPCGlassKey);
    if (!glass) {
        glass = LGCreateRegisteredGlass(host.bounds, nil, @"Passcode");
        if (!glass) return;
        glass.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [host insertSubview:glass atIndex:0];
        objc_setAssociatedObject(host, kPCGlassKey, glass, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    if (glass.superview != host) [host insertSubview:glass atIndex:0];
    glass.frame = host.bounds;
    glass.layer.cornerRadius  = r;
    glass.layer.cornerCurve   = kCACornerCurveCircular;
    glass.layer.masksToBounds = YES;
    [glass applyFilters];
    lgTrackGlass(glass, @"Passcode", nil);

    LGPasscodeVibranceView *vibrance = objc_getAssociatedObject(host, kPCVibranceKey);
    if (!vibrance) {
        vibrance = [[LGPasscodeVibranceView alloc] initWithFrame:host.bounds];
        if (vibrance) {
            vibrance.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
            [host insertSubview:vibrance aboveSubview:glass];
            objc_setAssociatedObject(host, kPCVibranceKey, vibrance, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        }
    }
    if (vibrance) {
        if (vibrance.superview != host) [host insertSubview:vibrance aboveSubview:glass];
        vibrance.frame = host.bounds;
        vibrance.layer.cornerRadius = r;
        vibrance.layer.cornerCurve = kCACornerCurveCircular;
        vibrance.layer.masksToBounds = YES;
        [vibrance applyFilters];
    }

    LGPasscodeExposureView *exposure = objc_getAssociatedObject(host, kPCExposureKey);
    if (!exposure) {
        exposure = [[LGPasscodeExposureView alloc] initWithFrame:host.bounds];
        if (exposure) {
            exposure.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
            if (vibrance) [host insertSubview:exposure aboveSubview:vibrance];
            else [host insertSubview:exposure aboveSubview:glass];
            objc_setAssociatedObject(host, kPCExposureKey, exposure, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        }
    }
    if (exposure) {
        if (exposure.superview != host) {
            if (vibrance) [host insertSubview:exposure aboveSubview:vibrance];
            else [host insertSubview:exposure aboveSubview:glass];
        }
        exposure.frame = host.bounds;
        exposure.layer.cornerRadius = r;
        exposure.layer.cornerCurve = kCACornerCurveCircular;
        exposure.layer.masksToBounds = YES;
        [exposure applyFilters];
    }

    UIView *tint = objc_getAssociatedObject(host, kPCTintKey);
    if (!tint) {
        tint = [[UIView alloc] initWithFrame:host.bounds];
        tint.userInteractionEnabled = NO;
        tint.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        objc_setAssociatedObject(host, kPCTintKey, tint, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    if (tint.superview != host) [host addSubview:tint];
    tint.frame = host.bounds;
    tint.layer.cornerRadius  = r;
    tint.layer.cornerCurve   = kCACornerCurveCircular;
    tint.layer.masksToBounds = YES;
    [host bringSubviewToFront:tint];

    objc_setAssociatedObject(button, kPCHostKey, host, OBJC_ASSOCIATION_ASSIGN);

    LGLiquidBlockerGesture *blocker = objc_getAssociatedObject(button, kPCBlockerGestureKey);
    if (!blocker) {
        blocker = [[LGLiquidBlockerGesture alloc] init];
        [button addGestureRecognizer:blocker];
        objc_setAssociatedObject(button, kPCBlockerGestureKey, blocker, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    for (UIGestureRecognizer *gr in button.gestureRecognizers) {
        if ([gr isKindOfClass:[UILongPressGestureRecognizer class]]) {
            gr.cancelsTouchesInView = NO;
        }
    }

    BOOL highlighted = [objc_getAssociatedObject(button, kPCHighlightedKey) boolValue];
    BOOL isPressed = [objc_getAssociatedObject(button, kPCIsPressedKey) boolValue];
    if (highlighted || isPressed) {
        if (exposure) exposure.alpha = 1.0;
        if (tint) tint.alpha = 0.0;
    } else {
        if (exposure) exposure.alpha = 0.0;
        if (tint) {
            tint.alpha = 1.0;
            tint.backgroundColor = [UIColor colorWithWhite:0.0 alpha:kPCRestDarkTint];
        }
    }
}

static void resetPasscodeButton(UIView *button) {
    UIView *host = objc_getAssociatedObject(button, kPCHostKey) ?: pcButtonHost(button);
    if (!host) return;
    LGLiveBackdropView *glass = objc_getAssociatedObject(host, kPCGlassKey);
    [glass removeFromSuperview];
    objc_setAssociatedObject(host, kPCGlassKey, nil, OBJC_ASSOCIATION_ASSIGN);
    LGPasscodeVibranceView *vibrance = objc_getAssociatedObject(host, kPCVibranceKey);
    [vibrance removeFromSuperview];
    objc_setAssociatedObject(host, kPCVibranceKey, nil, OBJC_ASSOCIATION_ASSIGN);
    LGPasscodeExposureView *exposure = objc_getAssociatedObject(host, kPCExposureKey);
    [exposure removeFromSuperview];
    objc_setAssociatedObject(host, kPCExposureKey, nil, OBJC_ASSOCIATION_ASSIGN);
    UIView *tint = objc_getAssociatedObject(host, kPCTintKey);
    [tint removeFromSuperview];
    objc_setAssociatedObject(host, kPCTintKey, nil, OBJC_ASSOCIATION_ASSIGN);
    pcApplyTransform(button, host, CGAffineTransformIdentity);
    pcRestoreBg(host);
    button.layer.zPosition = 0;
    LGLiquidBlockerGesture *blocker = objc_getAssociatedObject(button, kPCBlockerGestureKey);
    if (blocker) {
        [button removeGestureRecognizer:blocker];
        objc_setAssociatedObject(button, kPCBlockerGestureKey, nil, OBJC_ASSOCIATION_ASSIGN);
    }
    objc_setAssociatedObject(button, kPCHostKey, nil, OBJC_ASSOCIATION_ASSIGN);
    objc_setAssociatedObject(button, kPCHighlightedKey, nil, OBJC_ASSOCIATION_ASSIGN);
    objc_setAssociatedObject(button, kPCIsPressedKey, nil, OBJC_ASSOCIATION_ASSIGN);
    objc_setAssociatedObject(button, kPCTouchStartKey, nil, OBJC_ASSOCIATION_ASSIGN);
    objc_setAssociatedObject(button, kPCTouchDownTimeKey, nil, OBJC_ASSOCIATION_ASSIGN);
    objc_setAssociatedObject(button, kPCTouchCycleIdKey, nil, OBJC_ASSOCIATION_ASSIGN);
}

static void setPasscodeButtonHighlighted(UIView *button, BOOL highlighted) {
    if (!lgHostEnabled(@"Passcode")) {
        resetPasscodeButton(button);
        return;
    }
    UIView *host = objc_getAssociatedObject(button, kPCHostKey) ?: pcButtonHost(button);
    if (!host) return;

    objc_setAssociatedObject(button, kPCHighlightedKey, @(highlighted), OBJC_ASSOCIATION_RETAIN_NONATOMIC);

    BOOL isPressed = [objc_getAssociatedObject(button, kPCIsPressedKey) boolValue];
    if (!isPressed) {
        LGPasscodeExposureView *exposure = objc_getAssociatedObject(host, kPCExposureKey);
        UIView *tint = objc_getAssociatedObject(host, kPCTintKey);
        if (highlighted) {
            pcUnclipHierarchy(button);
            [UIView animateWithDuration:0.18 delay:0 usingSpringWithDamping:0.55 initialSpringVelocity:1.2 options:UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionBeginFromCurrentState animations:^{
                pcApplyTransform(button, host, CGAffineTransformMakeScale(1.10, 1.10));
                if (exposure) exposure.alpha = 1.0;
                if (tint) tint.alpha = 0.0;
            } completion:nil];
        } else {
            button.layer.zPosition = 0;
            [UIView animateWithDuration:0.52 delay:0 usingSpringWithDamping:0.44 initialSpringVelocity:1.8 options:UIViewAnimationOptionAllowUserInteraction animations:^{
                pcApplyTransform(button, host, CGAffineTransformIdentity);
                if (exposure) exposure.alpha = 0.0;
                if (tint) {
                    tint.alpha = 1.0;
                    tint.backgroundColor = [UIColor colorWithWhite:0.0 alpha:kPCRestDarkTint];
                }
            } completion:nil];
        }
    }
}

static BOOL isPasscodeSuppressibleRoot(UIView *v) {
    NSString *c = NSStringFromClass(v.class);
    return [c isEqualToString:@"CSQuickActionsButton"]
        || [c isEqualToString:@"CSProminentTimeView"]
        || [c isEqualToString:@"SBFLockScreenDateView"]
        || [c isEqualToString:@"PLPlatterView"]
        || [c isEqualToString:@"NCNotificationListView"]
        || [c isEqualToString:@"NCNotificationCombinedListView"]
        || [c isEqualToString:@"NCNotificationShortLookView"]
        || [c isEqualToString:@"NCNotificationLongLookView"];
}

static void *kPCSuppAlphaKey  = &kPCSuppAlphaKey;
static void *kPCSuppHiddenKey = &kPCSuppHiddenKey;

static void setPasscodeSuppressed(UIView *v, BOOL suppressed) {
    if (suppressed) {
        if (!objc_getAssociatedObject(v, kPCSuppAlphaKey)) {
            objc_setAssociatedObject(v, kPCSuppAlphaKey, @(v.alpha), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            objc_setAssociatedObject(v, kPCSuppHiddenKey, @(v.hidden), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        }
        [v.layer removeAllAnimations];
        [UIView animateWithDuration:0.18 delay:0.0
                            options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionCurveEaseInOut
                         animations:^{ v.alpha = 0.0; }
                         completion:^(__unused BOOL fin) { if (sPasscodeVisible) v.hidden = YES; }];
    } else {
        NSNumber *alpha = objc_getAssociatedObject(v, kPCSuppAlphaKey);
        [v.layer removeAllAnimations];
        v.hidden = NO;
        [UIView animateWithDuration:0.2 delay:0.0
                            options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionCurveEaseInOut
                         animations:^{ v.alpha = alpha ? alpha.doubleValue : 1.0; }
                         completion:^(__unused BOOL fin) {
            NSNumber *h = objc_getAssociatedObject(v, kPCSuppHiddenKey);
            if (h) v.hidden = h.boolValue;
        }];
        objc_setAssociatedObject(v, kPCSuppAlphaKey, nil, OBJC_ASSOCIATION_ASSIGN);
        objc_setAssociatedObject(v, kPCSuppHiddenKey, nil, OBJC_ASSOCIATION_ASSIGN);
    }
}

static void applyPasscodeSuppression(void) {
    for (UIWindow *w in UIApplication.sharedApplication.windows) {
        NSMutableArray<UIView *> *stack = [NSMutableArray arrayWithObject:w];
        while (stack.count) {
            UIView *v = stack.lastObject; [stack removeLastObject];
            if (isPasscodeSuppressibleRoot(v)) { setPasscodeSuppressed(v, sPasscodeVisible); continue; }
            for (UIView *c in v.subviews) [stack addObject:c];
        }
    }
}

static void updatePasscodeVisible(BOOL visible) {
    if (!lgHostEnabled(@"Passcode")) visible = NO;
    if (sPasscodeVisible == visible) return;
    sPasscodeVisible = visible;
    dispatch_async(dispatch_get_main_queue(), ^{ applyPasscodeSuppression(); });
}

static BOOL passcodeBackgroundVisible(UIView *v) {
    return isExactClass(v, @"CSPasscodeBackgroundView") && v.window &&
           !v.hidden && v.alpha > 0.01 && v.layer.opacity > 0.01f;
}

static void restorePasscodeSubtree(UIView *view) {
    if ([NSStringFromClass(view.class) isEqualToString:@"SBPasscodeNumberPadButton"])
        resetPasscodeButton(view);
    if ([NSStringFromClass(view.class) isEqualToString:@"CSPasscodeBackgroundView"]) {
        UIView *tint = objc_getAssociatedObject(view, kPCBgTintKey);
        [tint removeFromSuperview];
        objc_setAssociatedObject(view, kPCBgTintKey, nil, OBJC_ASSOCIATION_ASSIGN);
    }
    for (UIView *sub in [view.subviews copy]) restorePasscodeSubtree(sub);
}

static void restorePasscodeForDisable(void) {
    if (lgHostEnabled(@"Passcode")) return;
    updatePasscodeVisible(NO);
    for (UIWindow *window in UIApplication.sharedApplication.windows)
        restorePasscodeSubtree(window);
}

%group LGPasscodeHooks

%hook MTMaterialView
- (void)didMoveToWindow {
    %orig;
    UIView *self_ = (UIView *)self;
    if (self_.window) handlePasscodeBackgroundMaterial(self_);
}
- (void)layoutSubviews {
    %orig;
    handlePasscodeBackgroundMaterial((UIView *)self);
}
%end

%hook TPNumberPadButton

- (void)highlightCircleView:(BOOL)highlight animated:(BOOL)animated {
    if (lgHostEnabled(@"Passcode")) return;
    %orig;
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    if (!lgHostEnabled(@"Passcode")) return %orig;
    UIView *self_ = (UIView *)self;
    BOOL isPressed = [objc_getAssociatedObject(self, kPCIsPressedKey) boolValue];
    if (isPressed || CGRectContainsPoint(CGRectInset(self_.bounds, -20.0, -20.0), point)) {
        if (!self_.hidden && self_.alpha > 0.01 && self_.userInteractionEnabled) {
            if (CGRectContainsPoint(CGRectInset(self_.bounds, -120.0, -120.0), point)) {
                return self_;
            }
        }
    }
    return %orig;
}

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event {
    if (!lgHostEnabled(@"Passcode")) return %orig;
    UIView *self_ = (UIView *)self;
    BOOL isPressed = [objc_getAssociatedObject(self, kPCIsPressedKey) boolValue];
    if (isPressed) {
        return CGRectContainsPoint(CGRectInset(self_.bounds, -120.0, -120.0), point);
    }
    return %orig;
}

- (BOOL)pointMostlyInside:(CGPoint)point withEvent:(UIEvent *)event {
    if (!lgHostEnabled(@"Passcode")) return %orig;
    BOOL isPressed = [objc_getAssociatedObject(self, kPCIsPressedKey) boolValue];
    if (isPressed) {
        return CGRectContainsPoint(CGRectInset(((UIView *)self).bounds, -120.0, -120.0), point);
    }
    return %orig;
}

%end

%hook SBPasscodeNumberPadButton

- (void)didMoveToWindow {
    %orig;
    UIView *self_ = (UIView *)self;
    if (self_.window) injectPasscodeButton(self_);
    else resetPasscodeButton(self_);
}

- (void)layoutSubviews {
    %orig;
    injectPasscodeButton((UIView *)self);
}

- (void)setHighlighted:(BOOL)highlighted {
    %orig;
    setPasscodeButtonHighlighted((UIView *)self, highlighted);
}

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event {
    if (!lgHostEnabled(@"Passcode")) return %orig;
    UIView *self_ = (UIView *)self;
    BOOL isPressed = [objc_getAssociatedObject(self, kPCIsPressedKey) boolValue];
    if (isPressed) {
        return CGRectContainsPoint(CGRectInset(self_.bounds, -120.0, -120.0), point);
    }
    return %orig;
}

- (BOOL)pointMostlyInside:(CGPoint)point withEvent:(UIEvent *)event {
    if (!lgHostEnabled(@"Passcode")) return %orig;
    BOOL isPressed = [objc_getAssociatedObject(self, kPCIsPressedKey) boolValue];
    if (isPressed) {
        return CGRectContainsPoint(CGRectInset(((UIView *)self).bounds, -120.0, -120.0), point);
    }
    return %orig;
}

- (BOOL)beginTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event {
    if (lgHostEnabled(@"Passcode")) {
        CGPoint pt = [touch locationInView:(UIView *)self];
        pcHandleTouchDownAtPoint((UIView *)self, pt);
        return YES;
    }
    return %orig;
}

- (BOOL)continueTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event {
    if (lgHostEnabled(@"Passcode")) {
        CGPoint pt = [touch locationInView:(UIView *)self];
        pcHandleTouchMovedToPoint((UIView *)self, pt);
        return YES;
    }
    return %orig;
}

- (void)endTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event {
    if (lgHostEnabled(@"Passcode")) {
        CGPoint point = [touch locationInView:(UIView *)self];
        NSValue *startVal = objc_getAssociatedObject(self, kPCTouchStartKey);
        CGPoint startPt = startVal ? startVal.CGPointValue : point;
        CGFloat dx = point.x - startPt.x;
        CGFloat dy = point.y - startPt.y;
        CGFloat dist = sqrt(dx * dx + dy * dy);

        pcHandleTouchEnded((UIView *)self);

        if (dist >= 55.0) {
            [self cancelTrackingWithEvent:event];
            return;
        }
    }
    %orig;
}

- (void)cancelTrackingWithEvent:(UIEvent *)event {
    if (lgHostEnabled(@"Passcode")) {
        pcHandleTouchEnded((UIView *)self);
    }
    %orig;
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    if (lgHostEnabled(@"Passcode")) {
        UITouch *t = [touches anyObject];
        if (t) {
            CGPoint pt = [t locationInView:(UIView *)self];
            pcHandleTouchDownAtPoint((UIView *)self, pt);
        }
    }
    %orig;
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    if (lgHostEnabled(@"Passcode")) {
        UITouch *t = [touches anyObject];
        if (t) {
            CGPoint pt = [t locationInView:(UIView *)self];
            pcHandleTouchMovedToPoint((UIView *)self, pt);
        }
    }
    %orig;
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    if (lgHostEnabled(@"Passcode")) {
        pcHandleTouchEnded((UIView *)self);
    }
    %orig;
}

- (void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    if (lgHostEnabled(@"Passcode")) {
        pcHandleTouchEnded((UIView *)self);
    }
    %orig;
}

%end

%hook SBNumberPadWithDelegate

- (void)didMoveToWindow {
    %orig;
    if (lgHostEnabled(@"Passcode")) {
        UIView *self_ = (UIView *)self;
        self_.clipsToBounds = NO;
        self_.layer.masksToBounds = NO;
        for (UIGestureRecognizer *gr in self_.gestureRecognizers) {
            gr.cancelsTouchesInView = NO;
        }
        LGLiquidBlockerGesture *blocker = objc_getAssociatedObject(self, kPCBlockerGestureKey);
        if (!blocker) {
            blocker = [[LGLiquidBlockerGesture alloc] init];
            [self_ addGestureRecognizer:blocker];
            objc_setAssociatedObject(self, kPCBlockerGestureKey, blocker, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        }
    }
}

- (void)layoutSubviews {
    %orig;
    if (lgHostEnabled(@"Passcode")) {
        UIView *self_ = (UIView *)self;
        self_.clipsToBounds = NO;
        self_.layer.masksToBounds = NO;
        for (UIGestureRecognizer *gr in self_.gestureRecognizers) {
            gr.cancelsTouchesInView = NO;
        }
    }
}

- (BOOL)touchAtPoint:(CGPoint)point isCloseToButton:(UIView *)button {
    if (!lgHostEnabled(@"Passcode")) return %orig;
    if (!button) return NO;

    CGRect expanded = CGRectInset(button.frame, -38.0, -38.0);
    return CGRectContainsPoint(expanded, point);
}

- (BOOL)beginTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event {
    BOOL ret = %orig;
    if (lgHostEnabled(@"Passcode")) {
        CGPoint pt = [touch locationInView:(UIView *)self];
        UIView *btn = [self buttonForPoint:pt forEvent:event];
        UIView *prev = objc_getAssociatedObject(self, kPCActiveButtonKey);
        if (prev && prev != btn) {
            pcHandleTouchEnded(prev);
        }
        objc_setAssociatedObject(self, kPCActiveButtonKey, btn, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        if (btn) {
            CGPoint ptInBtn = [touch locationInView:btn];
            pcHandleTouchDownAtPoint(btn, ptInBtn);
        }
    }
    return ret;
}

- (BOOL)continueTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event {
    BOOL ret = %orig;
    if (lgHostEnabled(@"Passcode")) {
        UIView *btn = objc_getAssociatedObject(self, kPCActiveButtonKey);
        if (btn) {
            CGPoint ptInBtn = [touch locationInView:btn];
            pcHandleTouchMovedToPoint(btn, ptInBtn);
        }
    }
    return ret;
}

- (void)endTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event {
    if (lgHostEnabled(@"Passcode")) {
        UIView *btn = objc_getAssociatedObject(self, kPCActiveButtonKey);
        if (btn) {
            pcHandleTouchEnded(btn);
            objc_setAssociatedObject(self, kPCActiveButtonKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        }
    }
    %orig;
}

- (void)cancelTrackingWithEvent:(UIEvent *)event {
    if (lgHostEnabled(@"Passcode")) {
        UIView *btn = objc_getAssociatedObject(self, kPCActiveButtonKey);
        if (btn) {
            pcHandleTouchEnded(btn);
            objc_setAssociatedObject(self, kPCActiveButtonKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        }
    }
    %orig;
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    %orig;
    if (lgHostEnabled(@"Passcode")) {
        UITouch *t = [touches anyObject];
        if (t) {
            CGPoint pt = [t locationInView:(UIView *)self];
            UIView *btn = [self buttonForPoint:pt forEvent:event];
            UIView *prev = objc_getAssociatedObject(self, kPCActiveButtonKey);
            if (prev && prev != btn) {
                pcHandleTouchEnded(prev);
            }
            objc_setAssociatedObject(self, kPCActiveButtonKey, btn, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            if (btn) {
                CGPoint ptInBtn = [t locationInView:btn];
                pcHandleTouchDownAtPoint(btn, ptInBtn);
            }
        }
    }
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    %orig;
    if (lgHostEnabled(@"Passcode")) {
        UIView *btn = objc_getAssociatedObject(self, kPCActiveButtonKey);
        if (btn) {
            UITouch *t = [touches anyObject];
            if (t) {
                CGPoint ptInBtn = [t locationInView:btn];
                pcHandleTouchMovedToPoint(btn, ptInBtn);
            }
        }
    }
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    if (lgHostEnabled(@"Passcode")) {
        UIView *btn = objc_getAssociatedObject(self, kPCActiveButtonKey);
        if (btn) {
            pcHandleTouchEnded(btn);
            objc_setAssociatedObject(self, kPCActiveButtonKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        }
    }
    %orig;
}

- (void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    if (lgHostEnabled(@"Passcode")) {
        UIView *btn = objc_getAssociatedObject(self, kPCActiveButtonKey);
        if (btn) {
            pcHandleTouchEnded(btn);
            objc_setAssociatedObject(self, kPCActiveButtonKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        }
    }
    %orig;
}

%end

%hook CSScrollView

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    if (lgHostEnabled(@"Passcode")) {
        UIView *v = touch.view;
        while (v) {
            if ([v isKindOfClass:objc_getClass("SBPasscodeNumberPadButton")] ||
                [v isKindOfClass:objc_getClass("TPNumberPadButton")] ||
                [v isKindOfClass:objc_getClass("TPNumberPad")] ||
                [v isKindOfClass:objc_getClass("SBNumberPadWithDelegate")] ||
                [v isKindOfClass:objc_getClass("SBUIPasscodeLockNumberPad")]) {
                return NO;
            }
            v = v.superview;
        }
    }
    return %orig;
}

%end

%hook CSPasscodeBackgroundView
- (void)didMoveToWindow { %orig; updatePasscodeVisible(passcodeBackgroundVisible((UIView *)self)); }
- (void)layoutSubviews  { %orig; updatePasscodeVisible(passcodeBackgroundVisible((UIView *)self)); }
- (void)setHidden:(BOOL)hidden { %orig; updatePasscodeVisible(passcodeBackgroundVisible((UIView *)self)); }
%end

%end

%ctor {
    if (!LGIsSpringBoardProcess()) return;
    dlopen("/System/Library/PrivateFrameworks/TelephonyUI.framework/TelephonyUI", RTLD_NOW);
    dlopen("/System/Library/PrivateFrameworks/SpringBoardUIServices.framework/SpringBoardUIServices", RTLD_NOW);
    dlopen("/System/Library/PrivateFrameworks/CoverSheet.framework/CoverSheet", RTLD_NOW);
    %init(LGPasscodeHooks,
          TPNumberPadButton = objc_getClass("TPNumberPadButton"),
          SBPasscodeNumberPadButton = objc_getClass("SBPasscodeNumberPadButton"),
          SBNumberPadWithDelegate = objc_getClass("SBNumberPadWithDelegate"),
          CSPasscodeBackgroundView = objc_getClass("CSPasscodeBackgroundView"),
          MTMaterialView = objc_getClass("MTMaterialView"),
          CSScrollView = objc_getClass("CSScrollView"));
    lgObservePreferenceReload(^{ restorePasscodeForDisable(); });
}
