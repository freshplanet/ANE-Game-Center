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

#import "AirGameCenter.h"
#import "Constants.h"

@interface AirGameCenter ()
@property (nonatomic, readonly) FREContext context;
@end

@implementation AirGameCenter

- (instancetype)initWithContext:(FREContext)extensionContext {
    
    if ((self = [super init])) {
        
        _context = extensionContext;
        _playerPhotos = [[NSMutableDictionary alloc] init];
    }
    
    return self;
}

- (void) sendLog:(NSString*)log {
    [self sendEvent:@"log" level:log];
}

- (void) sendEvent:(NSString*)code {
    [self sendEvent:code level:@""];
}

- (void) sendEvent:(NSString*)code level:(NSString*)level {
    FREDispatchStatusEventAsync(_context, (const uint8_t*)[code UTF8String], (const uint8_t*)[level UTF8String]);
}

#if TARGET_OS_IPHONE
- (void) storePlayerPhoto:(NSString*)playerId playerPhoto:(UIImage *)photo
{
    [_playerPhotos setObject:photo forKey:playerId];
}
- (UIImage *) getStoredPlayerPhoto:(NSString*)playerId
{
    return [_playerPhotos valueForKey:playerId];
}
#elif TARGET_OS_OSX
- (void) storePlayerPhoto:(NSString*)playerId playerPhoto:(NSImage *)photo
{
    [_playerPhotos setObject:photo forKey:playerId];
}
- (NSImage *) getStoredPlayerPhoto:(NSString*)playerId
{
    return [_playerPhotos valueForKey:playerId];
}
#endif





- (void) gameCenterViewControllerDidFinish:(GKGameCenterViewController *)gameCenterViewController {
#if TARGET_OS_IPHONE
    [gameCenterViewController dismissViewControllerAnimated:true completion:nil];
#elif TARGET_OS_OSX
    [[GKDialogController sharedDialogController] dismiss:gameCenterViewController];
#endif
}

@end

NSString* dictionaryToNSString(NSDictionary *dictionary){
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dictionary
                                                       options:NSJSONWritingPrettyPrinted // Pass 0 if you don't care about the readability of the generated string
                                                         error:&error];
    if (! jsonData) {
        return @"";
    } else {
        return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    }
}

NSString* createPhotoLoadErrorString(NSString *playerId, NSString *error){
    
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    [dict setValue:playerId forKey:@"playerId"];
    [dict setValue:error forKey:@"error"];
    
    return dictionaryToNSString(dict);
}

NSDictionary* playerToDictionary (GKPlayer *player){
    
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    [dict setValue:player.playerID forKey:@"id"];
    [dict setValue:player.alias forKey:@"alias"];
    [dict setValue:player.displayName forKey:@"displayName"];
    
    return dict;
}

NSDictionary* scoreToDictionary (GKScore *score){
    
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    [dict setValue:score.leaderboardIdentifier forKey:@"leaderboardId"];
    [dict setValue:[NSNumber numberWithUnsignedInteger:score.value] forKey:@"value"];
    [dict setValue:score.formattedValue forKey:@"formattedValue"];
    [dict setValue:[NSNumber numberWithUnsignedInteger:score.date.timeIntervalSince1970] forKey:@"date"];
    [dict setValue:[NSNumber numberWithUnsignedInteger:score.rank] forKey:@"rank"];
    [dict setValue:playerToDictionary(score.player) forKey:@"player"];
    
    return dict;
}

