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

package com.freshplanet.ane.AirGameCenter {

import com.freshplanet.ane.AirGameCenter.enums.AirGameCenterLeaderboardPlayerScope;
import com.freshplanet.ane.AirGameCenter.enums.AirGameCenterLeaderboardTimeScope;
import com.freshplanet.ane.AirGameCenter.events.AirGameCenterAchievementEvent;
import com.freshplanet.ane.AirGameCenter.events.AirGameCenterEvent;
import com.freshplanet.ane.AirGameCenter.events.AirGameCenterLeaderboardEvent;
import com.freshplanet.ane.AirGameCenter.events.AirGameCenterPhotoEvent;
import com.freshplanet.ane.AirGameCenter.events.AirGameCenterRecentPlayersEvent;

import flash.display.BitmapData;

import flash.events.EventDispatcher;
	import flash.events.StatusEvent;
	import flash.external.ExtensionContext;
	import flash.system.Capabilities;

	public class AirGameCenter extends EventDispatcher {
		// --------------------------------------------------------------------------------------//
		//																						 //
		// 									   PUBLIC API										 //
		// 																						 //
		// --------------------------------------------------------------------------------------//


		/** supported on iOS devices. */
		public static function get isSupported() : Boolean {
			return isIOS;
		}

		/**
		 * If <code>true</code>, logs will be displayed at the Actionscript level.
		 */
		public function get logEnabled() : Boolean {
			return _logEnabled;
		}

		public function set logEnabled( value : Boolean ) : void {
			_logEnabled = value;
		}

		/**
		 * AirGameCenter instance
		 * @return AirGameCenter instance
		 */
		public static function get instance() : AirGameCenter {
			return _instance ? _instance : new AirGameCenter();
		}

		/**
		 * Authenticate the local player
		 */
		public function authenticateLocalPlayer() : void
		{
			if(isSupported)
				_context.call( "authenticateLocalPlayer" );
		}

		/**
		 * Is the local player authenticated
		 */
		public function get isAuthenticated() : Boolean
		{
			if(isSupported)
				return _context.call( "isAuthenticated" );

			return false;
		}

		/**
		 * Get local player
		 */
		public function get localPlayer() : AirGameCenterPlayer
		{
			if(isSupported) {
				var localPlayerJSON:String = _context.call("getLocalPlayer") as String;
				if(localPlayerJSON) {
					return parsePlayerJSON(localPlayerJSON);
				}
			}

			return null;
		}

		/**
		 * Load leaderboards
		 */
		public function loadLeaderboards() : void
		{
			if(isSupported)
				_context.call("loadLeaderboards");
		}

		/**
		 * Show leaderboard
		 */
		public function showLeaderboard(leaderboardId:String = null) : void
		{
			if(isSupported)
				_context.call("showLeaderboard", leaderboardId ? leaderboardId : "null");
		}

		/**
		 * Load achievements
		 */
		public function loadAchievements() : void
		{
			if(isSupported)
				_context.call("loadAchievements");
		}

		/**
		 * Show achievements
		 */
		public function showAchievements() : void
		{
			if(isSupported)
				_context.call("showAchievements");
		}

		/**
		 * Report score
		 */
		public function reportScore(leaderboardId:String, score:int) : void
		{
			if(isSupported)
				_context.call("reportScore", leaderboardId, score);
		}

		/**
		 * Report achievement
		 */
		public function reportAchievement(achievementId:String, showCompletionBanner:Boolean = true, percentComplete:Number = 100) : void
		{
			if(isSupported)
				_context.call("reportAchievement", achievementId, showCompletionBanner, percentComplete);
		}

		/**
		 * A recent player is someone that you have played a game with or is a legacy game center friend.
		 */
		public function loadRecentPlayers() : void
		{
			if(isSupported)
				_context.call("loadRecentPlayers");
		}

		/**
		 * Load player photo
		 */
		public function loadPlayerPhoto(playerId:String) : void
		{
			if(isSupported)
				_context.call("loadPlayerPhoto", playerId);
		}

		// --------------------------------------------------------------------------------------//
		//																						 //
		// 									 	PRIVATE API										 //
		// 																						 //
		// --------------------------------------------------------------------------------------//

		private static const EXTENSION_ID : String = "com.freshplanet.ane.AirGameCenter";
		private static var _instance : AirGameCenter;
		private var _context : ExtensionContext = null;
		private var _logEnabled : Boolean = true;

		private static const INTERNAL_PLAYER_PHOTO_LOAD_COMPLETE:String = "playerPhotoLoadComplete";

		/**
		 * "private" singleton constructor
		 */
		public function AirGameCenter() {
			if (!_instance) {
				_context = ExtensionContext.createExtensionContext(EXTENSION_ID, null);
				if (!_context) {
					log("ERROR - Extension context is null. Please check if extension.xml is setup correctly.");
					return;
				}
				_context.addEventListener(StatusEvent.STATUS, onStatus);

				_instance = this;
			}
			else {
				throw Error("This is a singleton, use instance, do not call the constructor directly.");
			}
		}

		private function getPlayerPhoto(playerId:String) : BitmapData
		{
			// not checking for isSupported because this function gets executed only when usage has already began
			return _context.call("getStoredPlayerPhoto", playerId) as BitmapData;
		}

		private function onStatus( event : StatusEvent ) : void {
			if (event.code == AirGameCenterEvent.AUTHENTICATED ) {
				this.dispatchEvent(new AirGameCenterEvent(event.code));
			}
			else if (event.code == AirGameCenterEvent.AUTHENTICATION_FAILED ) {
				this.dispatchEvent(new AirGameCenterEvent(event.code, event.level));
			}
			else if (event.code == INTERNAL_PLAYER_PHOTO_LOAD_COMPLETE ) {

				var playerId:String = event.level;
				var photoBD:BitmapData = getPlayerPhoto(playerId);
				this.dispatchEvent(new AirGameCenterPhotoEvent(AirGameCenterPhotoEvent.LOAD_COMPLETE, playerId, photoBD));
			}
			else if (event.code == AirGameCenterPhotoEvent.LOAD_ERROR ) {

				var result:Object = JSON.parse(event.level);
				this.dispatchEvent(new AirGameCenterPhotoEvent(AirGameCenterPhotoEvent.LOAD_ERROR, result.playerId, null, result.error));
			}
			else if (event.code == AirGameCenterLeaderboardEvent.LOAD_COMPLETE ) {
				var leaderboards:Vector.<AirGameCenterLeaderboard> = parseLeaderboardsJSON(event.level);
				this.dispatchEvent(new AirGameCenterLeaderboardEvent(AirGameCenterLeaderboardEvent.LOAD_COMPLETE, leaderboards));
			}
			else if (event.code == AirGameCenterLeaderboardEvent.LOAD_ERROR ) {

				this.dispatchEvent(new AirGameCenterLeaderboardEvent(AirGameCenterLeaderboardEvent.LOAD_ERROR, null, event.level));
			}
			else if (event.code == AirGameCenterEvent.SCORE_REPORT_FAILED) {
				this.dispatchEvent(new AirGameCenterEvent(AirGameCenterEvent.SCORE_REPORT_FAILED, event.level));
			}
			else if (event.code == AirGameCenterEvent.SCORE_REPORTED) {
				this.dispatchEvent(new AirGameCenterEvent(AirGameCenterEvent.SCORE_REPORTED));
			}
			else if (event.code == AirGameCenterAchievementEvent.LOAD_COMPLETE) {
				var achievements:Vector.<AirGameCenterAchievement> = parseAchievementsJSON(event.level);
				this.dispatchEvent(new AirGameCenterAchievementEvent(AirGameCenterAchievementEvent.LOAD_COMPLETE, achievements));
			}
			else if (event.code == AirGameCenterAchievementEvent.LOAD_ERROR) {
				this.dispatchEvent(new AirGameCenterAchievementEvent(AirGameCenterAchievementEvent.LOAD_ERROR, null, event.level));
			}
			else if (event.code == AirGameCenterEvent.ACHIEVEMENT_REPORTED) {
				this.dispatchEvent(new AirGameCenterEvent(AirGameCenterEvent.ACHIEVEMENT_REPORTED));
			}
			else if (event.code == AirGameCenterEvent.ACHIEVEMENT_REPORT_FAILED) {
				this.dispatchEvent(new AirGameCenterEvent(AirGameCenterEvent.ACHIEVEMENT_REPORT_FAILED, event.level));
			}
			else if (event.code == AirGameCenterRecentPlayersEvent.LOAD_COMPLETE) {
				var players:Vector.<AirGameCenterPlayer> = parseRecentPlayersJSON(event.level);
				this.dispatchEvent(new AirGameCenterRecentPlayersEvent(AirGameCenterRecentPlayersEvent.LOAD_COMPLETE, players));
			}
			else if (event.code == AirGameCenterRecentPlayersEvent.LOAD_ERROR) {
				this.dispatchEvent(new AirGameCenterRecentPlayersEvent(AirGameCenterRecentPlayersEvent.LOAD_ERROR, null, event.level));
			}
			else if (event.code == "log") {
				log(event.level);
			}

		}

		private function log(message:String):void {
			if (_logEnabled) trace("[AirGameCenter] " + message);
		}

		private static function get isIOS():Boolean {
			return Capabilities.manufacturer.indexOf("iOS") > -1 && Capabilities.os.indexOf("x86_64") < 0 && Capabilities.os.indexOf("i386") < 0;
		}

		private function parseRecentPlayersJSON(jsonString:String):Vector.<AirGameCenterPlayer> {
			var object:Object = JSON.parse(jsonString);
			var players:Array = object.players;
			var result:Vector.<AirGameCenterPlayer> = new <AirGameCenterPlayer>[];
			for (var i:int = 0; i < players.length; i++) {
				var playerObject:Object = players[i];
				result.push(new AirGameCenterPlayer(playerObject.id, playerObject.alias, playerObject.displayName));
			}
			return result;

		}

		private function parsePlayerJSON(jsonString:String):AirGameCenterPlayer {
			var object:Object = JSON.parse(jsonString);
			return new AirGameCenterPlayer(object.id, object.alias, object.displayName);
		}

		private function parseLeaderboardsJSON(jsonString:String):Vector.<AirGameCenterLeaderboard> {
			var object:Object = JSON.parse(jsonString);
			var leaderboards:Array = object.leaderboards;
			var result:Vector.<AirGameCenterLeaderboard> = new <AirGameCenterLeaderboard>[];

			for (var i:int = 0; i < leaderboards.length; i++) {
				var leaderboardObject:Object = leaderboards[i];

				var scoresArray:Array = leaderboardObject.scores;
				var scores:Vector.<AirGameCenterScore> = new <AirGameCenterScore>[];

				for (var j:int = 0; j < scoresArray.length; j++) {
					var scoreObject:Object = scoresArray[j];
					var score:AirGameCenterScore = new AirGameCenterScore(
							scoreObject.leaderboardId,
							scoreObject.value,
							scoreObject.formattedValue,
							new Date(scoreObject.date),
							new AirGameCenterPlayer(
									scoreObject.player.id,
									scoreObject.player.alias,
									scoreObject.player.displayName
							),
							scoreObject.rank
					);
					scores.push(score);
				}

				var leaderboard:AirGameCenterLeaderboard = new AirGameCenterLeaderboard(
						leaderboardObject.identifier,
						leaderboardObject.title,
						AirGameCenterLeaderboardTimeScope.fromValue(leaderboardObject.timeScope),
						AirGameCenterLeaderboardPlayerScope.fromValue(leaderboardObject.playerScope),
						leaderboardObject.rangeLocation,
						leaderboardObject.rangeLength,
						leaderboardObject.maxRange,
						scores,
						leaderboardObject.localPlayerScore ? new AirGameCenterScore(

								leaderboardObject.localPlayerScore.leaderboardId,
								leaderboardObject.localPlayerScore.value,
								leaderboardObject.localPlayerScore.formattedValue,
						new Date(leaderboardObject.localPlayerScore.date),
						new AirGameCenterPlayer(
								leaderboardObject.localPlayerScore.player.id,
								leaderboardObject.localPlayerScore.player.alias,
								leaderboardObject.localPlayerScore.player.displayName
						),
								leaderboardObject.localPlayerScore.rank
						) : null
				);

				result.push(leaderboard);

			}
			return result;
		}

		private function parseAchievementsJSON(jsonString:String):Vector.<AirGameCenterAchievement>  {
			var object:Object = JSON.parse(jsonString);
			var achievements:Array = object.achievements;

			var result:Vector.<AirGameCenterAchievement> = new <AirGameCenterAchievement>[];
			for (var i:int = 0; i < achievements.length; i++) {
				var achievementObject:Object = achievements[i];

				var achievement:AirGameCenterAchievement = new AirGameCenterAchievement(
						achievementObject.identifier,
						achievementObject.percentComplete,
						achievementObject.completed != 0,
						new Date(achievementObject.lastReportedDate));
				result.push(achievement);
			}

			return result;
		}

	}
}