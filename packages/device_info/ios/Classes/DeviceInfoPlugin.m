// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "DeviceInfoPlugin.h"
#import "SAMKeychain.h"
#import "SAMKeychainQuery.h"
#import <sys/utsname.h>

@implementation FLTDeviceInfoPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
    FlutterMethodChannel* channel =
    [FlutterMethodChannel methodChannelWithName:@"plugins.flutter.io/device_info"
                                binaryMessenger:[registrar messenger]];
    FLTDeviceInfoPlugin* instance = [[FLTDeviceInfoPlugin alloc] init];
    [registrar addMethodCallDelegate:instance channel:channel];
}

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
    if ([@"getIosDeviceInfo" isEqualToString:call.method]) {
        UIDevice* device = [UIDevice currentDevice];
        struct utsname un;
        uname(&un);
        
        NSString *bundleName = [[[NSBundle mainBundle] infoDictionary] objectForKey:(NSString *) kCFBundleNameKey];
        NSString *accountName = [[NSBundle mainBundle] bundleIdentifier];
        
        NSError *error = nil;
        NSString *uuid = [SAMKeychain passwordForService:bundleName account:accountName error: &error];
        if([error code] == SAMKeychainErrorBadArguments || [uuid length] == 0){
            uuid = [[device identifierForVendor] UUIDString];
            SAMKeychainQuery *query = [[SAMKeychainQuery alloc] init];
            query.service = bundleName;
            query.account = accountName;
            query.password = uuid;
            query.synchronizationMode = SAMKeychainQuerySynchronizationModeNo;
            
            
            [query save:&error];
            if(error != nil){
                NSLog(@"Some other error occurred: %@", [error localizedDescription]);
            }
        }
        
        result(@{
            @"name" : [device name],
            @"systemName" : [device systemName],
            @"systemVersion" : [device systemVersion],
            @"model" : [device model],
            @"localizedModel" : [device localizedModel],
            @"identifierForVendor" : uuid,
            @"isPhysicalDevice" : [self isDevicePhysical],
            @"utsname" : @{
                    @"sysname" : @(un.sysname),
                    @"nodename" : @(un.nodename),
                    @"release" : @(un.release),
                    @"version" : @(un.version),
                    @"machine" : @(un.machine),
            }
        });
    } else {
        result(FlutterMethodNotImplemented);
    }
}

// return value is false if code is run on a simulator
- (NSString*)isDevicePhysical {
#if TARGET_OS_SIMULATOR
    NSString* isPhysicalDevice = @"false";
#else
    NSString* isPhysicalDevice = @"true";
#endif
    
    return isPhysicalDevice;
}

@end
