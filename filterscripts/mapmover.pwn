/*
	MAP MOVER 2.1 FILTERSCRIPT
	
	Credits
	----------
	adri1 for filterscript, getobjectinfo include and mapmover plugin
	Nero_3D for screentoworld include and MoveObjectWithCursor functions
	Stylock for some functions
	Y_Less for sscanf2 include
	Zeex for zcmd include
	h02 for flymode include revision
	SA-MP Team for flymode
*/

#include <a_samp>
#include <screentoworld>
#include <zcmd>
#include <sscanf2>

#include "vkeys"
#include "flymode"
#include "getobjectinfo"


#define MAX_MAPMOVER_OBJECTS	1000
forward OnObjectImported(count, objectid);
forward OnMapLoaded(count);
forward OnObjectTextured(objectid, materialindex, modelid, txdname[], texturename[], materialcolor);
forward OnObjectTextTextured(objectid, text[], materialindex, materialsize, fontface[], fontsize, bold, fontcolor, backcolor, textalignment);

native GetScreenSize(&Width, &Height);
native GetMousePos(&X, &Y);

enum {
	mNone,
	mStarted,
	mLoadingMap,
	mEditing,
	mMoving,
	mMovingByCamera,
	mMovingByCursor,
	
	mapLoading,
	mapLoaded
}

enum {
	DIALOG_MAPMOVER = 601,
	DIALOG_MAPMOVERLOAD
}

enum {
	MOVEMODE_NONE,
	MOVEMODE_EDITOBJECT,
	MOVEMODE_CAMERA,
	MOVEMODE_CURSOR_AROUND
}

new
	
	gMoveObject = INVALID_OBJECT_ID,
	gTimerid,
	Cursor_oX,
	Cursor_oY,
	Cursor_X,
	Cursor_Y,
	ScreenWidth,
	ScreenHeight,
	Float: OffsetX,
	Float: OffsetY,
	
	total_objects_imported,
	mapmoverMode = mNone,
	mapmoverMapStatus = mNone,
	mapmoverMoveMode = MOVEMODE_EDITOBJECT,
	mapmoverPlayerID = -1,
	SetCenterObject,
	CenterObject,
	
	Float:oldX, Float:oldY, Float:oldZ, Float:oldRotX, Float:oldRotY, Float:oldRotZ,  //CANCELLING MAP MOVING
	Float:CamOffSetX, Float:CamOffSetY, Float:CamOffSetZ
;


//OBJECTS INFO
enum OBJECT_INFO
{

	bool:EDITOR,
	objectID,
	bool:TEXTURED,
	TEXTURE_COUNT,
	bool:TEXTTEXTURED,
	TEXTTEXTURE_COUNT,
	
	Float:OffSetX,
	Float:OffSetY,
	Float:OffSetZ
	
};
new MAPMOVER_OBJECT_INFO[MAX_MAPMOVER_OBJECTS][OBJECT_INFO];


enum OBJECTMATERIAL_INFO
{

	map_materialindex,
	map_modelid,
	map_txdname[24],
	map_texturename[24],
	map_materialcolor
	
};
new MAPMOVER_OBJECT_MATERIAL_INFO[MAX_MAPMOVER_OBJECTS][16][OBJECTMATERIAL_INFO];


enum OBJECTMATERIALTEXT_INFO
{

	map_text[256],
	map_mindex,
	map_materialsize,
	map_fontface[24],
	map_fontsize,
	map_bold,
	map_fontcolor,
	map_backcolor,
	map_textalignment
	
};
new MAPMOVER_OBJECT_MTEXT_INFO[MAX_MAPMOVER_OBJECTS][16][OBJECTMATERIALTEXT_INFO];
//



public OnFilterScriptInit() 
{
	print("MAP MOVER 2.1 BY ADRI1 LOADED.");
	return 1;
}

public OnFilterScriptExit() 
{
	Exit();
	return 1;
}

CMD:mapmover(playerid, params[])
{
	switch(mapmoverMode)
	{
		case mNone, mStarted:
		{
			new ip[16];
	        GetPlayerIp(playerid, ip, 16);
	        if(strcmp(ip, "127.0.0.1", false)) return SendClientMessage(playerid, -1, "{e2b960}MAP MOVER only can be used from localhost (127.0.0.1)");
			
			mapmoverPlayerID = playerid;
			GetScreenSize(ScreenWidth, ScreenHeight);
			ShowPlayerDialog(playerid, DIALOG_MAPMOVER, DIALOG_STYLE_LIST, "{CCCCCC}MAP MOVER 2.1", "{CCCCCC}1. Load editmap.pwn filterscript\n{999999}2. Go to the map\n{999999}3. Set center object\n{999999}4. Move map\n{999999}5. Save\n{CCCCCC}Exit\n{CCCCCC}On/Off /flymode", ">>", "X");
			mapmoverMode = mStarted;
		}
		case mLoadingMap: SendClientMessage(playerid, -1, "{CCCCCC}Loading map... please wait.");
		case mEditing:
		{
			if(IsValidObject(CenterObject)) ShowPlayerDialog(playerid, DIALOG_MAPMOVER, DIALOG_STYLE_LIST, "{CCCCCC}MAP MOVER 2.1", "{CCCCCC}1. Reload editmap.pwn filterscript\n{CCCCCC}2. Go to the map\n{CCCCCC}3. Move center object\n{CCCCCC}4. Move map\n{CCCCCC}5. Save\n{CCCCCC}Exit\n{CCCCCC}On/Off /flymode", ">>", "X");
			else ShowPlayerDialog(playerid, DIALOG_MAPMOVER, DIALOG_STYLE_LIST, "{CCCCCC}MAP MOVER 2.1", "{CCCCCC}1. Reload editmap.pwn filterscript\n{CCCCCC}2. Go to the map\n{CCCCCC}3. Set center object\n{999999}4. Move map\n{CCCCCC}5. Save\n{CCCCCC}Exit\n{CCCCCC}On/Off /flymode", ">>", "X");
		}
		case mMoving, mMovingByCamera, mMovingByCursor: SendClientMessage(playerid, -1, "{CCCCCC}Finish move the map first.");
	}
	return 1;
}

CMD:flymode(playerid, params[])
{
	if(IsPlayerUsingFlyMode(playerid)) {
		CancelFlyMode(playerid);
	} else {
		FlyMode(playerid);
	}
	return 1;
}

CMD:go(playerid, params[])
{
	if(mapmoverMode == mNone || mapmoverMode == mStarted) return SendClientMessage(playerid, -1, "{996600}ERROR.");
	if(sscanf(params, "d", params[0])) return SendClientMessage(playerid, -1, "{996600}ERROR.");
	if(params[0] > total_objects_imported-1) return SendClientMessage(playerid, -1, "{996600}ERROR.");
	if(params[0] < 0) return SendClientMessage(playerid, -1, "{996600}ERROR.");
	
	new Float:p[3];
	if(mapmoverMode == mMoving) return GetObjectPos(CenterObject, p[0], p[1], p[2]);
	else if(mapmoverMode == mMovingByCamera) return false;
	else GetObjectPos(MAPMOVER_OBJECT_INFO[params[0]][objectID], p[0], p[1], p[2]);
	if(IsPlayerUsingFlyMode(playerid)) SetPlayerObjectPos(playerid, GetFlymodeObject(playerid), p[0], p[1], p[2]);
	else SetPlayerPos(playerid, p[0], p[1], p[2]);
	return 1;
}