NSDictionary* leaderboardToDictionary (GKLeaderboard *leaderboard){
    
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    [dict setValue:[NSNumber numberWithInt:leaderboard.timeScope] forKey:@"timeScope"];
    [dict setValue:[NSNumber numberWithInt:leaderboard.playerScope] forKey:@"playerScope"];
    [dict setValue:leaderboard.identifier forKey:@"identifier"];
    [dict setValue:leaderboard.title forKey:@"title"];
    [dict setValue:[NSNumber numberWithUnsignedInteger:leaderboard.range.location] forKey:@"rangeLocation"];
    [dict setValue:[NSNumber numberWithUnsignedInteger:leaderboard.range.length] forKey:@"rangeLength"];
    [dict setValue:[NSNumber numberWithUnsignedInteger:leaderboard.maxRange] forKey:@"maxRange"];
    
    NSMutableArray *scoresArray = [[NSMutableArray alloc] init];
    
    for (GKScore* score in leaderboard.scores)
    {
        NSDictionary *scoreDict = scoreToDictionary(score);
        [scoresArray addObject:scoreDict];
    }
    [dict setValue:scoresArray forKey:@"scores"];
    [dict setValue:leaderboard.localPlayerScore == nil ? nil : scoreToDictionary(leaderboard.localPlayerScore) forKey:@"localPlayerScore"];
    
    return dict;
}

NSDictionary* achievementToDictionary (GKAchievement *achievement){
    
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    [dict setValue:achievement.identifier forKey:@"identifier"];
    [dict setValue:[NSNumber numberWithDouble:achievement.percentComplete] forKey:@"percentComplete"];
    [dict setValue:[NSNumber numberWithBool:achievement.completed] forKey:@"completed"];
    [dict setValue:[NSNumber numberWithUnsignedInteger:achievement.lastReportedDate.timeIntervalSince1970] forKey:@"lastReportedDate"];
    return dict;
}

NSArray* leaderboardsToDictionaryArray (NSArray *leaderboards){
    
    NSMutableArray *leaderboardsArray = [[NSMutableArray alloc] init];
    for (GKLeaderboard* leaderboard in leaderboards)
    {
        NSDictionary *leaderboardDict = leaderboardToDictionary(leaderboard);
        [leaderboardsArray addObject:leaderboardDict];
    }
    
    return leaderboardsArray;
    
}

AirGameCenter* GetAirGameCenterContextNativeData(FREContext context) {
    
    CFTypeRef controller;
    FREGetContextNativeData(context, (void**)&controller);
    return (__bridge AirGameCenter*)controller;
}

DEFINE_ANE_FUNCTION(authenticateLocalPlayer) {
    
    AirGameCenter* controller = GetAirGameCenterContextNativeData(context);
    
    if (!controller)
        return AirGameCenter_FPANE_CreateError(@"context's AirGameCenter is null", 0);
    
    
    @try {
        GKLocalPlayer* localPlayer = [GKLocalPlayer localPlayer];
        if (localPlayer.authenticated) {
            [controller sendEvent:kAirGameCenterEvent_authenticated];
        }
        else {
#if TARGET_OS_IPHONE
            localPlayer.authenticateHandler = ^(UIViewController *viewController, NSError *error) {
                
                if (viewController != nil)
                {
                    UIViewController* rootViewController = [[[UIApplication sharedApplication] keyWindow] rootViewController];
                    
                    [rootViewController presentViewController:viewController animated:YES completion:^{
                        NSLog(@"Finished Presenting Authentication Controller");
                    }];
                }
                else if (error != nil)
                {
                    [controller sendLog:error.localizedDescription];
                    [controller sendEvent:kAirGameCenterEvent_authenticationFailed level:error.localizedDescription];
                }
                else if ([GKLocalPlayer localPlayer].authenticated)
                {
                    [controller sendLog:@"Authentication Success"];
                    [controller sendEvent:kAirGameCenterEvent_authenticated];
                }
                else
                {
                    [controller sendLog:@"Authentication failed"];
                    [controller sendEvent:kAirGameCenterEvent_authenticationFailed level:@"Unknown authentication error"];
                }
            };
#elif TARGET_OS_OSX
            
            localPlayer.authenticateHandler = ^(NSViewController *viewController, NSError *error) {
                if (viewController != nil)
                {
                    
                    NSWindowController* rootViewController = [[[NSApplication sharedApplication] keyWindow] windowController];

                    [rootViewController.contentViewController presentViewControllerAsModalWindow:viewController];
                
                }
                else if (error != nil)
                {
                    [controller sendLog:error.localizedDescription];
                    [controller sendEvent:kAirGameCenterEvent_authenticationFailed level:error.localizedDescription];
                }
                else if ([GKLocalPlayer localPlayer].authenticated)
                {
                    [controller sendLog:@"Authentication Success"];
                    [controller sendEvent:kAirGameCenterEvent_authenticated];
                }
                else
                {
                    [controller sendLog:@"Authentication failed"];
                    [controller sendEvent:kAirGameCenterEvent_authenticationFailed level:@"Unknown authentication error"];
                }
                
            };
#endif
            
        }
        
    }
    @catch (NSException *exception) {
        [controller sendLog:[@"Exception occured while trying to authenticateLocalPlayer : " stringByAppendingString:exception.reason]];
    }
    
    
    return nil;
}

