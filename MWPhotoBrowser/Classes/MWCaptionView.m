//
//  MWCaptionView.m
//  MWPhotoBrowser
//
//  Created by Michael Waterfall on 30/12/2011.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "MWCommon.h"
#import "MWCaptionView.h"
#import "MWPhoto.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import "UIImageView+Letters.h"

static const CGFloat labelPadding = 10;

// Private
@interface MWCaptionView () {
    id <MWPhoto> _photo;
    UILabel *_label;
    UIImageView* _avatar;
}
@end

@implementation MWCaptionView

- (id)initWithPhoto:(id<MWPhoto>)photo {
    self = [super initWithFrame:CGRectMake(0, 0, 320, 44)]; // Random initial frame
    if (self) {
        self.userInteractionEnabled = NO;
        _photo = photo;
        if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7")) {
            // Use iOS 7 blurry goodness
            self.barStyle = UIBarStyleBlackTranslucent;
            self.tintColor = nil;
            self.barTintColor = nil;
            self.barStyle = UIBarStyleBlackTranslucent;
            [self setBackgroundImage:nil forToolbarPosition:UIBarPositionAny barMetrics:UIBarMetricsDefault];
        } else {
            // Transparent black with no gloss
            CGRect rect = CGRectMake(0.0f, 0.0f, 1.0f, 1.0f);
            UIGraphicsBeginImageContext(rect.size);
            CGContextRef context = UIGraphicsGetCurrentContext();
            CGContextSetFillColorWithColor(context, [[UIColor colorWithWhite:0 alpha:0.6] CGColor]);
            CGContextFillRect(context, rect);
            UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
            UIGraphicsEndImageContext();
            [self setBackgroundImage:image forToolbarPosition:UIBarPositionAny barMetrics:UIBarMetricsDefault];
        }
        //self.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin;

        self.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin;
        [self setupAvatar];
        [self setupCaption];
    }
    return self;
}

- (CGSize)sizeThatFits:(CGSize)size {
    CGFloat maxHeight = 9999;
    if (_label.numberOfLines > 0) maxHeight = _label.font.leading*_label.numberOfLines;
    CGSize textSize;
    if ([NSString instancesRespondToSelector:@selector(boundingRectWithSize:options:attributes:context:)]) {
        textSize = [_label.text boundingRectWithSize:CGSizeMake(size.width - labelPadding*2, maxHeight)
                                             options:NSStringDrawingUsesLineFragmentOrigin
                                          attributes:@{NSFontAttributeName:_label.font}
                                             context:nil].size;
    } else {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        textSize = [_label.text sizeWithFont:_label.font
                           constrainedToSize:CGSizeMake(size.width - labelPadding*2, maxHeight)
                               lineBreakMode:_label.lineBreakMode];
#pragma clang diagnostic pop
    }
    return CGSizeMake(size.width, textSize.height + labelPadding * 2);
}

-(void)setupAvatar {

    if ([_photo respondsToSelector:@selector(getAvatarUrl)]) {

        CGFloat size = MIN(32, self.bounds.size.height - labelPadding);
        _avatar = [[UIImageView alloc] initWithFrame:CGRectIntegral(CGRectMake(labelPadding, (self.bounds.size.height - size) / 2, size, size))];
        _avatar.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
        _avatar.opaque = NO;

        [[_avatar layer] setBorderColor:[[UIColor whiteColor] CGColor]];
        [[_avatar layer] setBorderWidth:0.3];
        [[_avatar layer] setCornerRadius: [_avatar bounds].size.width / 2];
        [_avatar setContentMode: UIViewContentModeScaleAspectFit];
        [_avatar setClipsToBounds:YES];
        [self addSubview: _avatar];

        id avatarUrl = [_photo performSelector:@selector(getAvatarUrl)];

        if (avatarUrl != nil) {
            [_avatar sd_setImageWithURL:avatarUrl];
        } else if ([_photo respondsToSelector:@selector(getNickname)] && [_photo respondsToSelector:@selector(getAvatarColor)]) {
            id nickname = [_photo performSelector:@selector(getNickname)];
            if (nickname == nil) {
                if ([_photo respondsToSelector:@selector(getAnonymousAvatar)]) {
                    id image = [_photo performSelector:@selector(getAnonymousAvatar)];
                    [_avatar setImage:image];
                }
            } else {
                id color = [_photo performSelector:@selector(getAvatarColor)];
                if (color != nil) {
                    [_avatar setImageWithString:nickname color:color circular:true];
                }
            }
        }


        if ([_photo respondsToSelector:@selector(showProfile)]) {
            UITapGestureRecognizer* tap = [[UITapGestureRecognizer alloc] initWithTarget:_photo action:@selector(showProfile)];
            [tap setNumberOfTapsRequired:1];
            [tap setNumberOfTouchesRequired:1];
            [self setUserInteractionEnabled:YES];
            [_avatar setUserInteractionEnabled:YES];
            [_avatar addGestureRecognizer:tap];
        }
        
    }

}

- (void)setupCaption {

    int avatarPadding = 0;

    if (_avatar != nil) {
        avatarPadding += [_avatar bounds].size.width + labelPadding;
    }

    _label = [[UILabel alloc] initWithFrame:CGRectIntegral(CGRectMake(labelPadding + avatarPadding, 0,
                                                       self.bounds.size.width - labelPadding * 2 - avatarPadding,
                                                       self.bounds.size.height))];
    _label.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
    _label.opaque = NO;
    _label.backgroundColor = [UIColor clearColor];
    if (SYSTEM_VERSION_LESS_THAN(@"6")) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        _label.textAlignment = UITextAlignmentCenter;
        _label.lineBreakMode = UILineBreakModeWordWrap;
#pragma clang diagnostic pop
    } else {
        _label.textAlignment = NSTextAlignmentCenter;
        _label.lineBreakMode = NSLineBreakByWordWrapping;
    }

    _label.numberOfLines = 0;
    _label.textColor = [UIColor whiteColor];
    if (SYSTEM_VERSION_LESS_THAN(@"7")) {
        // Shadow on 6 and below
        _label.shadowColor = [UIColor blackColor];
        _label.shadowOffset = CGSizeMake(1, 1);
    }
    _label.font = [UIFont systemFontOfSize:17];
    if ([_photo respondsToSelector:@selector(caption)]) {
        _label.text = [_photo caption] ? [_photo caption] : @" ";
    }
    [self addSubview:_label];
}


@end