CMD:movemode(playerid, params[])
{
	if(mapmoverMode != mEditing) return SendClientMessage(playerid, -1, "{996600}ERROR.");
	if(sscanf(params, "d", params[0])) return SendClientMessage(playerid, -1, "{CCCCCC}1. Normal  2. Camera  3. Cursor around.");
	
	switch(params[0])
	{
		case 1:
		{
			mapmoverMoveMode = MOVEMODE_EDITOBJECT;
			SendClientMessage(playerid, -1, "{CCCCCC}Move mode: NORMAL.");
		}
		case 2:
		{
			mapmoverMoveMode = MOVEMODE_CAMERA;
			SendClientMessage(playerid, -1, "{CCCCCC}Move mode: CAMERA.");
		}
		case 3:
		{
			mapmoverMoveMode = MOVEMODE_CURSOR_AROUND;
			SendClientMessage(playerid, -1, "{CCCCCC}Move mode: CURSOR AROUND.");
		}
		default: SendClientMessage(playerid, -1, "{CCCCCC}1. Normal  2. Camera  3. Cursor around.");
	}
	return 1;
}

public OnDialogResponse(playerid, dialogid, response, listitem, inputtext[])
{
    switch(dialogid)
	{
		case DIALOG_MAPMOVER:
		{
			if(response)
			{
				switch(listitem)
				{
					case 0: //RE/LOAD FS MAP
					{
						if(mapmoverMode == mStarted)
						{
							SendClientMessage(playerid, -1, "{CCCCCC}Loading map... please wait.");
							mapmoverMapStatus = mapLoading;
							mapmoverMode = mLoadingMap;
							ShowPlayerDialog(playerid, DIALOG_MAPMOVERLOAD, DIALOG_STYLE_MSGBOX, "{CCCCCC}MAP MOVER 2.1", "{CCCCCC}\n\tLoading map...\n", "X", "");
							SendRconCommand("reloadfs editmap");
							
							if(mapmoverMapStatus == mapLoaded && total_objects_imported > 0)
							{
								mapmoverMode = mEditing;
								ShowPlayerDialog(playerid, DIALOG_MAPMOVER, DIALOG_STYLE_LIST, "{CCCCCC}MAP MOVER 2.1", "{CCCCCC}1. Reload editmap.pwn filterscript\n{CCCCCC}2. Go to the map\n{CCCCCC}3. Set center object\n{999999}4. Move map\n{CCCCCC}5. Save\n{CCCCCC}Exit\n{CCCCCC}On/Off /flymode", ">>", "X");
							}
							else
							{
								mapmoverMapStatus = mNone;
								mapmoverMode = mStarted;
								ShowPlayerDialog(playerid, DIALOG_MAPMOVER, DIALOG_STYLE_LIST, "{CCCCCC}MAP MOVER 2.1", "{CCCCCC}1. Load editmap.pwn filterscript\n{999999}2. Go to the map\n{999999}3. Set center object\n{999999}4. Move map\n{999999}5. Save\n{CCCCCC}Exit\n{CCCCCC}On/Off /flymode", ">>", "X");
								SendClientMessage(playerid, -1, "{CCCCCC}Map can't be loaded. Check editmap.pwn filterscript, it must be compiled.");
							}
						}
						else if(mapmoverMode == mEditing)
						{
							for(new i = 0; i != MAX_MAPMOVER_OBJECTS; i++)
							{
								if(MAPMOVER_OBJECT_INFO[i][EDITOR]) DestroyObject(MAPMOVER_OBJECT_INFO[i][objectID]);
								for(new d; d < sizeof(MAPMOVER_OBJECT_INFO[]); d++)
								{
									MAPMOVER_OBJECT_INFO[i][OBJECT_INFO: d] = 0;
								}	
								
								for(new d; d < sizeof(MAPMOVER_OBJECT_MATERIAL_INFO[]); d++)
								{
									for(new s; s < sizeof(MAPMOVER_OBJECT_MATERIAL_INFO[][]); s++) MAPMOVER_OBJECT_MATERIAL_INFO[i][s][OBJECTMATERIAL_INFO: d] = 0;
								}	
								
								for(new d; d < sizeof(MAPMOVER_OBJECT_MTEXT_INFO[]); d++)
								{
									for(new s; s < sizeof(MAPMOVER_OBJECT_MTEXT_INFO[][]); s++) MAPMOVER_OBJECT_MTEXT_INFO[i][s][OBJECTMATERIALTEXT_INFO: d] = 0;
								}	
								
							}
							total_objects_imported = 0;
							if(IsValidObject(SetCenterObject)) DestroyObject(SetCenterObject);
							if(IsValidObject(CenterObject))  DestroyObject(CenterObject);
							
							SendClientMessage(playerid, -1, "{CCCCCC}Loading map... please wait.");
							mapmoverMapStatus = mapLoading;
							mapmoverMode = mLoadingMap;
							ShowPlayerDialog(playerid, DIALOG_MAPMOVERLOAD, DIALOG_STYLE_MSGBOX, "{CCCCCC}MAP MOVER 2.1", "{CCCCCC}\n\tLoading map...\n", "X", "");
							SendRconCommand("reloadfs editmap");
							
							if(mapmoverMapStatus == mapLoaded && total_objects_imported > 0)
							{
								mapmoverMode = mEditing;
								ShowPlayerDialog(playerid, DIALOG_MAPMOVER, DIALOG_STYLE_LIST, "{CCCCCC}MAP MOVER 2.1", "{CCCCCC}1. Reload editmap.pwn filterscript\n{CCCCCC}2. Go to the map\n{CCCCCC}3. Set center object\n{999999}4. Move map\n{CCCCCC}5. Save\n{CCCCCC}Exit\n{CCCCCC}On/Off /flymode", ">>", "X");
							}
							else
							{
								mapmoverMapStatus = mNone;
								mapmoverMode = mStarted;
								ShowPlayerDialog(playerid, DIALOG_MAPMOVER, DIALOG_STYLE_LIST, "{CCCCCC}MAP MOVER 2.1", "{CCCCCC}1. Load editmap.pwn filterscript\n{999999}2. Go to the map\n{999999}3. Set center object\n{999999}4. Move map\n{999999}5. Save\n{CCCCCC}Exit\n{CCCCCC}On/Off /flymode", ">>", "X");
								SendClientMessage(playerid, -1, "{CCCCCC}Map can't be loaded. Check editmap.pwn filterscript, it must be compiled.");
							}
						}
					}
					case 1: //GO TO MAP
					{
						if(mapmoverMode == mStarted) return ShowPlayerDialog(playerid, DIALOG_MAPMOVER, DIALOG_STYLE_LIST, "{CCCCCC}MAP MOVER 2.1", "{CCCCCC}1. Load editmap.pwn filterscript\n{999999}2. Go to the map\n{999999}3. Set center object\n{999999}4. Move map\n{999999}5. Save\n{CCCCCC}Exit\n{CCCCCC}On/Off /flymode", ">>", "X");
						
						new info[128];
						format(info, sizeof info, "{CCCCCC}You can also use /go [0-%d] to teleport between imported objects.", total_objects_imported-1);
						SendClientMessage(playerid, -1, info);
						SendClientMessage(playerid, -1, "{CCCCCC}Press 'RIGHT SHIFT' to open main dialog, or type /mapmover again.");
						new Float:p[3];
						GetObjectPos(MAPMOVER_OBJECT_INFO[total_objects_imported-1][objectID], p[0], p[1], p[2]);
						if(IsPlayerUsingFlyMode(playerid)) SetPlayerObjectPos(playerid, GetFlymodeObject(playerid), p[0], p[1], p[2]);
						else SetPlayerPos(playerid, p[0], p[1], p[2]);
					}
					case 2: //RE/SET OBJECT CENTER
					{
						if(mapmoverMode == mStarted) return ShowPlayerDialog(playerid, DIALOG_MAPMOVER, DIALOG_STYLE_LIST, "{CCCCCC}MAP MOVER 2.1", "{CCCCCC}1. Load editmap.pwn filterscript\n{999999}2. Go to the map\n{999999}3. Set center object\n{999999}4. Move map\n{999999}5. Save\n{CCCCCC}Exit\n{CCCCCC}On/Off /flymode", ">>", "X");

						new Float:pos[3];
						GetPlayerPos(playerid, pos[0], pos[1], pos[2]);
						SetCenterObject = CreateObject(1220, pos[0], pos[1], pos[2], 0.0, 0.0, 0.0);
						SetObjectMaterial(SetCenterObject, 0, 18646, "matcolours", "blue");
						EditObject(playerid, SetCenterObject);
						
					}
					case 3: //MOVE MAP
					{
						if(mapmoverMode == mStarted) return ShowPlayerDialog(playerid, DIALOG_MAPMOVER, DIALOG_STYLE_LIST, "{CCCCCC}MAP MOVER 2.1", "{CCCCCC}1. Load editmap.pwn filterscript\n{999999}2. Go to the map\n{999999}3. Set center object\n{999999}4. Move map\n{999999}5. Save\n{CCCCCC}Exit\n{CCCCCC}On/Off /flymode", ">>", "X");
						if(mapmoverMode == mEditing)
						{
							if(!IsValidObject(CenterObject))
							{
								ShowPlayerDialog(playerid, DIALOG_MAPMOVER, DIALOG_STYLE_LIST, "{CCCCCC}MAP MOVER 2.1", "{CCCCCC}1. Reload editmap.pwn filterscript\n{CCCCCC}2. Go to the map\n{CCCCCC}3. Set center object\n{999999}4. Move map\n{CCCCCC}5. Save\n{CCCCCC}Exit\n{CCCCCC}On/Off /flymode", ">>", "X");
								SendClientMessage(playerid, -1, "{CCCCCC}Please, set center object first.");
								return 1;
							}	
							SendClientMessage(playerid, -1, "{CCCCCC}Use /movemode [1-5] to change move mode.  1. Normal  2. Camera  3. Cursor around.");
							switch(mapmoverMoveMode)
							{
								case MOVEMODE_EDITOBJECT:
								{
									new Float:CenterX, Float:CenterY, Float:CenterZ;
									GetObjectPos(CenterObject, CenterX, CenterY, CenterZ);
									
									GetObjectPos(CenterObject, oldX, oldY, oldZ);
									GetObjectRot(CenterObject, oldRotX, oldRotY, oldRotZ);
									
									for(new i = 0; i != MAX_MAPMOVER_OBJECTS; i++)
									{
										if(MAPMOVER_OBJECT_INFO[i][EDITOR])
										{
											new Float:aOffSetX, Float:aOffSetY, Float:aOffSetZ, Float:pos[6];
											GetObjectPos(MAPMOVER_OBJECT_INFO[i][objectID], pos[0], pos[1], pos[2]);
											GetObjectRot(MAPMOVER_OBJECT_INFO[i][objectID], pos[3], pos[4], pos[5]);
											aOffSetX = floatsub(pos[0], CenterX);
											aOffSetY = floatsub(pos[1], CenterY);
											aOffSetZ = floatsub(pos[2], CenterZ);
											MAPMOVER_OBJECT_INFO[i][OffSetX] = aOffSetX;
											MAPMOVER_OBJECT_INFO[i][OffSetY] = aOffSetY;
											MAPMOVER_OBJECT_INFO[i][OffSetZ] = aOffSetZ;
											AttachObjectToObject(MAPMOVER_OBJECT_INFO[i][objectID], CenterObject, aOffSetX, aOffSetY, aOffSetZ, pos[3], pos[4], pos[5], true);
										}
									}
									mapmoverMode = mMoving;
									EditObject(playerid, CenterObject);
									
	            
								}
								case MOVEMODE_CAMERA:
								{
									if(!IsPlayerUsingFlyMode(playerid))
									{
										ShowPlayerDialog(playerid, DIALOG_MAPMOVER, DIALOG_STYLE_LIST, "{CCCCCC}MAP MOVER 2.1", "{CCCCCC}1. Reload editmap.pwn filterscript\n{CCCCCC}2. Go to the map\n{CCCCCC}3. Set center object\n{CCCCCC}4. Move map\n{CCCCCC}5. Save\n{CCCCCC}Exit\n{CCCCCC}On/Off /flymode", ">>", "X");
										SendClientMessage(playerid, -1, "{CCCCCC}CAMERA MOVE MODE NEED FLYMODE ACTIVATED.");
										return 1;
									}
									
									SendClientMessage(playerid, -1, "{CCCCCC}Move the camera to move the map. Press {FFFF00}~k~~PED_DUCK~ {CCCCCC}for stop.");
									new Float:CenterX, Float:CenterY, Float:CenterZ;
									GetObjectPos(CenterObject, CenterX, CenterY, CenterZ);
									for(new i = 0; i != MAX_MAPMOVER_OBJECTS; i++)
									{
										if(MAPMOVER_OBJECT_INFO[i][EDITOR])
										{
											new Float:aOffSetX, Float:aOffSetY, Float:aOffSetZ, Float:pos[6];
											GetObjectPos(MAPMOVER_OBJECT_INFO[i][objectID], pos[0], pos[1], pos[2]);
											GetObjectRot(MAPMOVER_OBJECT_INFO[i][objectID], pos[3], pos[4], pos[5]);
											aOffSetX = floatsub(pos[0], CenterX);
											aOffSetY = floatsub(pos[1], CenterY);
											aOffSetZ = floatsub(pos[2], CenterZ);
											MAPMOVER_OBJECT_INFO[i][OffSetX] = aOffSetX;
											MAPMOVER_OBJECT_INFO[i][OffSetY] = aOffSetY;
											MAPMOVER_OBJECT_INFO[i][OffSetZ] = aOffSetZ;
											AttachObjectToObject(MAPMOVER_OBJECT_INFO[i][objectID], CenterObject, aOffSetX, aOffSetY, aOffSetZ, pos[3], pos[4], pos[5], true);
										}
									}
									new Float:fVX, Float:fVY, Float:fVZ, Float:object_x, Float:object_y, Float:object_z;
									const Float:fScale = 50.0;
									GetPlayerCameraFrontVector(playerid, fVX, fVY, fVZ);
									object_x = floatmul(fVX, fScale);
									object_y = floatmul(fVY, fScale);
									object_z = floatmul(fVZ, fScale);
									AttachObjectToObject(CenterObject, GetFlymodeObject(playerid), object_x, object_y, object_z, 0.0, 0.0, 0.0, true);
									CamOffSetX = object_x;
									CamOffSetY = object_y;
									CamOffSetZ = object_z;
									
									mapmoverMode = mMovingByCamera;
									
								}
								case MOVEMODE_CURSOR_AROUND:
								{
									SendClientMessage(playerid, -1, "{CCCCCC}Move map with left click pressed. Press 'SPACE' to move around. Press 'ESC' to finish.");
									new Float:aCenterX, Float:aCenterY, Float:aCenterZ;
									GetObjectPos(CenterObject, aCenterX, aCenterY, aCenterZ);
									
									for(new i = 0; i != MAX_MAPMOVER_OBJECTS; i++)
									{
										if(MAPMOVER_OBJECT_INFO[i][EDITOR])
										{
											new Float:aOffSetX, Float:aOffSetY, Float:aOffSetZ, Float:pos[6];
											GetObjectPos(MAPMOVER_OBJECT_INFO[i][objectID], pos[0], pos[1], pos[2]);
											GetObjectRot(MAPMOVER_OBJECT_INFO[i][objectID], pos[3], pos[4], pos[5]);
											aOffSetX = floatsub(pos[0], aCenterX);
											aOffSetY = floatsub(pos[1], aCenterY);
											aOffSetZ = floatsub(pos[2], aCenterZ);
											MAPMOVER_OBJECT_INFO[i][OffSetX] = aOffSetX;
											MAPMOVER_OBJECT_INFO[i][OffSetY] = aOffSetY;
											MAPMOVER_OBJECT_INFO[i][OffSetZ] = aOffSetZ;
											AttachObjectToObject(MAPMOVER_OBJECT_INFO[i][objectID], CenterObject, aOffSetX, aOffSetY, aOffSetZ, pos[3], pos[4], pos[5], true);
										}
									}
									
									GetScreenSize(ScreenWidth, ScreenHeight);
									SelectTextDraw(playerid, -1);
									mapmoverMode = mMovingByCursor;
								}
							}
						}
						
					}
					case 4:
					{
						if(mapmoverMode != mEditing) return ShowPlayerDialog(playerid, DIALOG_MAPMOVER, DIALOG_STYLE_LIST, "{CCCCCC}MAP MOVER 2.1", "{CCCCCC}1. Load editmap.pwn filterscript\n{999999}2. Go to the map\n{999999}3. Set center object\n{999999}4. Move map\n{999999}5. Save\n{CCCCCC}Exit\n{CCCCCC}On/Off /flymode", ">>", "X");
						SaveMap();
						SendClientMessage(playerid, -1, "{CCCCCC}MAP Exported exported in /scriptfiles/map_moved.txt");
					}
					case 5:
					{
						Exit();
						SendClientMessage(playerid, -1, "{999999}EXIT");
					}
					case 6: //FLYMODE
					{
						if(IsPlayerUsingFlyMode(playerid)) {
							CancelFlyMode(playerid);
						} else {
							FlyMode(playerid);
						}
						
						cmd_mapmover(playerid, "");
					}
				}
			}
		}
		
		case DIALOG_MAPMOVERLOAD: ShowPlayerDialog(playerid, DIALOG_MAPMOVERLOAD, DIALOG_STYLE_MSGBOX, "{CCCCCC}MAP MOVER 2.1", "{CCCCCC}\n\tLoading map...\n", "X", "");
	

	}
    return 0;
}

