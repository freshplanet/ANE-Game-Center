package com.sticksports.nativeExtensions.gameCenter
{
	import com.sticksports.nativeExtensions.gameCenter.signals.GCSignal0;
	import com.sticksports.nativeExtensions.gameCenter.signals.GCSignal1;
	
	import flash.display.BitmapData;
	import flash.events.StatusEvent;
	import flash.external.ExtensionContext;

	public class GameCenter
	{		
		public static var localPlayerAuthenticated : GCSignal0 = new GCSignal0();
		public static var localPlayerNotAuthenticated : GCSignal0 = new GCSignal0();
		public static var localPlayerFriendsLoadComplete : GCSignal1 = new GCSignal1( Array );
		public static var localPlayerFriendsLoadFailed : GCSignal0 = new GCSignal0();
		public static var leaderboardLoadComplete : GCSignal1 = new GCSignal1( GCLeaderboard );
		public static var leaderboardLoadFailed : GCSignal0 = new GCSignal0();
		public static var localPlayerScoreLoadComplete : GCSignal1 = new GCSignal1( GCLeaderboard );
		public static var localPlayerScoreLoadFailed : GCSignal0 = new GCSignal0();
		public static var localPlayerScoreReported : GCSignal0 = new GCSignal0();
		public static var localPlayerScoreReportFailed : GCSignal0 = new GCSignal0();
		public static var localPlayerAchievementReported : GCSignal0 = new GCSignal0();
		public static var localPlayerAchievementReportFailed : GCSignal0 = new GCSignal0();
		public static var achievementsLoadComplete : GCSignal1 = new GCSignal1( Vector );
		public static var achievementsLoadFailed : GCSignal0 = new GCSignal0();
		public static var gameCenterViewRemoved : GCSignal0 = new GCSignal0();
		
		private static var _loadPlayerPhotoCompleteSignals:Object = {};
		private static var _loadPlayerPhotoFailedSignals:Object = {};
		private static var _loadingPlayerPhotos:Object = {};
		
		public static var isAuthenticating : Boolean;
		
		private static var _isSupported : Boolean;
		private static var _isSupportedTested : Boolean;
		private static var _isAuthenticated : Boolean;
		private static var _isAuthenticatedTested : Boolean;
		
		private static var _localPlayer : GCLocalPlayer;
		private static var _localPlayerTested : Boolean;
		
		private static var extensionContext : ExtensionContext = null;
		private static var initialised : Boolean = false;
		
		/**
		 * Initialise the extension
		 */
		public static function init() : void
		{
			if ( !initialised )
			{
				initialised = true;
				
				extensionContext = ExtensionContext.createExtensionContext( "com.sticksports.nativeExtensions.GameCenter", null );
				
				extensionContext.addEventListener( StatusEvent.STATUS, handleStatusEvent );
			}
		}
		
		private static function handleStatusEvent( event : StatusEvent ) : void
		{
			//trace( "internal event", event.level );
			switch( event.level )
			{
				case InternalMessages.localPlayerAuthenticated :
					isAuthenticating = false;
					_isAuthenticated = true;
					_isAuthenticatedTested = true;
					_localPlayerTested = false;
					localPlayerAuthenticated.dispatch();
					break;
				case InternalMessages.localPlayerNotAuthenticated :
					isAuthenticating = false;
					_isAuthenticated = false;
					_isAuthenticatedTested = true;
					_localPlayerTested = false;
					localPlayerNotAuthenticated.dispatch();
					break;
				case InternalMessages.notAuthenticated :
					throw new Error( InternalMessages.notAuthenticatedError );
					break;
				case InternalMessages.scoreReported :
					localPlayerScoreReported.dispatch();
					break;
				case InternalMessages.scoreNotReported :
					localPlayerScoreReportFailed.dispatch();
					break;
				case InternalMessages.achievementReported :
					localPlayerAchievementReported.dispatch();
					break;
				case InternalMessages.achievementNotReported :
					localPlayerAchievementReportFailed.dispatch();
					break;
				case InternalMessages.loadFriendsComplete :
					var friends : Array = getReturnedPlayers( event.code );
					if( friends )
					{
						localPlayerFriendsLoadComplete.dispatch( friends );
					}
					else
					{
						localPlayerFriendsLoadFailed.dispatch();
					}
					break;
				case InternalMessages.loadFriendsFailed :
					localPlayerFriendsLoadFailed.dispatch();
					break;
				case InternalMessages.loadLocalPlayerScoreComplete :
					var score : GCLeaderboard = getReturnedLocalPlayerScore( event.code );
					if( score )
					{
						localPlayerScoreLoadComplete.dispatch( score );
					}
					else
					{
						localPlayerScoreLoadFailed.dispatch();
					}
					break;
				case InternalMessages.loadLocalPlayerScoreFailed :
					localPlayerScoreLoadFailed.dispatch();
					break;
				case InternalMessages.gameCenterViewRemoved :
					gameCenterViewRemoved.dispatch();
					break;
				case InternalMessages.loadLeaderboardComplete :
					var leaderboard : GCLeaderboard = getStoredLeaderboard( event.code );
					if( leaderboard )
					{
						leaderboardLoadComplete.dispatch( leaderboard );
					}
					else
					{
						leaderboardLoadFailed.dispatch();
					}
					break;
				case InternalMessages.loadLeaderboardFailed :
					leaderboardLoadFailed.dispatch();
					break;
				case InternalMessages.loadAchievementsComplete :
					var achievements : Vector.<GCAchievement> = getStoredAchievements( event.code );
					if( achievements )
					{
						achievementsLoadComplete.dispatch( achievements );
					}
					else
					{
						achievementsLoadFailed.dispatch();
					}
					break;
				case InternalMessages.loadAchievementsFailed :
					achievementsLoadFailed.dispatch();
					break;
				case InternalMessages.loadPlayerPhotoComplete:
					onLoadPlayerPhotoComplete(event.code);
					break;
				case InternalMessages.loadPlayerPhotoFailed:
					onLoadPlayerPhotoFailed(event.code);
					break;
			}
		}
		
		/**
		 * Is the extension supported
		 */
		public static function get isSupported() : Boolean
		{
			if( !_isSupportedTested )
			{
				_isSupportedTested = true;
				init();
				_isSupported = extensionContext.call( NativeMethods.isSupported ) as Boolean;
			}
			return _isSupported;
		}
		
		private static function assertIsSupported() : void
		{
			if( !isSupported )
			{
				throw new Error( InternalMessages.notSupportedError );
			}
		}

		/**
		 * Authenticate the local player
		 */
		public static function authenticateLocalPlayer() : void
		{
			assertIsSupported();
			isAuthenticating = true;
			extensionContext.call( NativeMethods.authenticateLocalPlayer );
		}
		
		/**
		 * Is the local player authenticated
		 */
		public static function get isAuthenticated() : Boolean
		{
			return _isAuthenticated;
		}

		private static function assertIsAuthenticatedTested() : void
		{
			assertIsSupported();
			if( !_isAuthenticatedTested )
			{
				throw new Error( InternalMessages.authenticationNotAttempted );
			}
		}

		private static function assertIsAuthenticated() : void
		{
			assertIsAuthenticatedTested();
			if( !_isAuthenticated )
			{
				throw new Error( InternalMessages.notAuthenticatedError );
			}
		}
		
		/**
		 * Authenticate the local player
		 */
		public static function get localPlayer() : GCLocalPlayer
		{
			assertIsAuthenticatedTested();
			if( _isAuthenticated && !_localPlayerTested )
			{
				_localPlayer = extensionContext.call( NativeMethods.getLocalPlayer ) as GCLocalPlayer;
			}
			return _localPlayer;
		}
		
		/**
		 * Report a score to Game Center
		 */
		public static function reportScore( category : String, value : int ) : void
		{
			assertIsAuthenticated();
			if( localPlayer )
			{
				extensionContext.call( NativeMethods.reportScore, category, value );
			}
		}
		
		/**
		 * Report a achievement to Game Center
		 */
		public static function reportAchievement( category : String, value : Number, banner : Boolean = false ) : void
		{
			assertIsAuthenticated();
			if( localPlayer )
			{
				extensionContext.call( NativeMethods.reportAchievement, category, value, banner );
			}
		}
		
		public static function showStandardLeaderboard( category : String = "", timeScope : int = -1 ) : void
		{
			assertIsAuthenticated();
			if( localPlayer )
			{
				if( category )
				{
					if( timeScope != -1 )
					{
						extensionContext.call( NativeMethods.showStandardLeaderboardWithCategoryAndTimescope, category, timeScope );
					}
					else
					{
						extensionContext.call( NativeMethods.showStandardLeaderboardWithCategory, category );
					}
				}
				else if( timeScope != -1 )
				{
					extensionContext.call( NativeMethods.showStandardLeaderboardWithTimescope, timeScope );
				}
				else
				{
					extensionContext.call( NativeMethods.showStandardLeaderboard );
				}
			}
		}
		
		public static function showStandardAchievements() : void
		{
			assertIsAuthenticated();
			if( localPlayer )
			{
				extensionContext.call( NativeMethods.showStandardAchievements );
			}
		}
		
		public static function getLocalPlayerFriends() : void
		{
			assertIsAuthenticated();
			if( localPlayer )
			{
				extensionContext.call( NativeMethods.getLocalPlayerFriends );
			}
		}
		
		public static function getLocalPlayerScore( category : String, playerScope : int = 0, timeScope : int = 2 ) : void
		{
			assertIsAuthenticated();
			if( localPlayer )
			{
				extensionContext.call( NativeMethods.getLocalPlayerScore, category, playerScope, timeScope );
			}
		}
		
		public static function getPlayerPhoto(id:String, bmd:BitmapData, successCB:Function, errorCB:Function):void 
		{
			assertIsAuthenticated();
			if( localPlayer )
			{
				if(_loadingPlayerPhotos[id]) {
					return;
				}
				
				addLoadPlayerPhotoCompleteSignal(id, successCB);
				addLoadPlayerPhotoFailedSignal(id, errorCB);
				extensionContext.call( NativeMethods.getPlayerPhoto, id, bmd ) as String;
				_loadingPlayerPhotos[id] = new bmd;
			}
		}
		
		public static function addLoadPlayerPhotoCompleteSignal( id:String, cb:Function ):void 
		{
			var sig:GCSignal1 = _loadPlayerPhotoCompleteSignals[id];
			if(!sig) {
				sig = new GCSignal1( BitmapData );
				_loadPlayerPhotoCompleteSignals[id] = sig;
			}
			sig.addOnce(cb);
		}
		
		public static function addLoadPlayerPhotoFailedSignal( id:String, cb:Function ):void 
		{
			var sig:GCSignal0 = _loadPlayerPhotoFailedSignals[id];
			if(!sig) {
				sig = new GCSignal0();
				_loadPlayerPhotoFailedSignals[id] = sig;
			}
			sig.addOnce(cb);
		}

		private static function onLoadPlayerPhotoComplete( id:String ):void 
		{
			if(_loadingPlayerPhotos[id] && _loadPlayerPhotoCompleteSignals[id]) {
				var loadingPhoto:BitmapData = _loadingPlayerPhotos[id];
				try {
					if(getStoredPlayerPhoto(id, loadingPhoto)) {
						_loadPlayerPhotoCompleteSignals[id].dispatch(loadingPhoto)
					} else {
						_loadPlayerPhotoFailedSignals[id].dispatch();
					}
				} catch (e:Error) {
					_loadPlayerPhotoFailedSignals[id].dispatch();
				}
			}
			cleanupLoadingPhoto(id);
		}
		
		private static function onLoadPlayerPhotoFailed( id:String ):void 
		{
			if(_loadPlayerPhotoFailedSignals[id]) {
				_loadPlayerPhotoFailedSignals[id].dispatch();
			}
			cleanupLoadingPhoto(id);
		}
		
		private static function cleanupLoadingPhoto( id:String ):void 
		{
			if(_loadPlayerPhotoCompleteSignals[id]) {
				_loadPlayerPhotoCompleteSignals[id].removeAll();
				delete _loadPlayerPhotoCompleteSignals[id];
			}
			if(_loadPlayerPhotoFailedSignals[id]) {
				_loadPlayerPhotoFailedSignals[id].removeAll();
				delete _loadPlayerPhotoFailedSignals[id];
			}
			delete _loadingPlayerPhotos[id];
		}
		
		public static function getLeaderboard( category : String, playerScope : int = 0, timeScope : int = 2, rangeStart : int = 1, rangeLength : int = 25 ) : void
		{
			assertIsAuthenticated();
			if( localPlayer )
			{
				extensionContext.call( NativeMethods.getLeaderboard, category, playerScope, timeScope, rangeStart, rangeLength );
			}
		}
		
		public static function getAchievements() : void
		{
			assertIsAuthenticated();
			if( localPlayer )
			{
				extensionContext.call( NativeMethods.getAchievements );
			}
		}
		
		private static function getStoredPlayerPhoto(key:String, inBMD:BitmapData) : void 
		{
			extensionContext.call( NativeMethods.getStoredPlayerPhoto, key, inBMD );
		}
		
		private static function getStoredLeaderboard( key : String ) : GCLeaderboard
		{
			return extensionContext.call( NativeMethods.getStoredLeaderboard, key ) as GCLeaderboard;
		}
		
		private static function getStoredAchievements( key : String ) : Vector.<GCAchievement>
		{
			return extensionContext.call( NativeMethods.getStoredAchievements, key ) as Vector.<GCAchievement>;
		}
		
		private static function getReturnedLocalPlayerScore( key : String ) : GCLeaderboard
		{
			return extensionContext.call( NativeMethods.getStoredLocalPlayerScore, key ) as GCLeaderboard;
		}
		
		private static function getReturnedPlayers( key : String ) : Array
		{
			return extensionContext.call( NativeMethods.getStoredPlayers, key ) as Array;
		}

		/**
		 * Clean up the extension - only if you no longer need it or want to free memory. All listeners will be removed.
		 */
		public static function dispose() : void
		{
			if ( extensionContext )
			{
				extensionContext.dispose();
				extensionContext = null;
			}
			localPlayerAuthenticated.removeAll();
			localPlayerNotAuthenticated.removeAll();
			localPlayerFriendsLoadComplete.removeAll();
			localPlayerFriendsLoadFailed.removeAll();
			leaderboardLoadComplete.removeAll();
			leaderboardLoadFailed.removeAll();
			achievementsLoadComplete.removeAll();
			achievementsLoadFailed.removeAll();
			localPlayerScoreLoadComplete.removeAll();
			localPlayerScoreLoadFailed.removeAll();
			localPlayerScoreReported.removeAll();
			localPlayerScoreReportFailed.removeAll();
			localPlayerAchievementReported.removeAll();
			localPlayerAchievementReportFailed.removeAll();
			gameCenterViewRemoved.removeAll();
			
			for (var k:String in _loadPlayerPhotoCompleteSignals) {
				_loadPlayerPhotoCompleteSignals[k].removeAll();
				delete _loadPlayerPhotoCompleteSignals[k];
			}
			for (k in _loadPlayerPhotoFailedSignals) {
				_loadPlayerPhotoFailedSignals[k].removeAll();
				delete _loadPlayerPhotoFailedSignals[k];
			}
			
			initialised = false;
		}
	}
}