DEFINE_ANE_FUNCTION(isAuthenticated) {
    
    BOOL isAuthenticated = [GKLocalPlayer localPlayer].authenticated;
    return AirGameCenter_FPANE_BOOLToFREObject(isAuthenticated);

}

DEFINE_ANE_FUNCTION(getLocalPlayer) {

    AirGameCenter* controller = GetAirGameCenterContextNativeData(context);
    
    if (!controller)
        return AirGameCenter_FPANE_CreateError(@"context's AirGameCenter is null", 0);
    
    GKLocalPlayer* localPlayer = [GKLocalPlayer localPlayer];
    if ( localPlayer && localPlayer.isAuthenticated )
    {
        NSDictionary *playerDict = playerToDictionary((GKPlayer*)localPlayer);//[[NSMutableDictionary alloc] init];
        NSString *playerString = dictionaryToNSString(playerDict);
        return AirGameCenter_FPANE_NSStringToFREObject(playerString);
        
    }
    else
    {
        return nil;
    }
    
    
}



DEFINE_ANE_FUNCTION(getStoredPlayerPhoto) {
    
    AirGameCenter* controller = GetAirGameCenterContextNativeData(context);
    
    if (!controller)
        return AirGameCenter_FPANE_CreateError(@"context's AirGameCenter is null", 0);
    
    @try {
        NSString *playerId = AirGameCenter_FPANE_FREObjectToNSString((argv[0]));
#if TARGET_OS_IPHONE
        UIImage *photo = [controller getStoredPlayerPhoto:playerId];
        if (photo != nil) {
            return AirGameCenter_FPANE_UIImageToFREBitmapData(photo);
        }
#elif TARGET_OS_OSX
        NSImage *photo = [controller getStoredPlayerPhoto:playerId];
        if (photo != nil) {
            return AirGameCenter_FPANE_NSImageToFREBitmapData(photo);
        }
#endif
        
    }
    @catch (NSException *exception) {
        [controller sendLog:[@"Exception occured while trying to load player photo : " stringByAppendingString:exception.reason]];
        
    }
    
    
    return nil;
}

