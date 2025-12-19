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

package com.freshplanet.ane.AirGameCenter.events {
import flash.events.Event;

public class AirGameCenterEvent extends Event {

	public static const AUTHENTICATED:String = "AirGameCenterEvent_authenticated";
	public static const AUTHENTICATION_FAILED:String = "AirGameCenterEvent_authenticationFailed";

	public static const SCORE_REPORTED:String = "AirGameCenterEvent_scoreReported";
	public static const SCORE_REPORT_FAILED:String = "AirGameCenterEvent_scoreReportFailed";

	public static const ACHIEVEMENT_REPORTED:String = "AirGameCenterEvent_achievementReported";
	public static const ACHIEVEMENT_REPORT_FAILED:String = "AirGameCenterEvent_achievementReportFailed";

	public static const ACHIEVEMENTS_RESET:String = "AirGameCenterEvent_achievementsReset";
	public static const ACHIEVEMENTS_RESET_FAILED:String = "AirGameCenterEvent_achievementsResetFailed";

	private var _error:String;

	public function AirGameCenterEvent(type:String, error:String = null, bubbles:Boolean = false, cancelable:Boolean = false) {
		super(type, bubbles, cancelable);
		_error = error;
	}

	public function get error():String {
		return _error;
	}
}
}
