#ifdef __OBJC__
#import <UIKit/UIKit.h>
#else
#ifndef FOUNDATION_EXPORT
#if defined(__cplusplus)
#define FOUNDATION_EXPORT extern "C"
#else
#define FOUNDATION_EXPORT extern
#endif
#endif
#endif

#import "DeviceUtil+Constant.h"
#import "DeviceUtil.h"

FOUNDATION_EXPORT double DeviceUtilVersionNumber;
FOUNDATION_EXPORT const unsigned char DeviceUtilVersionString[];