DEFINE_ANE_FUNCTION(loadLeaderboards) {
    
    AirGameCenter* controller = GetAirGameCenterContextNativeData(context);
    
    if (!controller)
        return AirGameCenter_FPANE_CreateError(@"context's AirGameCenter is null", 0);
    
   [GKLeaderboard loadLeaderboardsWithCompletionHandler:^(NSArray<GKLeaderboard *> * _Nullable leaderboards, NSError * _Nullable error) {
      
       if (error != nil) {
           [controller sendLog:[@"loadLeaderboards error : " stringByAppendingString:error.localizedDescription]];
           [controller sendEvent:kAirGameCenterLeaderboardEvent_leaderboardsLoadError level:error.localizedDescription];
           return;
       }
       
       if (leaderboards != nil) {
           [controller sendLog:[@"successfully loaded leaderboards : " stringByAppendingString:@""]];
           
           
           NSMutableDictionary *result = [[NSMutableDictionary alloc] init];
           
         
           __block NSInteger loadedCount = 0;
           __block BOOL stopLoading = NO;
           
           for (GKLeaderboard* leaderboard in leaderboards)
           {
               if (stopLoading) {
                   break;
               }
               [leaderboard loadScoresWithCompletionHandler:^(NSArray<GKScore *> * _Nullable scores, NSError * _Nullable error) {
                   
                   if (error != nil) {
                       stopLoading = YES;
                       [controller sendEvent:kAirGameCenterLeaderboardEvent_leaderboardsLoadError level:error.localizedDescription];
                   }
                   else {
                       loadedCount = loadedCount + 1;
                       if (loadedCount == leaderboards.count) {
                           // finished
                           NSArray *leaderboardsArray = leaderboardsToDictionaryArray(leaderboards);
                           [result setValue:leaderboardsArray forKey:@"leaderboards"];
                           [controller sendEvent:kAirGameCenterLeaderboardEvent_leaderboardsLoadComplete level:dictionaryToNSString(result)];
                       }
                   }
                   
               }];
           }
       }
       else {
           [controller sendEvent:kAirGameCenterLeaderboardEvent_leaderboardsLoadError level:@"Unable to load leaderboards"];
       }
       
   }];
    
    return nil;
}

DEFINE_ANE_FUNCTION(showLeaderboard) {
    
    AirGameCenter* controller = GetAirGameCenterContextNativeData(context);
    
    if (!controller)
        return AirGameCenter_FPANE_CreateError(@"context's AirGameCenter is null", 0);
    
    @try {
        NSString *leaderboardId = AirGameCenter_FPANE_FREObjectToNSString((argv[0]));
        
        GKGameCenterViewController *leaderboardViewController = [[GKGameCenterViewController alloc] init];
        leaderboardViewController.viewState = GKGameCenterViewControllerStateLeaderboards;
        if ([leaderboardId isEqualToString:@"null"] == false) {
            leaderboardViewController.leaderboardIdentifier = leaderboardId;
        }
        
        leaderboardViewController.gameCenterDelegate = controller;
        
#if TARGET_OS_IPHONE
        UIViewController* rootViewController = [[[UIApplication sharedApplication] keyWindow] rootViewController];
        [rootViewController presentViewController:leaderboardViewController animated:true completion:nil];
#elif TARGET_OS_OSX
        GKDialogController *sdc = [GKDialogController sharedDialogController];
        sdc.parentWindow = [NSApp keyWindow];
        [sdc presentViewController:leaderboardViewController];
#endif
        
    }
    @catch (NSException *exception) {
        [controller sendLog:[@"Exception occured while trying to showLeaderboard: " stringByAppendingString:exception.reason]];
        
    }
    
    return nil;
}

DEFINE_ANE_FUNCTION(showAchievements) {
    
    AirGameCenter* controller = GetAirGameCenterContextNativeData(context);
    
    if (!controller)
        return AirGameCenter_FPANE_CreateError(@"context's AirGameCenter is null", 0);
    
    @try {
        
        GKGameCenterViewController *achievementViewController = [[GKGameCenterViewController alloc] init];
        achievementViewController.viewState = GKGameCenterViewControllerStateAchievements;
        achievementViewController.gameCenterDelegate = controller;
#if TARGET_OS_IPHONE
        UIViewController* rootViewController = [[[UIApplication sharedApplication] keyWindow] rootViewController];
        [rootViewController presentViewController:achievementViewController animated:true completion:nil];
#elif TARGET_OS_OSX
        GKDialogController *sdc = [GKDialogController sharedDialogController];
        sdc.parentWindow = [NSApp keyWindow];
        [sdc presentViewController:achievementViewController];
        
        
        
#endif
        
    }
    @catch (NSException *exception) {
        [controller sendLog:[@"Exception occured while trying to showAchievements: " stringByAppendingString:exception.reason]];
        
    }
    
    return nil;
}

