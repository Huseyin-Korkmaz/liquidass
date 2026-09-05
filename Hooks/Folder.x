#import <UIKit/UIKit.h>
#import <math.h>
#import "../Shared/LGLiveBackdropView.h"
#import "../Shared/LGGlassKit.h"
#import "../Shared/LGSharedSupport.h"
#import <objc/runtime.h>

@interface SBFolderIconImageView : UIView
@end

@interface SBIconBadgeView : UIView
@end

static BOOL isFolderIconMaterial(UIView *mat) {
    static Class folderCls, iconCls;
    if (!folderCls) folderCls = NSClassFromString(@"SBFolderIconImageView");
    if (!iconCls)   iconCls   = NSClassFromString(@"SBIconView");
    for (UIView *v = mat.superview; v; v = v.superview) {
        if ([v isKindOfClass:folderCls]) return YES;
        if ([v isKindOfClass:iconCls])   break;
    }
    return NO;
}

static BOOL isOpenFolderMaterial(UIView *mat) {
    if (!hasAncestorOfClassName(mat, @"SBFolderBackgroundView")) return NO;
    CGRect b = mat.bounds;
    return CGRectGetWidth(b) >= 200.0 && CGRectGetHeight(b) >= 200.0;
}

static NSHashTable<UIView *> *sFolderIconGlasses;
static NSHashTable<UIView *> *sFolderIconMaterials;
static NSHashTable<UIView *> *sOpenFolderMaterials;
static BOOL sOpenFolderIsOpen;

static BOOL anyOpenFolderActive(void) {
    for (UIView *m in sOpenFolderMaterials.allObjects) {
        if (m.window) return YES;
    }
    return NO;
}

static UIView *glassForBackgroundView(UIView *bg) {
    if (!bg) return nil;
    UIView *g = objc_getAssociatedObject(bg, kGlassKey);
    if (g) return g;
    for (UIView *sub in bg.subviews) {
        g = objc_getAssociatedObject(sub, kGlassKey);
        if (g) return g;
    }
    return nil;
}

static void hideRemainingFolderIconGlasses(UIView *activeFolderIconImageView) {
    sOpenFolderIsOpen = YES;
    UIView *activeBg = nil;
    if (activeFolderIconImageView) {
        @try { activeBg = [activeFolderIconImageView valueForKey:@"_backgroundView"]; } @catch (...) {}
    }
    UIView *activeGlass = glassForBackgroundView(activeBg);

    for (UIView *g in sFolderIconGlasses.allObjects) {
        if (g == activeGlass) continue;
        g.hidden = YES;
        g.alpha = 0.0;
    }
}

static void showAllFolderIconGlasses(void) {
    sOpenFolderIsOpen = NO;
    for (UIView *g in sFolderIconGlasses.allObjects) {
        UIView *parent = g.superview;
        id crossfadeView = nil;
        if (parent) {
            @try { crossfadeView = [parent valueForKey:@"_crossfadeFolderView"]; } @catch (...) {}
        }
        if (!crossfadeView) {
            g.hidden = NO;
            g.alpha = 1.0;
        }
    }
}

CGFloat LGFolderIconCornerRadiusFallback(void) {

    for (UIView *glass in sFolderIconGlasses.allObjects) {
        CGFloat radius = glass.layer.cornerRadius;
        if (isfinite(radius) && radius > 0.0) return radius;
    }
    for (UIView *material in sFolderIconMaterials.allObjects) {
        CGFloat radius = material.layer.cornerRadius;
        if (isfinite(radius) && radius > 0.0) return radius;
    }
    return 0.0;
}

static void ensureFolderIconSubviewOrder(UIView *parent) {
    if (!parent) return;
    UIView *bg = nil;
    UIView *grid = nil;
    UIView *scaling = nil;
    @try {
        bg = [parent valueForKey:@"_backgroundView"];
        grid = [parent valueForKey:@"_pageGridContainer"];
        scaling = [parent valueForKey:@"_crossfadeScalingView"];
    } @catch (...) {}

    UIView *glass = glassForBackgroundView(bg);
    if (glass && glass.superview == parent) {
        if (bg) [parent insertSubview:glass aboveSubview:bg];
        if (scaling) [parent insertSubview:glass belowSubview:scaling];
        if (grid) [parent insertSubview:glass belowSubview:grid];
    }

    Class badgeClass = NSClassFromString(@"SBIconBadgeView");
    for (UIView *sub in parent.subviews) {
        if (badgeClass && [sub isKindOfClass:badgeClass]) {
            [parent bringSubviewToFront:sub];
        }
    }
}