public OnPlayerClickTextDraw(playerid, Text:clickedid)
{
    if(clickedid == Text:INVALID_TEXT_DRAW)
    {
        if(mapmoverMode == mMovingByCursor && mapmoverMoveMode == MOVEMODE_CURSOR_AROUND)
        {
			gMoveObject = INVALID_OBJECT_ID;
			KillTimer(gTimerid);
			
			for(new i = 0; i != MAX_MAPMOVER_OBJECTS; i++)
			{
				if(MAPMOVER_OBJECT_INFO[i][EDITOR])
				{
					new Float:PX, Float:PY, Float:PZ;
					new Float:RX, Float:RY, Float:RZ;
					new Float:rot[3]; GetObjectRot(MAPMOVER_OBJECT_INFO[i][objectID], rot[0], rot[1], rot[2]);
					AttachObjectToObjectEx(CenterObject, MAPMOVER_OBJECT_INFO[i][OffSetX], MAPMOVER_OBJECT_INFO[i][OffSetY], MAPMOVER_OBJECT_INFO[i][OffSetZ], rot[0], rot[1], rot[2], PX, PY, PZ, RX, RY, RZ);

					MAPMOVER_OBJECT_INFO[i][OffSetX] = 0.0;
					MAPMOVER_OBJECT_INFO[i][OffSetY] = 0.0;
					MAPMOVER_OBJECT_INFO[i][OffSetZ] = 0.0;
					
					new modelid = GetObjectModel(MAPMOVER_OBJECT_INFO[i][objectID]);
					DestroyObject(MAPMOVER_OBJECT_INFO[i][objectID]);
					MAPMOVER_OBJECT_INFO[i][objectID] = CreateObject(modelid, PX, PY, PZ, RX, RY, RZ);
					if(MAPMOVER_OBJECT_INFO[i][TEXTURED]) TextureImportedObject(i, MAPMOVER_OBJECT_INFO[i][objectID]);
					if(MAPMOVER_OBJECT_INFO[i][TEXTTEXTURED]) TextTextureImportedObject(i, MAPMOVER_OBJECT_INFO[i][objectID]);
				}
			}
			
			SetObjectRot(CenterObject, 0.0, 0.0, 0.0);
			mapmoverMode = mEditing;
			mapmoverMoveMode = MOVEMODE_CURSOR_AROUND;
			SendClientMessage(playerid, -1, "{CCCCCC}Map moved!");
			
			return 1;
        }
    }
    return 0;
}