DEFINE_ANE_FUNCTION(loadAchievements) {
    
    AirGameCenter* controller = GetAirGameCenterContextNativeData(context);
    
    if (!controller)
        return AirGameCenter_FPANE_CreateError(@"context's AirGameCenter is null", 0);

    NSMutableDictionary *result = [[NSMutableDictionary alloc] init];
    NSMutableArray *achievementsArray = [[NSMutableArray alloc] init];
    
    [GKAchievement loadAchievementsWithCompletionHandler:^(NSArray<GKAchievement *> * _Nullable achievements, NSError * _Nullable error) {
       
        if (error != nil) {
            [controller sendLog:[@"getAchievements error : " stringByAppendingString:error.localizedDescription]];
            [controller sendEvent:kAirGameCenterAchievementEvent_achievementsLoadError level:error.localizedDescription];
            return;
        }
        
        for (GKAchievement* achievement in achievements)
        {
            NSDictionary *achievementDict = achievementToDictionary(achievement);
            [achievementsArray addObject:achievementDict];
        }
        
        [result setValue:achievementsArray forKey:@"achievements"];
        
        [controller sendEvent:kAirGameCenterAchievementEvent_achievementsLoadComplete level:dictionaryToNSString(result)];
        
    }];
    
    return nil;
}

DEFINE_ANE_FUNCTION(reportScore) {
    
    AirGameCenter* controller = GetAirGameCenterContextNativeData(context);
    
    if (!controller)
        return AirGameCenter_FPANE_CreateError(@"context's AirGameCenter is null", 0);
    
    @try {
        NSString *leaderboardId = AirGameCenter_FPANE_FREObjectToNSString((argv[0]));
        NSInteger score = AirGameCenter_FPANE_FREObjectToInt((argv[1]));
       
        GKScore *gkScore = [[GKScore alloc] initWithLeaderboardIdentifier:leaderboardId];
        [gkScore setValue:score];
        
        [GKScore reportScores:@[gkScore] withCompletionHandler:^(NSError * _Nullable error) {

            if (error != nil) {
                // dispatch error
                [controller sendEvent:kAirGameCenterEvent_scoreReportFailed level:error.localizedDescription];
                return;
            }
            
            // dispatch success
            [controller sendEvent:kAirGameCenterEvent_scoreReported];
            
        }];
        
    }
    @catch (NSException *exception) {
        [controller sendLog:[@"Exception occured while trying to showLeaderboard: " stringByAppendingString:exception.reason]];
        
    }
    
    return nil;
}

DEFINE_ANE_FUNCTION(reportAchievement) {
    
    AirGameCenter* controller = GetAirGameCenterContextNativeData(context);
    
    if (!controller)
        return AirGameCenter_FPANE_CreateError(@"context's AirGameCenter is null", 0);
    
    @try {
        NSString *identifier = AirGameCenter_FPANE_FREObjectToNSString((argv[0]));
        BOOL showCompletionBanner = AirGameCenter_FPANE_FREObjectToBool((argv[1]));
        double percentComplete = AirGameCenter_FPANE_FREObjectToDouble((argv[2]));
        
        GKAchievement *gkAchievement = [[GKAchievement alloc] initWithIdentifier:identifier];
        [gkAchievement setPercentComplete:percentComplete];
        [gkAchievement setShowsCompletionBanner:showCompletionBanner];
        
        [GKAchievement reportAchievements:@[gkAchievement] withCompletionHandler:^(NSError * _Nullable error) {
            if (error != nil) {
                // dispatch error
                [controller sendEvent:kAirGameCenterEvent_achievementReportFailed level:error.localizedDescription];
                return;
            }
            
            // dispatch success
            [controller sendEvent:kAirGameCenterEvent_achievementReported];
            
        }];
    }
    @catch (NSException *exception) {
        [controller sendLog:[@"Exception occured while trying to showLeaderboard: " stringByAppendingString:exception.reason]];
        
    }
    
    return nil;
}

