/*

	MAP MOVER 2.1 MAP LOAD
	Put here the map that you want to edit
*/

#include <a_samp>
#include "getobjectinfo"

#define CreateObject 					MAPMOVER_CreateObject
#define CreateDynamicObject 			MAPMOVER_CreateObject
#define SetObjectMaterial				MAPMOVER_SetObjectMaterial
#define SetDynamicObjectMaterial		MAPMOVER_SetObjectMaterial
#define SetObjectMaterialText			MAPMOVER_SetObjectMaterialText
#define SetDynamicObjectMaterialText	MAPMOVER_SetDObjectMaterialText

new playerid = 0; //Enter here playerid that you will use to edit the map. By default is 0.

public OnFilterScriptInit() 
{
	// Put here your map

	
	
	
	//
	
	
	
	CallRemoteFunction("OnMapLoaded", "d", objects_imported_count);
	return 1;
}

