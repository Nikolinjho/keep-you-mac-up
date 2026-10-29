//
//  NSImage+KYAStatusItemImage.m
//  KYAStatusItemUI
//
//  Created by Marcel Dierkes on 30.04.22.
//

#import "NSImage+KYAStatusItemImage.h"
#import <KYACommon/KYACommon.h>
#import "NSURL+KYAStatusItemImage.h"

const NSImageName KYAStatusItemActiveImageName = @"ActiveIcon";
const NSImageName KYAStatusItemInactiveImageName = @"InactiveIcon";

static NSImage *KYACreateMacBookStatusImage(BOOL active)
{
    NSImage *reference = [NSImage imageNamed:@"MacBookGisela"];
    NSImage *image = [NSImage imageWithSize:NSMakeSize(22, 18) flipped:NO
                           drawingHandler:^BOOL(NSRect rect) {
        if (active) {
            [NSColor.blackColor setFill];
            NSRectFill(NSMakeRect(3.0, 4.15, 15.9, 10.8));
        }
        // Поля исходника обрезаем при отрисовке, сохраняя пропорции и камеру.
        [reference drawInRect:NSMakeRect(0, 2, 22, 13.75)
                    fromRect:NSMakeRect(0, 96, 512, 320)
                   operation:NSCompositingOperationSourceOver fraction:1.0];
        return YES;
    }];
    image.template = YES;
    image.accessibilityDescription = active ? @"KeepYouAwake active" : @"KeepYouAwake inactive";
    return image;
}

@implementation NSImage (KYAStatusItemImage)

#pragma mark - Default Icon Images

+ (NSImage *)kya_defaultActiveIconImage
{
    return KYACreateMacBookStatusImage(YES);
}

+ (NSImage *)kya_defaultInactiveIconImage
{
    return KYACreateMacBookStatusImage(NO);
}

#pragma mark - Custom Icon Images

+ (NSImage *)kya_customActiveIconImage
{
    return [self customIconNamed:KYAStatusItemActiveImageName];
}

+ (NSImage *)kya_customInactiveIconImage
{
    return [self customIconNamed:KYAStatusItemInactiveImageName];
}

#pragma mark -

+ (NSImage *)customIconNamed:(NSImageName)imageName
{
    NSParameterAssert(imageName);
    
    Auto fileURL = [NSURL kya_iconImageFileURLWithName:imageName isRetinaIcon:NO];
    Auto image = [[NSImage alloc] initWithContentsOfURL:fileURL];
    image.template = YES;
    
    Auto retinaFileURL = [NSURL kya_iconImageFileURLWithName:imageName isRetinaIcon:YES];
    Auto retinaRep = [NSImageRep imageRepWithContentsOfURL:retinaFileURL];
    if(retinaRep != nil)
    {
        [image addRepresentation:retinaRep];
    }
    
    return image;
}

@end

BOOL KYACustomIconImageFilesExist()
{
    return KYACustomIconImageFileExists(KYAStatusItemActiveImageName, NO)
    && KYACustomIconImageFileExists(KYAStatusItemActiveImageName, YES)
    && KYACustomIconImageFileExists(KYAStatusItemInactiveImageName, NO)
    && KYACustomIconImageFileExists(KYAStatusItemInactiveImageName, YES);
}