public OnPlayerKeyStateChange(playerid, newkeys, oldkeys)
{
	if((newkeys & KEY_CROUCH))
	{
		if(mapmoverMode == mMovingByCamera)
	    {
	        new Float:rPX, Float:rPY, Float:rPZ, Float:rRX, Float:rRY, Float:rRZ;
		    AttachObjectToObjectEx(GetFlymodeObject(playerid), CamOffSetX, CamOffSetY, CamOffSetZ, 0.0, 0.0, 0.0, rPX, rPY, rPZ, rRX, rRY, rRZ, playerid);
			new ResolveObject = CreateObject(1220, rPX, rPY, rPZ, rRX, rRY, rRZ);
			printf("%f, %f, %f", rPX, rPY, rPZ);
			for(new i = 0; i != MAX_MAPMOVER_OBJECTS; i++)
			{
				if(MAPMOVER_OBJECT_INFO[i][EDITOR])
				{
					new Float:PX, Float:PY, Float:PZ;
					new Float:RX, Float:RY, Float:RZ;
					new Float:rot[3]; GetObjectRot(MAPMOVER_OBJECT_INFO[i][objectID], rot[0], rot[1], rot[2]);
					AttachObjectToObjectEx(ResolveObject, MAPMOVER_OBJECT_INFO[i][OffSetX], MAPMOVER_OBJECT_INFO[i][OffSetY], MAPMOVER_OBJECT_INFO[i][OffSetZ], rot[0], rot[1], rot[2], PX, PY, PZ, RX, RY, RZ);

					MAPMOVER_OBJECT_INFO[i][OffSetX] = 0.0;
					MAPMOVER_OBJECT_INFO[i][OffSetY] = 0.0;
					MAPMOVER_OBJECT_INFO[i][OffSetZ] = 0.0;
					
					new modelid = GetObjectModel(MAPMOVER_OBJECT_INFO[i][objectID]);
					DestroyObject(MAPMOVER_OBJECT_INFO[i][objectID]);
					MAPMOVER_OBJECT_INFO[i][objectID] = CreateObject(modelid, PX, PY, PZ, RX, RY, RZ);
					if(MAPMOVER_OBJECT_INFO[i][TEXTURED]) TextureImportedObject(i, MAPMOVER_OBJECT_INFO[i][objectID]);
					if(MAPMOVER_OBJECT_INFO[i][TEXTTEXTURED]) TextTextureImportedObject(i, MAPMOVER_OBJECT_INFO[i][objectID]);
				}
			}
			
            DestroyObject(ResolveObject);
            DestroyObject(CenterObject);
            CenterObject = CreateObject(1220, rPX, rPY, rPZ, 0.0, 0.0, 0.0);
			SetObjectMaterial(CenterObject, 0, 18646, "matcolours", "red");
            mapmoverMode = mEditing;
			SendClientMessage(playerid, -1, "{CCCCCC}Map moved!");
	        return 1;
	    }
	}
	return 1;
}