static void injectFolderIcon(UIView *mat) {
    if (!mat) return;
    if (!sFolderIconMaterials) sFolderIconMaterials = [NSHashTable weakObjectsHashTable];
    [sFolderIconMaterials addObject:mat];

    UIView *g = LGInstallRegisteredGlassInMaterial(mat, kGlassKey, @"FolderIcon",
                                                    UIEdgeInsetsZero, -1.0, nil);
    if (!g) return;
    if (!sFolderIconGlasses) sFolderIconGlasses = [NSHashTable weakObjectsHashTable];
    [sFolderIconGlasses addObject:g];

    if (mat.superview) {
        objc_setAssociatedObject(mat.superview, kGlassKey, g, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }

    UIView *folderImageView = nil;
    Class folderCls = NSClassFromString(@"SBFolderIconImageView");
    for (UIView *v = mat.superview; v; v = v.superview) {
        if (folderCls && [v isKindOfClass:folderCls]) {
            folderImageView = v;
            break;
        }
    }

    id crossfadeView = nil;
    if (folderImageView) {
        @try { crossfadeView = [folderImageView valueForKey:@"_crossfadeFolderView"]; } @catch (...) {}
    }
    if (crossfadeView || sOpenFolderIsOpen) {
        g.hidden = YES;
        g.alpha = 0.0;
    } else {
        g.hidden = NO;
        g.alpha = 1.0;
    }

    ensureFolderIconSubviewOrder(folderImageView ?: mat.superview);
}

static void injectOpenFolder(UIView *mat) {
    if (!LGInstallRegisteredGlassInMaterial(mat, kGlassKey, @"OpenFolder",
                                            UIEdgeInsetsZero, -1.0, nil)) {
        [sOpenFolderMaterials removeObject:mat];
        if (!anyOpenFolderActive()) showAllFolderIconGlasses();
        return;
    }
    if (!sOpenFolderMaterials) sOpenFolderMaterials = [NSHashTable weakObjectsHashTable];
    if (![sOpenFolderMaterials containsObject:mat]) {
        [sOpenFolderMaterials addObject:mat];
    }
}

%group FolderHooks

%hook MTMaterialView
- (void)didMoveToWindow {
    %orig;
    UIView *self_ = (UIView *)self;
    if (!self_.window) {
        [sFolderIconMaterials removeObject:self_];
        if ([sOpenFolderMaterials containsObject:self_]) {
            [sOpenFolderMaterials removeObject:self_];
            if (!anyOpenFolderActive()) {
                showAllFolderIconGlasses();
            }
        }
        return;
    }
    if (isFolderIconMaterial(self_))      injectFolderIcon(self_);
    else if (isOpenFolderMaterial(self_)) injectOpenFolder(self_);
}

- (void)layoutSubviews {
    %orig;
    UIView *self_ = (UIView *)self;
    if (isFolderIconMaterial(self_))      injectFolderIcon(self_);
    else if (isOpenFolderMaterial(self_)) injectOpenFolder(self_);
}

- (void)setAlpha:(CGFloat)alpha {
    %orig(alpha);
    UIView *self_ = (UIView *)self;
    if (isFolderIconMaterial(self_)) {
        UIView *parent = self_.superview;
        id crossfadeView = nil;
        if (parent) {
            @try { crossfadeView = [parent valueForKey:@"_crossfadeFolderView"]; } @catch (...) {}
        }
        UIView *glass = objc_getAssociatedObject(self_, kGlassKey);
        if (!glass && parent) glass = objc_getAssociatedObject(parent, kGlassKey);
        if (glass) {
            if (crossfadeView || sOpenFolderIsOpen) {
                glass.hidden = YES;
                glass.alpha = 0.0;
            } else {
                glass.hidden = (alpha <= 0.001);
                glass.alpha = alpha;
            }
        }
    } else if (isOpenFolderMaterial(self_)) {
        UIView *glass = objc_getAssociatedObject(self_, kGlassKey);
        if (glass) glass.alpha = alpha;
    }
}
%end

%hook SBFolderIconImageView

- (void)prepareToCrossfadeWithFloatyFolderView:(id)floatyFolderView allowFolderInteraction:(BOOL)allowFolderInteraction {
    %orig;
    if (sOpenFolderIsOpen) {
        showAllFolderIconGlasses();
    }
    UIView *bg = nil;
    @try { bg = [self valueForKey:@"_backgroundView"]; } @catch (...) {}
    UIView *glass = glassForBackgroundView(bg);
    if (glass) {
        glass.hidden = YES;
        glass.alpha = 0.0;
    }
}

- (void)setFloatyFolderCrossfadeFraction:(CGFloat)fraction {
    %orig(fraction);
    if (fraction >= 0.999f && anyOpenFolderActive()) {
        hideRemainingFolderIconGlasses(self);
    } else if (fraction < 0.95f && sOpenFolderIsOpen) {
        showAllFolderIconGlasses();
    }

    UIView *bg = nil;
    @try { bg = [self valueForKey:@"_backgroundView"]; } @catch (...) {}
    UIView *glass = glassForBackgroundView(bg);
    if (glass) {
        glass.hidden = YES;
        glass.alpha = 0.0;
    }
}

- (void)setBackgroundAndIconGridImageAlpha:(CGFloat)alpha {
    %orig(alpha);
    id crossfadeView = nil;
    @try { crossfadeView = [self valueForKey:@"_crossfadeFolderView"]; } @catch (...) {}
    UIView *bg = nil;
    @try { bg = [self valueForKey:@"_backgroundView"]; } @catch (...) {}
    UIView *glass = glassForBackgroundView(bg);
    if (glass) {
        if (crossfadeView || sOpenFolderIsOpen) {
            glass.hidden = YES;
            glass.alpha = 0.0;
        } else {
            glass.hidden = (alpha <= 0.001);
            glass.alpha = alpha;
        }
    }
}

- (void)layoutSubviews {
    %orig;
    UIView *bg = nil;
    @try { bg = [self valueForKey:@"_backgroundView"]; } @catch (...) {}
    if (bg) {

        Class matCls = NSClassFromString(@"MTMaterialView");
        UIView *mat = (matCls && [bg isKindOfClass:matCls]) ? bg : nil;
        if (!mat) {
            for (UIView *sub in bg.subviews) {
                if (matCls && [sub isKindOfClass:matCls]) {
                    mat = sub;
                    break;
                }
            }
        }
        if (mat) {
            injectFolderIcon(mat);
        }

        id crossfadeView = nil;
        @try { crossfadeView = [self valueForKey:@"_crossfadeFolderView"]; } @catch (...) {}
        UIView *glass = glassForBackgroundView(bg);
        if (glass) {
            if (crossfadeView || sOpenFolderIsOpen) {
                glass.hidden = YES;
                glass.alpha = 0.0;
            } else {
                glass.hidden = NO;
                glass.alpha = 1.0;
            }
        }
    }
    ensureFolderIconSubviewOrder(self);
}

- (void)cleanupAfterFloatyFolderCrossfade {
    %orig;
    UIView *bg = nil;
    @try { bg = [self valueForKey:@"_backgroundView"]; } @catch (...) {}
    UIView *glass = glassForBackgroundView(bg);
    if (glass) {
        if (anyOpenFolderActive()) {
            glass.hidden = YES;
            glass.alpha = 0.0;
            hideRemainingFolderIconGlasses(self);
        } else {
            glass.hidden = NO;
            glass.alpha = 1.0;
            showAllFolderIconGlasses();
        }
    }
    ensureFolderIconSubviewOrder(self);
}

%end

@interface SBFolderController : NSObject
@end

%hook SBFolderController

- (void)folderControllerWillClose:(id)arg1 {
    %orig;
    showAllFolderIconGlasses();
}

- (void)folderControllerDidClose:(id)arg1 {
    %orig;
    showAllFolderIconGlasses();
}

%end

%hook SBIconBadgeView

- (void)didMoveToSuperview {
    %orig;
    if (self.superview) {
        [self.superview bringSubviewToFront:self];
    }
}

- (void)layoutSubviews {
    %orig;
    if (self.superview) {
        [self.superview bringSubviewToFront:self];
    }
}

%end

%end

%ctor {
    if (!LGIsSpringBoardProcess()) return;
    %init(FolderHooks);
}
