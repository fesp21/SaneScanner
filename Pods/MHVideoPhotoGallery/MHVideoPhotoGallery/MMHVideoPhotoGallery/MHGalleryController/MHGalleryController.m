//
//  MHGalleryController.m
//  MHVideoPhotoGallery
//
//  Created by Mario Hahn on 01.04.14.
//  Copyright (c) 2014 Mario Hahn. All rights reserved.
//

#import "MHGalleryController.h"


@implementation MHGalleryController

- (id)initWithPresentationStyle:(MHGalleryViewMode)presentationStyle {
    self = [self initWithPresentationStyle:presentationStyle UICustomization:MHUICustomization.new];
    return self;
}

- (id)initWithPresentationStyle:(MHGalleryViewMode)presentationStyle UICustomization:(MHUICustomization *)UICustomization {
    self = [super initWithNibName:nil bundle:nil];
    if (!self)
        return nil;
    
    self.autoplayVideos = NO;

    self.preferredStatusBarStyleMH = UIStatusBarStyleDefault;
    self.presentationStyle = presentationStyle;
    self.transitionCustomization = MHTransitionCustomization.new;
    self.UICustomization = UICustomization ?: MHUICustomization.new;
    
    self.overViewViewController= MHOverviewController.new;
    self.imageViewerViewController = MHGalleryImageViewerViewController.new;
    
    if (presentationStyle != MHGalleryViewModeOverView) {
        self.viewControllers = @[self.overViewViewController,self.imageViewerViewController];
    }else{
        self.viewControllers = @[self.overViewViewController];
    }
    return self;
}

+(instancetype)galleryWithPresentationStyle:(MHGalleryViewMode)presentationStyle{
    return [self.class.alloc initWithPresentationStyle:presentationStyle];
}

+(instancetype)galleryWithPresentationStyle:(MHGalleryViewMode)presentationStyle UICustomization:(MHUICustomization *)UICustomization{
    return [self.class.alloc initWithPresentationStyle:presentationStyle UICustomization:UICustomization];
}

-(void)setGalleryItems:(NSArray *)galleryItems{
    [self setDataSource:self];
    
    if (!galleryItems.count)
        _galleryItems = @[[MHGalleryItem itemWithImage:UIImage.new]];
    else
        _galleryItems = galleryItems;
    
    self.overViewViewController.galleryItems = _galleryItems;
    self.imageViewerViewController.galleryItems = _galleryItems;

    [self reloadData];
}

-(void)setPresentationIndex:(NSInteger)presentationIndex{
    self.imageViewerViewController.pageIndex = presentationIndex;
    _presentationIndex = presentationIndex;
}

-(void)setPresentingFromImageView:(UIImageView *)presentingFromImageView{
    self.imageViewerViewController.presentingFromImageView = presentingFromImageView;
    _presentingFromImageView = presentingFromImageView;
}
-(void)setInteractivePresentationTransition:(MHTransitionPresentMHGallery *)interactivePresentationTranstion{
    self.imageViewerViewController.interactivePresentationTranstion = interactivePresentationTranstion;
    _interactivePresentationTransition = interactivePresentationTranstion;
}

-(MHGalleryItem *)itemForIndex:(NSInteger)index{
    if (index < 0 || index >= [self numberOfItemsInGallery:self]) {
        return nil;
    }
    return self.galleryItems[index];
}
-(NSInteger)numberOfItemsInGallery:(MHGalleryController *)galleryController{
    return self.galleryItems.count;
}

-(void)reloadData {
    // checks are needed to be sure views have been loaded
    
    if (self.imageViewerViewController.toolbar)
        [self.imageViewerViewController reloadData];
    
    if (self.overViewViewController.collectionView)
        [self.overViewViewController reloadData];
}

- (BOOL)isShowingOverview
{
    return (self.topViewController == self.overViewViewController);
}

- (void)openOverview
{
    if (![self isShowingOverview])
        [self popViewControllerAnimated:NO];
}

- (void)openImageViewForPage:(NSInteger)page
{
    if (page < 0 || page >= self.galleryItems.count)
        return;
    
    if ([self isShowingOverview])
        [self.overViewViewController pushToImageViewerForIndexPath:[NSIndexPath indexPathForItem:page inSection:0]];
    else
    {
        [self.imageViewerViewController setPageIndex:page];
        [self.imageViewerViewController reloadData];
    }
}

@end


@implementation UIViewController(MHGalleryViewController)