public OnPlayerEditObject(playerid, playerobject, objectid, response, Float:fX, Float:fY, Float:fZ, Float:fRotX, Float:fRotY, Float:fRotZ)
{

	if(!playerobject) 
	{
	    if(!IsValidObject(objectid)) return 1;
	    SetObjectPos(objectid, fX, fY, fZ);		          
        SetObjectRot(objectid, fRotX, fRotY, fRotZ);
	}
 
 
	if(response == EDIT_RESPONSE_FINAL)
	{
		if(objectid == SetCenterObject)
		{
			if(IsValidObject(CenterObject)) DestroyObject(CenterObject);
			new Float:pos[3];
			GetObjectPos(SetCenterObject, pos[0], pos[1], pos[2]);
			CenterObject = CreateObject(1220, pos[0], pos[1], pos[2], 0.0, 0.0, 0.0);
			SetObjectMaterial(CenterObject, 0, 18646, "matcolours", "red");
			DestroyObject(SetCenterObject);
			
			ShowPlayerDialog(playerid, DIALOG_MAPMOVER, DIALOG_STYLE_LIST, "{CCCCCC}MAP MOVER 2.1", "{CCCCCC}1. Reload editmap.pwn filterscript\n{CCCCCC}2. Go to the map\n{CCCCCC}3. Move center object\n{CCCCCC}4. Move map\n{CCCCCC}5. Save\n{CCCCCC}Exit\n{CCCCCC}On/Off /flymode", ">>", "X");
			SendClientMessage(playerid, -1, "{CCCCCC}Center object set.");
			return 1;
		}
		
		if(objectid == CenterObject && mapmoverMode == mMoving)
		{
			
			for(new i = 0; i != MAX_MAPMOVER_OBJECTS; i++)
			{
				if(MAPMOVER_OBJECT_INFO[i][EDITOR])
				{
					new Float:PX, Float:PY, Float:PZ;
					new Float:RX, Float:RY, Float:RZ;
					new Float:rot[3]; GetObjectRot(MAPMOVER_OBJECT_INFO[i][objectID], rot[0], rot[1], rot[2]);
					AttachObjectToObjectEx(CenterObject, MAPMOVER_OBJECT_INFO[i][OffSetX], MAPMOVER_OBJECT_INFO[i][OffSetY], MAPMOVER_OBJECT_INFO[i][OffSetZ], rot[0], rot[1], rot[2], PX, PY, PZ, RX, RY, RZ);

					MAPMOVER_OBJECT_INFO[i][OffSetX] = 0.0;
					MAPMOVER_OBJECT_INFO[i][OffSetY] = 0.0;
					MAPMOVER_OBJECT_INFO[i][OffSetZ] = 0.0;
					
					new modelid = GetObjectModel(MAPMOVER_OBJECT_INFO[i][objectID]);
					DestroyObject(MAPMOVER_OBJECT_INFO[i][objectID]);
					MAPMOVER_OBJECT_INFO[i][objectID] = CreateObject(modelid, PX, PY, PZ, RX, RY, RZ);
					if(MAPMOVER_OBJECT_INFO[i][TEXTURED]) TextureImportedObject(i, MAPMOVER_OBJECT_INFO[i][objectID]);
					if(MAPMOVER_OBJECT_INFO[i][TEXTTEXTURED]) TextTextureImportedObject(i, MAPMOVER_OBJECT_INFO[i][objectID]);
				}
			}
			
			SetObjectRot(CenterObject, 0.0, 0.0, 0.0);
			mapmoverMode = mEditing;
			SendClientMessage(playerid, -1, "{CCCCCC}Map moved!");
			return 1;
		}
	}
 
	if(response == EDIT_RESPONSE_CANCEL)
	{
		if(objectid == SetCenterObject)
		{
			SendClientMessage(playerid, -1, "{CCCCCC}Cancelled.");
			DestroyObject(SetCenterObject);
			if(IsValidObject(CenterObject)) ShowPlayerDialog(playerid, DIALOG_MAPMOVER, DIALOG_STYLE_LIST, "{CCCCCC}MAP MOVER 2.1", "{CCCCCC}1. Reload editmap.pwn filterscript\n{CCCCCC}2. Go to the map\n{CCCCCC}3. Move center object\n{CCCCCC}4. Move map\n{CCCCCC}5. Save\n{CCCCCC}Exit\n{CCCCCC}On/Off /flymode", ">>", "X");
			else ShowPlayerDialog(playerid, DIALOG_MAPMOVER, DIALOG_STYLE_LIST, "{CCCCCC}MAP MOVER 2.1", "{CCCCCC}1. Reload editmap.pwn filterscript\n{CCCCCC}2. Go to the map\n{CCCCCC}3. Set center object\n{999999}4. Move map\n{CCCCCC}5. Save\n{CCCCCC}Exit\n{CCCCCC}On/Off /flymode", ">>", "X");
			return 1;
		}
		
		if(objectid == CenterObject)
		{
			SetObjectPos(CenterObject, oldX, oldY, oldZ);
			SetObjectRot(CenterObject, oldRotX, oldRotY, oldRotZ);
			
			
			for(new i = 0; i != MAX_MAPMOVER_OBJECTS; i++)
			{
				if(MAPMOVER_OBJECT_INFO[i][EDITOR])
				{
					new Float:PX, Float:PY, Float:PZ;
					new Float:RX, Float:RY, Float:RZ;
					new Float:rot[3]; GetObjectRot(MAPMOVER_OBJECT_INFO[i][objectID], rot[0], rot[1], rot[2]);
					AttachObjectToObjectEx(CenterObject, MAPMOVER_OBJECT_INFO[i][OffSetX], MAPMOVER_OBJECT_INFO[i][OffSetY], MAPMOVER_OBJECT_INFO[i][OffSetZ], rot[0], rot[1], rot[2], PX, PY, PZ, RX, RY, RZ);

					MAPMOVER_OBJECT_INFO[i][OffSetX] = 0.0;
					MAPMOVER_OBJECT_INFO[i][OffSetY] = 0.0;
					MAPMOVER_OBJECT_INFO[i][OffSetZ] = 0.0;
					
					new modelid = GetObjectModel(MAPMOVER_OBJECT_INFO[i][objectID]);
					DestroyObject(MAPMOVER_OBJECT_INFO[i][objectID]);
					MAPMOVER_OBJECT_INFO[i][objectID] = CreateObject(modelid, PX, PY, PZ, RX, RY, RZ);
					if(MAPMOVER_OBJECT_INFO[i][TEXTURED]) TextureImportedObject(i, MAPMOVER_OBJECT_INFO[i][objectID]);
					if(MAPMOVER_OBJECT_INFO[i][TEXTTEXTURED]) TextTextureImportedObject(i, MAPMOVER_OBJECT_INFO[i][objectID]);
				}
			}
			
			SetObjectRot(CenterObject, 0.0, 0.0, 0.0);
			mapmoverMode = mEditing;
			SendClientMessage(playerid, -1, "{CCCCCC}Map moving cancelled.");
			return 1;
		}
	}
	return 1;
}

