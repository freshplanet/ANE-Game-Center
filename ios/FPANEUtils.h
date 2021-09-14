/*
 * Copyright 2017 FreshPlanet
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
#import <Foundation/Foundation.h>
#import "FlashRuntimeExtensions.h"
#if TARGET_OS_IPHONE
    #import <UIKit/UIKit.h>
#elif TARGET_OS_OSX
    #import <AppKit/AppKit.h>
    #import <Cocoa/Cocoa.h>
#endif

#define DEFINE_ANE_FUNCTION(fn) FREObject fn(FREContext context, void* functionData, uint32_t argc, FREObject argv[])
#define MAP_FUNCTION(fn, data) { (const uint8_t*)(#fn), (data), &(fn) }
#define ROOT_VIEW_CONTROLLER [[[UIApplication sharedApplication] keyWindow] rootViewController]

void AirGameCenter_FPANE_DispatchEvent(FREContext context, NSString* eventName);
void AirGameCenter_FPANE_DispatchEventWithInfo(FREContext context, NSString* eventName, NSString* eventInfo);
void AirGameCenter_FPANE_Log(FREContext context, NSString* message);

NSString* AirGameCenter_FPANE_FREObjectToNSString(FREObject object);
NSArray* AirGameCenter_FPANE_FREObjectToNSArrayOfNSString(FREObject object);
NSDictionary* AirGameCenter_FPANE_FREObjectsToNSDictionaryOfNSString(FREObject keys, FREObject values);
BOOL AirGameCenter_FPANE_FREObjectToBool(FREObject object);
NSInteger AirGameCenter_FPANE_FREObjectToInt(FREObject object);
double AirGameCenter_FPANE_FREObjectToDouble(FREObject object);

FREObject AirGameCenter_FPANE_BOOLToFREObject(BOOL boolean);
FREObject AirGameCenter_FPANE_IntToFREObject(NSInteger i);
FREObject AirGameCenter_FPANE_DoubleToFREObject(double d);
FREObject AirGameCenter_FPANE_NSStringToFREObject(NSString* string);
FREObject AirGameCenter_FPANE_CreateError(NSString* error, NSInteger* id);
#if TARGET_OS_IPHONE
FREObject AirGameCenter_FPANE_UIImageToFREBitmapData(UIImage *image);
UIImage* AirGameCenter_FPANE_FREBitmapDataToUIImage(FREObject object);
#elif TARGET_OS_OSX
FREObject AirGameCenter_FPANE_NSImageToFREBitmapData(NSImage *image);
#endif

NSArray* AirGameCenter_FPANE_FREObjectToNSArrayOfUIImage(FREObject object);
