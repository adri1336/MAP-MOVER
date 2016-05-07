// Revised version to work as include, credits to h02

#define MOVE_SPEED 100.0
#define ACCEL_RATE 0.03

enum ( <<= 1 ) {
	CAMERA_MODE_NONE,
	CAMERA_MODE_FLY = 1,
	CAMERA_MOVE_UP,
	CAMERA_MOVE_DOWN,
	CAMERA_MOVE_LEFT,
	CAMERA_MOVE_RIGHT
}

enum noclipenum {
	eF_objectid,
	eF_mode,
	eF_lr,
	eF_ud,
	eF_time,
	Float: eF_accel
}
static
	gFlyData[MAX_PLAYERS][noclipenum]
;

stock IsPlayerUsingFlyMode(playerid) {
	return (gFlyData[playerid][eF_mode] != CAMERA_MODE_NONE);
}

stock FlyMode(playerid) {
	if(TogglePlayerSpectating(playerid, true) && gFlyData[playerid][eF_mode] == CAMERA_MODE_NONE) {
		new
			Float: X,
			Float: Y,
			Float: Z
		;
		GetPlayerPos(playerid, X, Y, Z);

		gFlyData[playerid][eF_objectid] = CreatePlayerObject(playerid, 19300, X, Y, Z, 0.0, 0.0, 0.0);

		AttachCameraToPlayerObject(playerid, gFlyData[playerid][eF_objectid]);

		gFlyData[playerid][eF_mode] = CAMERA_MODE_FLY;
		gFlyData[playerid][eF_accel] = 0.0;

		GetPlayerKeys(playerid, playerid, gFlyData[playerid][eF_ud], gFlyData[playerid][eF_lr]);
		return true;
	}
	return false;
}

stock GetFlymodeObject(playerid) {
	
	return gFlyData[playerid][eF_objectid];
}

stock CancelFlyMode(playerid) {
	if(gFlyData[playerid][eF_mode] != CAMERA_MODE_NONE) {
		TogglePlayerSpectating(playerid, false);
		DestroyPlayerObject(playerid, gFlyData[playerid][eF_objectid]);

		gFlyData[playerid][eF_mode] = CAMERA_MODE_NONE;
		return true;
	}
	return false;
}

// static

static GetMoveDirectionFromKeys(ud, lr) {
	new
		direction
	;
	if(ud < 0)		direction |= CAMERA_MOVE_UP;
	else if(ud > 0)	direction |= CAMERA_MOVE_DOWN;
	if(lr < 0)		direction |= CAMERA_MOVE_LEFT;
	else if(lr > 0)	direction |= CAMERA_MOVE_RIGHT;

	return direction;
}

static GetNextCameraPosition(mode, Float: vX, Float: vY, Float: vZ, & Float:X, & Float:Y, & Float:Z) {
	vX *= 10000.0;
	vY *= 10000.0;
	vZ *= 10000.0;

	if(mode & CAMERA_MOVE_UP) {
		X += vX;
		Y += vY;
		Z += vZ;
	}
	else if(mode & CAMERA_MOVE_DOWN) {
		X -= vX;
		Y -= vY;
		Z -= vZ;
	}
	if(mode & CAMERA_MOVE_LEFT) {
		X -= vY;
		Y += vX;
	}
	else if(mode & CAMERA_MOVE_RIGHT) {
		X += vY;
		Y -= vX;
	}
}

static MoveCamera(playerid) {
	if(gFlyData[playerid][eF_accel] <= 5.0) {
		gFlyData[playerid][eF_accel] += ACCEL_RATE;
	}
	new
		Float: X,
		Float: Y,
		Float: Z,
		Float: vX,
		Float: vY,
		Float: vZ
	;
	GetPlayerCameraPos(playerid, X, Y, Z);
    GetPlayerCameraFrontVector(playerid, vX, vY, vZ);

	GetNextCameraPosition(gFlyData[playerid][eF_mode], vX, vY, vZ, X, Y, Z);

	MovePlayerObject(playerid, gFlyData[playerid][eF_objectid], X, Y, Z, MOVE_SPEED * gFlyData[playerid][eF_accel]);

	gFlyData[playerid][eF_time] = GetTickCount() + 100;
}

// public

public OnPlayerUpdate(playerid) {
	if(gFlyData[playerid][eF_mode] != CAMERA_MODE_NONE) {

		new
			keys,
			ud,
			lr
		;
		GetPlayerKeys(playerid, keys, ud, lr);

		if(ud == 0 && lr == 0) {
			StopPlayerObject(playerid, gFlyData[playerid][eF_objectid]);

			gFlyData[playerid][eF_mode] = CAMERA_MODE_FLY;
			gFlyData[playerid][eF_accel] = 0.0;
			gFlyData[playerid][eF_time] = 0;
		}
		else if(gFlyData[playerid][eF_ud] != ud || gFlyData[playerid][eF_lr] != lr) {
			gFlyData[playerid][eF_mode] = GetMoveDirectionFromKeys(ud, lr);

			MoveCamera(playerid);
		}
		else if(gFlyData[playerid][eF_time] < GetTickCount()) {
			MoveCamera(playerid);			
		}
		gFlyData[playerid][eF_ud] = ud;
		gFlyData[playerid][eF_lr] = lr;
	}
	#if defined FM_OnPlayerUpdate
		return FM_OnPlayerUpdate(playerid);
	#else
		return true;
	#endif
}

public OnFilterScriptExit() {
	for(new i; i < MAX_PLAYERS; ++i) {
		CancelFlyMode(i);
	}
	#if defined FM_OnFilterScriptExit
		FM_OnFilterScriptExit();
	#endif
}

public OnPlayerDisconnect(playerid, reason) {
	CancelFlyMode(playerid);

	#if defined FM_OnPlayerDisconnect
		return FM_OnPlayerDisconnect(playerid, reason);
	#else
		return true;
	#endif
}

#if defined _ALS_OnPlayerUpdate
	#undef OnPlayerUpdate
#else
	#define _ALS_OnPlayerUpdate
#endif
#if defined _ALS_OnFilterScriptExit
	#undef OnFilterScriptExit
#else
	#define _ALS_OnFilterScriptExit
#endif
#if defined _ALS_OnPlayerDisconnect
	#undef OnPlayerDisconnect
#else
	#define _ALS_OnPlayerDisconnect
#endif

#define OnPlayerUpdate FM_OnPlayerUpdate
#define OnFilterScriptExit FM_OnFilterScriptExit
#define OnPlayerDisconnect FM_OnPlayerDisconnect

#if defined FM_OnPlayerUpdate
	forward FM_OnPlayerUpdate(playerid);
#endif
#if defined FM_OnFilterScriptExit
	forward FM_OnFilterScriptExit();
#endif
#if defined FM_OnPlayerDisconnect
	forward FM_OnPlayerDisconnect(playerid, reason);
#endif