public OnObjectImported(count, objectid)
{
	MAPMOVER_OBJECT_INFO[count][EDITOR] = true;
    MAPMOVER_OBJECT_INFO[count][objectID] = objectid; 
	//printf("Object #%d imported.", count);
	
	total_objects_imported ++;
	return 1;
}

public OnObjectTextured(objectid, materialindex, modelid, txdname[], texturename[], materialcolor)
{
	new Index = GetIndexFromObjectID(objectid);
	if(Index == -1) return false;
	
	if(!MAPMOVER_OBJECT_INFO[Index][EDITOR]) return false;
	if(!MAPMOVER_OBJECT_INFO[Index][TEXTURED]) MAPMOVER_OBJECT_INFO[Index][TEXTURED] = true;
	
	new count = MAPMOVER_OBJECT_INFO[Index][TEXTURE_COUNT];
	if(count == 16) return false;
	
	MAPMOVER_OBJECT_MATERIAL_INFO[Index][count][map_materialindex] = materialindex;
	MAPMOVER_OBJECT_MATERIAL_INFO[Index][count][map_modelid] = modelid;
	format(MAPMOVER_OBJECT_MATERIAL_INFO[Index][count][map_txdname], 24, txdname);
	format(MAPMOVER_OBJECT_MATERIAL_INFO[Index][count][map_texturename], 24, texturename);
	MAPMOVER_OBJECT_MATERIAL_INFO[Index][count][map_materialcolor] = materialcolor;
	
	MAPMOVER_OBJECT_INFO[Index][TEXTURE_COUNT] += 1;
	return 1;
}

public OnObjectTextTextured(objectid, text[], materialindex, materialsize, fontface[], fontsize, bold, fontcolor, backcolor, textalignment)
{

	new Index = GetIndexFromObjectID(objectid);
	if(Index == -1) return false;
	
	if(!MAPMOVER_OBJECT_INFO[Index][EDITOR]) return false;
	if(!MAPMOVER_OBJECT_INFO[Index][TEXTTEXTURED]) MAPMOVER_OBJECT_INFO[Index][TEXTTEXTURED] = true;
	
	new count = MAPMOVER_OBJECT_INFO[Index][TEXTTEXTURE_COUNT];
	if(count == 16) return false;
	
	format(MAPMOVER_OBJECT_MTEXT_INFO[Index][count][map_text], 256, text);
	MAPMOVER_OBJECT_MTEXT_INFO[Index][count][map_mindex] = materialindex;
	MAPMOVER_OBJECT_MTEXT_INFO[Index][count][map_materialsize] = materialsize;
	format(MAPMOVER_OBJECT_MTEXT_INFO[Index][count][map_fontface], 24, fontface);
	MAPMOVER_OBJECT_MTEXT_INFO[Index][count][map_fontsize] = fontsize;
	MAPMOVER_OBJECT_MTEXT_INFO[Index][count][map_bold] = bold;
	MAPMOVER_OBJECT_MTEXT_INFO[Index][count][map_fontcolor] = fontcolor;
	MAPMOVER_OBJECT_MTEXT_INFO[Index][count][map_backcolor] = backcolor;
	MAPMOVER_OBJECT_MTEXT_INFO[Index][count][map_textalignment] = textalignment;
	
	MAPMOVER_OBJECT_INFO[Index][TEXTTEXTURE_COUNT] += 1;
	return 1;
}

public OnMapLoaded(count)
{
	mapmoverMapStatus = mapLoaded;
	
	
	printf("Map loaded, total objects loades: %d", count);
	new str[45]; format(str, sizeof str, "{CCCCCC}Map loaded, total objects: %d", count);
	SendClientMessage(0, -1, str);
	return 1;
}


stock MoveObjectWithCursor(objectid, Float: ScreenX, Float: ScreenY) {
	new
		Float: cX,
		Float: cY,
		Float: cZ,
		Float: oX,
		Float: oY,
		Float: oZ,
		Float: vX,
		Float: vY,
		Float: vZ,
		Float: distance
	;
	ScreenToWorld(mapmoverPlayerID, ScreenX, ScreenY, vX, vY, vZ);

	GetPlayerCameraPos(mapmoverPlayerID, cX, cY, cZ);
	GetObjectPos(objectid, oX, oY, oZ);

	distance = floatabs((cZ - oZ) / vZ);

	oX = cX + vX * distance;
	oY = cY + vY * distance;

	StopObject(objectid);
	SetObjectPos(objectid, oX, oY, oZ);
}

OnCursorPositionChange(NewX, NewY) 
{
	if(gMoveObject != INVALID_OBJECT_ID) 
	{
		if(mapmoverMode == mMovingByCursor)
		{

			MoveObjectWithCursor(gMoveObject,
				(NewX * cOnScreenX / ScreenWidth) - OffsetX,
				(NewY * cOnScreenY / ScreenHeight) - OffsetY
			);
			
		}
	}
}

forward OnEditorUpdate();
public OnEditorUpdate() {
	GetMousePos(Cursor_X, Cursor_Y);

	if(Cursor_oX != Cursor_X || Cursor_oY != Cursor_Y) 
	{
		static
			Float: offX,
			Float: offY,
			Float: speed
		;
		offX = ((Cursor_X - Cursor_oX) * cOnScreenX / ScreenWidth);
		offY = ((Cursor_Y - Cursor_oY) * cOnScreenY / ScreenHeight);

		speed = VectorSize(offX, offY, 0.0) * 0.01;

		OffsetX -= offX * speed;
		OffsetY -= offY * speed;

		OnCursorPositionChange((Cursor_oX = Cursor_X), (Cursor_oY = Cursor_Y));
	}
}

public OnVirtualKeyDown(key) 
{

	if(key == VK_SPACE) 
	{
		if(mapmoverMode == mMovingByCursor && mapmoverMoveMode == MOVEMODE_CURSOR_AROUND)
		{
			mapmoverMoveMode = MOVEMODE_NONE;
			CancelSelectTextDraw(mapmoverPlayerID);
		}
		return 1;
	}
	if(key == VK_LBUTTON) 
	{
		if(mapmoverMode == mMovingByCursor)
		{

			new
				Float: oX,
				Float: oY,
				Float: oZ,
				Float: cX,
				Float: cY,
				Float: cZ,
				Float: screenX,
				Float: screenY,
				Float: cursorX,
				Float: cursorY
			;
			GetMousePos(Cursor_X, Cursor_Y);
			GetPlayerCameraPos(0, cX, cY, cZ);
			GetPlayerCameraFrontVector(0, oX, oY, oZ);

			cX += oX * 500.0;
			cY += oY * 500.0;
			cZ += oZ * 500.0;

			cursorX = Cursor_X * cOnScreenX / ScreenWidth;
			cursorY = Cursor_Y * cOnScreenY / ScreenHeight;

			if(GetObjectPos(CenterObject, oX, oY, oZ) && WorldToScreen(0, oX, oY, oZ, screenX, screenY)) 
			{
				screenX = cursorX - screenX;
				screenY = cursorY - screenY;
				gMoveObject = CenterObject;
				OffsetX = screenX;
				OffsetY = screenY;
			}
			gTimerid = SetTimer("OnEditorUpdate", 25, true);
			GetMousePos(Cursor_oX, Cursor_oY);
			
		}
		return 1;
	}
	return 1;
}