DEFINE_ANE_FUNCTION(loadRecentPlayers) {
    
    AirGameCenter* controller = GetAirGameCenterContextNativeData(context);
    
    if (!controller)
        return AirGameCenter_FPANE_CreateError(@"context's AirGameCenter is null", 0);
   
    GKLocalPlayer *localPlayer = [GKLocalPlayer localPlayer];
    [localPlayer loadRecentPlayersWithCompletionHandler:^(NSArray<GKPlayer *> * _Nullable recentPlayers, NSError * _Nullable error) {
       
        if (error != nil) {
            [controller sendEvent:kAirGameCenterRecentPlayersEvent_playersLoadError level:error.localizedDescription];
            return;
        }
        NSMutableDictionary *result = [[NSMutableDictionary alloc] init];
        NSMutableArray *playersArray = [[NSMutableArray alloc] init];
        
        
        for (GKPlayer *player in recentPlayers) {
            NSDictionary *playerDict = playerToDictionary(player);
            [playersArray addObject:playerDict];
        }
        [result setValue:playersArray forKey:@"players"];
        
        [controller sendEvent:kAirGameCenterRecentPlayersEvent_playersLoadComplete level:dictionaryToNSString(result)];
        
    }];
    
    
    return nil;
}

DEFINE_ANE_FUNCTION(loadPlayerPhoto) {
    
    AirGameCenter* controller = GetAirGameCenterContextNativeData(context);
    
    if (!controller)
        return AirGameCenter_FPANE_CreateError(@"context's AirGameCenter is null", 0);
    
    @try {
        NSString *playerID = AirGameCenter_FPANE_FREObjectToNSString((argv[0]));
        [GKPlayer loadPlayersForIdentifiers:@[playerID] withCompletionHandler:^(NSArray<GKPlayer *> * _Nullable players, NSError * _Nullable error) {
            
            if (error != nil) {
                [controller sendEvent:kAirGameCenterPhotoEvent_photoLoadError level:error.localizedDescription];
                return;
            }
           
            if(players.count > 0) {
                GKPlayer *player = players[0];
#if TARGET_OS_IPHONE
                [player loadPhotoForSize:GKPhotoSizeNormal withCompletionHandler:
                 ^(UIImage *photo, NSError *error) {
                     if(error != nil) {
                         [controller sendEvent:kAirGameCenterPhotoEvent_photoLoadError level:createPhotoLoadErrorString(playerID, error.localizedDescription)];
                         return;
                     }
                     
                     if (photo != nil) {
                         [controller storePlayerPhoto:player.playerID playerPhoto:photo];
                         [controller sendEvent:kPlayerPhotoLoadComplete level:player.playerID];
                     }
                     else {
                         [controller sendEvent:kAirGameCenterPhotoEvent_photoLoadError level:createPhotoLoadErrorString(playerID, @"Player has no photo")];
                     }
                     
                     
                 }];
#elif TARGET_OS_OSX
                [player loadPhotoForSize:GKPhotoSizeNormal withCompletionHandler:^(NSImage * _Nullable photo, NSError * _Nullable error) {
                    if(error != nil) {
                        [controller sendEvent:kAirGameCenterPhotoEvent_photoLoadError level:createPhotoLoadErrorString(playerID, error.localizedDescription)];
                        return;
                    }
                    
                    if (photo != nil) {
                        [controller storePlayerPhoto:player.playerID playerPhoto:photo];
                        [controller sendEvent:kPlayerPhotoLoadComplete level:player.playerID];
                    }
                    else {
                        [controller sendEvent:kAirGameCenterPhotoEvent_photoLoadError level:createPhotoLoadErrorString(playerID, @"Player has no photo")];
                    }
                }];
#endif
            }
            else {
                [controller sendEvent:kAirGameCenterPhotoEvent_photoLoadError level:createPhotoLoadErrorString(playerID, error.localizedDescription)];
            }
            
            
        }];
        
    }
    @catch (NSException *exception) {
        [controller sendLog:[@"Exception occured while trying to loadPlayerPhoto: " stringByAppendingString:exception.reason]];
        
    }
    
    return nil;
}