-(void)presentMHGalleryController:(MHGalleryController *)galleryController
                         animated:(BOOL)animated
                       completion:(void (^)(void))completion{

    if(galleryController.UICustomization.useCustomBackButtonImageOnImageViewer){
        UIBarButtonItem *backBarButton = [UIBarButtonItem.alloc initWithImage:MHTemplateImage(@"ic_square")
                                                                        style:UIBarButtonItemStylePlain
                                                                       target:self
                                                                       action:nil];
        galleryController.overViewViewController.navigationItem.backBarButtonItem = backBarButton;
        galleryController.navigationBar.tintColor = galleryController.UICustomization.barButtonsTintColor;
    }
    
    if (galleryController.transitionCustomization.interactiveDismiss) {
        galleryController.transitioningDelegate = self;
        galleryController.modalPresentationStyle = UIModalPresentationFullScreen;
    }else{
        galleryController.transitionCustomization.interactiveDismiss = NO;
        galleryController.transitionCustomization.dismissWithScrollGestureOnFirstAndLastImage = NO;
    }
    galleryController.navigationBar.barStyle = galleryController.UICustomization.barStyle;
    galleryController.navigationBar.barTintColor = galleryController.UICustomization.barTintColor;
    
    if (!galleryController.dataSource) {
        galleryController.dataSource = galleryController;
    }
    if (galleryController.presentationStyle == MHGalleryViewModeImageViewerNavigationBarHidden) {
        galleryController.imageViewerViewController.hiddingToolBarAndNavigationBar = YES;
    }
    [self presentViewController:galleryController animated:animated completion:completion];
}


- (void)dismissViewControllerAnimated:(BOOL)flag dismissImageView:(UIImageView*)dismissImageView completion:(void (^)(void))completion{
    if ([self isKindOfClass:[UINavigationController class]] && [[(UINavigationController*)self viewControllers].lastObject isKindOfClass:MHGalleryImageViewerViewController.class]) {
        MHGalleryImageViewerViewController *imageViewer = [(UINavigationController*)self viewControllers].lastObject;
        imageViewer.dismissFromImageView = dismissImageView;
    }
    [self dismissViewControllerAnimated:flag completion:completion];
}


-(id<UIViewControllerInteractiveTransitioning>)interactionControllerForPresentation:(id<UIViewControllerAnimatedTransitioning>)animator{
    if ([animator isKindOfClass:MHTransitionPresentMHGallery.class]) {
        MHTransitionPresentMHGallery *animatorPresent = (MHTransitionPresentMHGallery*)animator;
        if (animatorPresent.interactive) {
            return animatorPresent;
        }
        return nil;
    }else {
        return nil;
    }
}

-(id<UIViewControllerInteractiveTransitioning>)interactionControllerForDismissal:(id<UIViewControllerAnimatedTransitioning>)animator{
    if ([animator isKindOfClass:MHTransitionDismissMHGallery.class]) {
        MHTransitionDismissMHGallery *animatorDismiss = (MHTransitionDismissMHGallery*)animator;
        if (animatorDismiss.interactive) {
            return animatorDismiss;
        }
        return nil;
    }else {
        return nil;
    }
}


-(id<UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(UIViewController *)dismissed{
    if ([dismissed isKindOfClass:[UINavigationController class]] && [[(UINavigationController*)dismissed  viewControllers].lastObject isKindOfClass:MHGalleryImageViewerViewController.class]) {
        MHGalleryImageViewerViewController *imageViewer = [(UINavigationController*)dismissed  viewControllers].lastObject;
        MHImageViewController *viewer = imageViewer.pageViewController.viewControllers.firstObject;
        
        if (!imageViewer.dismissFromImageView && viewer.interactiveTransition.finishButtonAction) {
            return nil;
        }
        
        if (viewer.interactiveTransition) {
            MHTransitionDismissMHGallery *detail = viewer.interactiveTransition;
            detail.transitionImageView = imageViewer.dismissFromImageView;
            return detail;
        }
        
        MHTransitionDismissMHGallery *detail = MHTransitionDismissMHGallery.new;
        detail.transitionImageView = imageViewer.dismissFromImageView;
        return detail;
    }
    return nil;
}

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented
                                                                  presentingController:(UIViewController *)presenting
                                                                      sourceController:(UIViewController *)source {
    UINavigationController *nav = (UINavigationController*)presented;
    if ([nav isKindOfClass:[UINavigationController class]] && [nav.viewControllers.lastObject  isKindOfClass:MHGalleryImageViewerViewController.class]) {
        MHGalleryImageViewerViewController *imageViewer = nav.viewControllers.lastObject;
        if (imageViewer.interactivePresentationTranstion) {
            MHTransitionPresentMHGallery *detail = imageViewer.interactivePresentationTranstion;
            detail.presentingImageView = imageViewer.presentingFromImageView;
            return detail;
        }
        MHTransitionPresentMHGallery *detail = MHTransitionPresentMHGallery.new;
        detail.presentingImageView = imageViewer.presentingFromImageView;
        return detail;
    }
    return nil;
}

@end