public OnVirtualKeyRelease(key) 
{
	if(key == VK_RSHIFT) //Right shift
	{
		if(mapmoverMode != mNone) cmd_mapmover(mapmoverPlayerID, "");
		return 1;
	}
	if(key == VK_SPACE) 
	{
		if(mapmoverMode == mMovingByCursor)
		{
			mapmoverMoveMode = MOVEMODE_CURSOR_AROUND;
			SelectTextDraw(mapmoverPlayerID, -1);
		}
		return 1;
	}
	if(key == VK_LBUTTON && gMoveObject != INVALID_OBJECT_ID && mapmoverMode == mMovingByCursor) 
	{
		gMoveObject = INVALID_OBJECT_ID;
		KillTimer(gTimerid);
		return 1;
	}
	
	return 1;
}



stock GetIndexFromObjectID(objectid)
{
	for(new i = 0; i != sizeof(MAPMOVER_OBJECT_INFO); i++)
	{
	    if(MAPMOVER_OBJECT_INFO[i][objectID] == objectid)
	    {
	        return i;
	    }
	}
	return -1;
}


stock TextureImportedObject(index, objectid)
{
	for(new i = 0; i != MAPMOVER_OBJECT_INFO[index][TEXTURE_COUNT]; i ++)
	{
		SetObjectMaterial(objectid, MAPMOVER_OBJECT_MATERIAL_INFO[index][i][map_materialindex], MAPMOVER_OBJECT_MATERIAL_INFO[index][i][map_modelid], MAPMOVER_OBJECT_MATERIAL_INFO[index][i][map_txdname], MAPMOVER_OBJECT_MATERIAL_INFO[index][i][map_texturename], MAPMOVER_OBJECT_MATERIAL_INFO[index][i][map_materialcolor]);
	}
	return 1;
}

stock TextTextureImportedObject(index, objectid)
{
	for(new i = 0; i != MAPMOVER_OBJECT_INFO[index][TEXTTEXTURE_COUNT]; i ++)
	{
		SetObjectMaterialText(objectid, MAPMOVER_OBJECT_MTEXT_INFO[index][i][map_text], MAPMOVER_OBJECT_MTEXT_INFO[index][i][map_mindex], MAPMOVER_OBJECT_MTEXT_INFO[index][i][map_materialsize], MAPMOVER_OBJECT_MTEXT_INFO[index][i][map_fontface], MAPMOVER_OBJECT_MTEXT_INFO[index][i][map_fontsize], MAPMOVER_OBJECT_MTEXT_INFO[index][i][map_bold], MAPMOVER_OBJECT_MTEXT_INFO[index][i][map_fontcolor], MAPMOVER_OBJECT_MTEXT_INFO[index][i][map_backcolor], MAPMOVER_OBJECT_MTEXT_INFO[index][i][map_textalignment]);
	}
	return 1;
}

//-------------------------------------------------- STYLOCK --------------------------------------------------
AttachObjectToObjectEx(attachoid, Float:off_x, Float:off_y, Float:off_z, Float:rot_x, Float:rot_y, Float:rot_z, &Float:X, &Float:Y, &Float:Z, &Float:RX, &Float:RY, &Float:RZ, pobject = -1) // By Stylock - http://forum.sa-mp.com/member.php?u=114165
{
	static
		Float:sin[3],
		Float:cos[3],
		Float:pos[3],
		Float:rot[3];
	if(pobject == -1)
	{
		GetObjectPos(attachoid, pos[0], pos[1], pos[2]);
		GetObjectRot(attachoid, rot[0], rot[1], rot[2]);
	}
	else
	{
		GetPlayerObjectPos(pobject, attachoid, pos[0], pos[1], pos[2]);
		GetPlayerObjectRot(pobject, attachoid, rot[0], rot[1], rot[2]);
	}
	EDIT_FloatEulerFix(rot[0], rot[1], rot[2]);
	cos[0] = floatcos(rot[0], degrees); cos[1] = floatcos(rot[1], degrees); cos[2] = floatcos(rot[2], degrees); sin[0] = floatsin(rot[0], degrees); sin[1] = floatsin(rot[1], degrees); sin[2] = floatsin(rot[2], degrees);
	pos[0] = pos[0] + off_x * cos[1] * cos[2] - off_x * sin[0] * sin[1] * sin[2] - off_y * cos[0] * sin[2] + off_z * sin[1] * cos[2] + off_z * sin[0] * cos[1] * sin[2];
	pos[1] = pos[1] + off_x * cos[1] * sin[2] + off_x * sin[0] * sin[1] * cos[2] + off_y * cos[0] * cos[2] + off_z * sin[1] * sin[2] - off_z * sin[0] * cos[1] * cos[2];
	pos[2] = pos[2] - off_x * cos[0] * sin[1] + off_y * sin[0] + off_z * cos[0] * cos[1];
	rot[0] = asin(cos[0] * cos[1]); rot[1] = atan2(sin[0], cos[0] * sin[1]) + rot_z; rot[2] = atan2(cos[1] * cos[2] * sin[0] - sin[1] * sin[2], cos[2] * sin[1] - cos[1] * sin[0] * -sin[2]);
	cos[0] = floatcos(rot[0], degrees); cos[1] = floatcos(rot[1], degrees); cos[2] = floatcos(rot[2], degrees); sin[0] = floatsin(rot[0], degrees); sin[1] = floatsin(rot[1], degrees); sin[2] = floatsin(rot[2], degrees);
	rot[0] = asin(cos[0] * sin[1]); rot[1] = atan2(cos[0] * cos[1], sin[0]); rot[2] = atan2(cos[2] * sin[0] * sin[1] - cos[1] * sin[2], cos[1] * cos[2] + sin[0] * sin[1] * sin[2]);
	cos[0] = floatcos(rot[0], degrees); cos[1] = floatcos(rot[1], degrees); cos[2] = floatcos(rot[2], degrees); sin[0] = floatsin(rot[0], degrees); sin[1] = floatsin(rot[1], degrees); sin[2] = floatsin(rot[2], degrees);
	rot[0] = atan2(sin[0], cos[0] * cos[1]) + rot_x; rot[1] = asin(cos[0] * sin[1]); rot[2] = atan2(cos[2] * sin[0] * sin[1] + cos[1] * sin[2], cos[1] * cos[2] - sin[0] * sin[1] * sin[2]);
	cos[0] = floatcos(rot[0], degrees); cos[1] = floatcos(rot[1], degrees); cos[2] = floatcos(rot[2], degrees); sin[0] = floatsin(rot[0], degrees); sin[1] = floatsin(rot[1], degrees); sin[2] = floatsin(rot[2], degrees);
	rot[0] = asin(cos[1] * sin[0]); rot[1] = atan2(sin[1], cos[0] * cos[1]) + rot_y; rot[2] = atan2(cos[0] * sin[2] - cos[2] * sin[0] * sin[1], cos[0] * cos[2] + sin[0] * sin[1] * sin[2]);
	X = pos[0];
	Y = pos[1];
	Z = pos[2];
	RX = rot[0];
	RY = rot[1];
 	RZ = rot[2];
}


EDIT_FloatEulerFix(&Float:rot_x, &Float:rot_y, &Float:rot_z)
{
    EDIT_FloatGetRemainder(rot_x, rot_y, rot_z);
    if((!floatcmp(rot_x, 0.0) || !floatcmp(rot_x, 360.0))
    && (!floatcmp(rot_y, 0.0) || !floatcmp(rot_y, 360.0)))
    {
        rot_y = 0.0000002;
    }
    return 1;
}

