//
//  PresentTransformAnimation.m
//  AnimationTransitions
//
//  Created by 蓝云 on 2017/5/18.
//  Copyright © 2017年 yangzhi. All rights reserved.
//

#import "PresentTransformAnimation.h"
#import "UIView+KGViewExtend.h"

@interface PresentTransformAnimation ()

@property (nonatomic, assign) PresentTransformAnimationType type;

@end

@implementation PresentTransformAnimation

+ (instancetype)makeWithTransitionType:(PresentTransformAnimationType)type isHorizontal:(BOOL)isH
{
    return [[self alloc] initWithTransitionType:type isHorizontal:isH];
}

- (instancetype)initWithTransitionType:(PresentTransformAnimationType)type isHorizontal:(BOOL)isH
{
    if (self == [super init]) {
        _type = type;
        _isHorizontal = isH;
    }
    return self;
}

- (NSTimeInterval)transitionDuration:(nullable id <UIViewControllerContextTransitioning>)transitionContext
{
    return .5;
}


- (void)animateTransition:(id <UIViewControllerContextTransitioning>)transitionContext
{
    switch (_type) {
        case PresentTransformAnimationTypePresent:
            [self presentTransform:transitionContext];
            break;
        case PresentTransformAnimationTypeDismissed:
            [self dismissTransform:transitionContext];
            break;
        default:
            break;
    }

}

- (void)presentTransform:(id<UIViewControllerContextTransitioning>)transitionContext
{
    UIViewController *fromVC = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    UIViewController *toVC = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    //获取一个UIView的快照
    UIView *tempView = [fromVC.view snapshotViewAfterScreenUpdates:NO];
    tempView.frame = fromVC.view.frame;
    
    UIView *maskView = [[UIView alloc] init];
    [maskView setFrame:CGRectMake(0, 0, tempView.width, tempView.height)];
    [maskView setBackgroundColor:[UIColor lightGrayColor]];
    maskView.alpha = 0.0;
    maskView.tag = 99;
    [tempView addSubview:maskView];
    
    CGRect screenBounds = [[UIScreen mainScreen] bounds];
    CGRect finalFrame = [transitionContext finalFrameForViewController:toVC];
    toVC.view.frame = CGRectOffset(finalFrame, 0, screenBounds.size.height);
    fromVC.view.hidden = YES;
    
    UIView *containerView = [transitionContext containerView];
    [containerView addSubview:tempView];
    [containerView addSubview:toVC.view];
    
    NSTimeInterval duration = [self transitionDuration:transitionContext];
    [UIView animateWithDuration:duration
                          delay:0.0
         usingSpringWithDamping:0.8
          initialSpringVelocity:0.0
                        options:UIViewAnimationOptionCurveLinear
                     animations:^{
                         maskView.alpha = 0.8;
                         toVC.view.transform = CGAffineTransformMakeTranslation(0, -SCREENHEIGHT);
                         //然后让截图视图缩小一点即可
                         //tempView.transform = CGAffineTransformMakeScale(0.9, 0.9);
                     } completion:^(BOOL finished) {
                         [transitionContext completeTransition:YES];
                     }];
}

- (void)dismissTransform:(id<UIViewControllerContextTransitioning>)transitionContext
{
    //注意在dismiss的时候fromVC就是vc2了，toVC才是VC1了，注意理解这个逻辑关系
    UIViewController *fromVC = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    UIViewController *toVC = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    
    //参照present动画的逻辑，present成功后，containerView的最后一个子视图就是截图视图，我们将其取出准备动画
    UIView *containerView = [transitionContext containerView];
    NSArray *subviewsArray = containerView.subviews;
    UIView *tempView = subviewsArray[MIN(subviewsArray.count, MAX(0, subviewsArray.count - 2))];
    
    UIView *maskView = [tempView viewWithTag:99];
    
    //动画吧
    [UIView animateWithDuration:[self transitionDuration:transitionContext] animations:^{
        //因为present的时候都是使用的transform，这里的动画只需要将transform恢复就可以了
        maskView.alpha = 0;
        
        tempView.transform = CGAffineTransformIdentity;
        if (_isHorizontal) {
            fromVC.view.transform = CGAffineTransformMakeTranslation(SCREENWIDTH, -SCREENHEIGHT);
        }else{
            fromVC.view.transform = CGAffineTransformIdentity;
        }
    } completion:^(BOOL finished) {

        if ([transitionContext transitionWasCancelled]) {
            //失败了接标记失败
            [transitionContext completeTransition:NO];
        }else{
            //如果成功了，我们需要标记成功，同时让vc1显示出来，然后移除截图视图，
            [transitionContext completeTransition:YES];
            toVC.view.hidden = NO;
            [tempView removeFromSuperview];
        }
    }];
}



@end
