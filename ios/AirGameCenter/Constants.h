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

#ifndef Constants_h
#define Constants_h


#endif /* Constants_h */

static NSString *const kAirGameCenterEvent_authenticated = @"AirGameCenterEvent_authenticated";
static NSString *const kAirGameCenterEvent_authenticationFailed = @"AirGameCenterEvent_authenticationFailed";
static NSString *const kAirGameCenterEvent_scoreReported = @"AirGameCenterEvent_scoreReported";
static NSString *const kAirGameCenterEvent_scoreReportFailed = @"AirGameCenterEvent_scoreReportFailed";
static NSString *const kAirGameCenterEvent_achievementReported = @"AirGameCenterEvent_achievementReported";
static NSString *const kAirGameCenterEvent_achievementReportFailed = @"AirGameCenterEvent_achievementReportFailed";
static NSString *const kAirGameCenterEvent_achievementsReset = @"AirGameCenterEvent_achievementsReset";
static NSString *const kAirGameCenterEvent_achievementsResetFailed = @"AirGameCenterEvent_achievementsResetFailed";

static NSString *const kAirGameCenterPhotoEvent_photoLoadError = @"AirGameCenterPhotoEvent_photoLoadError";

static NSString *const kAirGameCenterLeaderboardEvent_leaderboardsLoadComplete = @"AirGameCenterLeaderboardEvent_leaderboardsLoadComplete";
static NSString *const kAirGameCenterLeaderboardEvent_leaderboardsLoadError = @"AirGameCenterLeaderboardEvent_leaderboardsLoadError";

static NSString *const kAirGameCenterAchievementEvent_achievementsLoadComplete = @"AirGameCenterAchievementEvent_achievementsLoadComplete";
static NSString *const kAirGameCenterAchievementEvent_achievementsLoadError = @"AirGameCenterAchievementEvent_achievementsLoadError";

static NSString *const kAirGameCenterRecentPlayersEvent_playersLoadComplete = @"AirGameCenterRecentPlayersEvent_playersLoadComplete";
static NSString *const kAirGameCenterRecentPlayersEvent_playersLoadError = @"AirGameCenterRecentPlayersEvent_playersLoadError";



// internal events
static NSString *const kPlayerPhotoLoadComplete = @"playerPhotoLoadComplete";