EDIT_FloatGetRemainder(&Float:rot_x, &Float:rot_y, &Float:rot_z)
{
    EDIT_FloatRemainder(rot_x, 360.0);
    EDIT_FloatRemainder(rot_y, 360.0);
    EDIT_FloatRemainder(rot_z, 360.0);
    return 1;
}

EDIT_FloatRemainder(&Float:remainder, Float:value)
{
    if(remainder >= value)
    {
        while(remainder >= value)
        {
            remainder = remainder - value;
        }
    }
    else if(remainder < 0.0)
    {
        while(remainder < 0.0)
        {
            remainder = remainder + value;
        }
    }
    return 1;
}
//-------------------------------------------------- STYLOCK --------------------------------------------------



SaveMap()
{
	new File:codefile = fopen("map_moved.txt", io_write);
	if(codefile)
	{
		new Year, Month, Day;
		getdate(Year, Month, Day);
		new Hour, Minute, Second;
		gettime(Hour, Minute, Second);
		new intro[128]; format(intro, 128, "MAP MOVER 2.1 ~ %02d/%02d/%d ~ %02d:%02d:%02d\r\n\r\n", Day, Month, Year, Hour, Minute, Second);
		fwrite(codefile, intro);
		fwrite(codefile, "new tmpobjid;\r\n\r\n");
		for(new i = 0; i != MAX_MAPMOVER_OBJECTS; i++)
		{
			if(MAPMOVER_OBJECT_INFO[i][EDITOR])
			{
				new line[128], Float:pos[6];
				GetObjectPos(MAPMOVER_OBJECT_INFO[i][objectID], pos[0], pos[1], pos[2]);
				GetObjectRot(MAPMOVER_OBJECT_INFO[i][objectID], pos[3], pos[4], pos[5]);
				if(MAPMOVER_OBJECT_INFO[i][TEXTURED] || MAPMOVER_OBJECT_INFO[i][TEXTTEXTURED])
				{
					format(line, 128, "tmpobjid = CreateObject(%d, %f, %f, %f, %f, %f, %f);\r\n", GetObjectModel(MAPMOVER_OBJECT_INFO[i][objectID]), pos[0], pos[1], pos[2], pos[3], pos[4], pos[5]);
					fwrite(codefile, line);
					
					if(MAPMOVER_OBJECT_INFO[i][TEXTURED])
					{
						for(new d = 0; d != MAPMOVER_OBJECT_INFO[i][TEXTURE_COUNT]; d ++)
						{
							format(line, 128, "SetObjectMaterial(tmpobjid, %d, %d, \"%s\", \"%s\", %d);\r\n", MAPMOVER_OBJECT_MATERIAL_INFO[i][d][map_materialindex], MAPMOVER_OBJECT_MATERIAL_INFO[i][d][map_modelid], MAPMOVER_OBJECT_MATERIAL_INFO[i][d][map_txdname], MAPMOVER_OBJECT_MATERIAL_INFO[i][d][map_texturename], MAPMOVER_OBJECT_MATERIAL_INFO[i][d][map_materialcolor]);
							fwrite(codefile, line);
						}
					}
					
					if(MAPMOVER_OBJECT_INFO[i][TEXTTEXTURED])
					{
						for(new d = 0; d != MAPMOVER_OBJECT_INFO[i][TEXTTEXTURE_COUNT]; d ++)
						{
							format(line, 128, "SetObjectMaterialText(tmpobjid, \"%s\", %d, %d, \"%s\", %d, %d, %d, %d, %d);\r\n",
							MAPMOVER_OBJECT_MTEXT_INFO[i][d][map_text], MAPMOVER_OBJECT_MTEXT_INFO[i][d][map_mindex], MAPMOVER_OBJECT_MTEXT_INFO[i][d][map_materialsize], MAPMOVER_OBJECT_MTEXT_INFO[i][d][map_fontface], MAPMOVER_OBJECT_MTEXT_INFO[i][d][map_fontsize], MAPMOVER_OBJECT_MTEXT_INFO[i][d][map_bold], MAPMOVER_OBJECT_MTEXT_INFO[i][d][map_fontcolor], MAPMOVER_OBJECT_MTEXT_INFO[i][d][map_backcolor], MAPMOVER_OBJECT_MTEXT_INFO[i][d][map_textalignment]);
							fwrite(codefile, line);
						}
					}
					
				}
				else
				{
					format(line, 128, "CreateObject(%d, %f, %f, %f, %f, %f, %f);\r\n", GetObjectModel(MAPMOVER_OBJECT_INFO[i][objectID]), pos[0], pos[1], pos[2], pos[3], pos[4], pos[5]);
					fwrite(codefile, line);
				}
			}
		}
		fwrite(codefile, "\r\n");
		fwrite(codefile, "\r\n");
		fwrite(codefile, "RemoveBuildings no converted (not necessary).\r\n");
		fwrite(codefile, "MAP MOVER 2.1 BY ADRI1");
		fclose(codefile);
	}

	return 1;
}

Exit()
{
	for(new i = 0; i != MAX_MAPMOVER_OBJECTS; i++)
	{
		if(MAPMOVER_OBJECT_INFO[i][EDITOR]) DestroyObject(MAPMOVER_OBJECT_INFO[i][objectID]);
		for(new d; d < sizeof(MAPMOVER_OBJECT_INFO[]); d++)
		{
			MAPMOVER_OBJECT_INFO[i][OBJECT_INFO: d] = 0;
		}	
		
		for(new d; d < sizeof(MAPMOVER_OBJECT_MATERIAL_INFO[]); d++)
		{
			for(new s; s < sizeof(MAPMOVER_OBJECT_MATERIAL_INFO[][]); s++) MAPMOVER_OBJECT_MATERIAL_INFO[i][s][OBJECTMATERIAL_INFO: d] = 0;
		}
		
		for(new d; d < sizeof(MAPMOVER_OBJECT_MTEXT_INFO[]); d++)
		{
			for(new s; s < sizeof(MAPMOVER_OBJECT_MTEXT_INFO[][]); s++) MAPMOVER_OBJECT_MTEXT_INFO[i][s][OBJECTMATERIALTEXT_INFO: d] = 0;
		}
		
	}
		
	if(IsPlayerUsingFlyMode(mapmoverPlayerID)) CancelFlyMode(mapmoverPlayerID);
	CancelSelectTextDraw(mapmoverPlayerID);
	ShowPlayerDialog(mapmoverPlayerID, -1, 0, "","", "", "");
	gMoveObject = INVALID_OBJECT_ID;
	KillTimer(gTimerid);
	Cursor_oX = 0;
	Cursor_oY = 0;
	Cursor_X = 0;
	Cursor_Y = 0;
	ScreenWidth = 0;
	ScreenHeight = 0;
	OffsetX = 0.0;
	OffsetY = 0.0;
	total_objects_imported = 0;
	mapmoverMode = mNone;
	mapmoverMapStatus = mNone;
	mapmoverMoveMode = MOVEMODE_EDITOBJECT;
	mapmoverPlayerID = -1;
	if(IsValidObject(SetCenterObject)) DestroyObject(SetCenterObject);
	if(IsValidObject(CenterObject))  DestroyObject(CenterObject);
	oldX = 0.0;
	oldY = 0.0;
	oldZ = 0.0;
	oldRotX = 0.0;
	oldRotY = 0.0;
	oldRotZ = 0.0;
	CamOffSetX = 0.0;
	CamOffSetY = 0.0;
	CamOffSetZ = 0.0;
	return 1;
}