DEFINE_ANE_FUNCTION(showDashboard) {
    
    AirGameCenter* controller = GetAirGameCenterContextNativeData(context);
    
    if (!controller)
        return AirGameCenter_FPANE_CreateError(@"context's AirGameCenter is null", 0);
    
    @try {
        
        GKGameCenterViewController *achievementViewController = [[GKGameCenterViewController alloc] init];
        achievementViewController.viewState = GKGameCenterViewControllerStateDashboard;
        achievementViewController.gameCenterDelegate = controller;
#if TARGET_OS_IPHONE
        UIViewController* rootViewController = [[[UIApplication sharedApplication] keyWindow] rootViewController];
        [rootViewController presentViewController:achievementViewController animated:true completion:nil];
#elif TARGET_OS_OSX
        GKDialogController *sdc = [GKDialogController sharedDialogController];
        sdc.parentWindow = [NSApp keyWindow];
        [sdc presentViewController:achievementViewController];
        
        
        
#endif
        
    }
    @catch (NSException *exception) {
        [controller sendLog:[@"Exception occured while trying to showDashboard: " stringByAppendingString:exception.reason]];
        
    }
    
    return nil;
}

DEFINE_ANE_FUNCTION(showAccessPoint) {
    if (@available(iOS 14.0, macOS 11.0, *)) {
        [GKAccessPoint shared].showHighlights = false;
        [GKAccessPoint shared].location = GKAccessPointLocationTopTrailing;
        [[GKAccessPoint shared] setActive:true];
    }
    
    return nil;
}

DEFINE_ANE_FUNCTION(hideAccessPoint) {
    if (@available(iOS 14.0, macOS 11.0, *)) {
        [[GKAccessPoint shared] setActive:false];
    }
    
    return nil;
}


#pragma mark - ANE setup

void AirGameCenterContextInitializer(void* extData, const uint8_t* ctxType, FREContext ctx,
                                      uint32_t* numFunctionsToTest, const FRENamedFunction** functionsToSet) {
    
    AirGameCenter* controller = [[AirGameCenter alloc] initWithContext:ctx];
    FRESetContextNativeData(ctx, (void*)CFBridgingRetain(controller));
    
    static FRENamedFunction functions[] = {
        MAP_FUNCTION(authenticateLocalPlayer, NULL),
        MAP_FUNCTION(isAuthenticated, NULL),
        MAP_FUNCTION(getLocalPlayer, NULL),
        MAP_FUNCTION(getStoredPlayerPhoto, NULL),
        MAP_FUNCTION(loadLeaderboards, NULL),
        MAP_FUNCTION(showLeaderboard, NULL),
        MAP_FUNCTION(reportScore, NULL),
        MAP_FUNCTION(showAchievements, NULL),
        MAP_FUNCTION(loadAchievements, NULL),
        MAP_FUNCTION(reportAchievement, NULL),
        MAP_FUNCTION(loadRecentPlayers, NULL),
        MAP_FUNCTION(loadPlayerPhoto, NULL),
        MAP_FUNCTION(showDashboard, NULL),
        MAP_FUNCTION(showAccessPoint, NULL),
        MAP_FUNCTION(hideAccessPoint, NULL)
    };
    
    *numFunctionsToTest = sizeof(functions) / sizeof(FRENamedFunction);
    *functionsToSet = functions;
    
}

void AirGameCenterContextFinalizer(FREContext ctx) {
    CFTypeRef controller;
    FREGetContextNativeData(ctx, (void **)&controller);
    CFBridgingRelease(controller);
}

void AirGameCenterInitializer(void** extDataToSet, FREContextInitializer* ctxInitializerToSet, FREContextFinalizer* ctxFinalizerToSet ) {
    *extDataToSet = NULL;
    *ctxInitializerToSet = &AirGameCenterContextInitializer;
    *ctxFinalizerToSet = &AirGameCenterContextFinalizer;
}

void AirGameCenterFinalizer(void *extData) {}

