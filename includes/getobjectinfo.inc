/*

	MAP MOVER 2.1 INCLUDE
*/


#if defined _mapmover_included
	#endinput
#endif
#define _mapmover_included


new objects_imported_count;
stock MAPMOVER_CreateObject(modelid, Float:X, Float:Y, Float:Z, Float:RX, Float:RY, Float:RZ, Float:drawdistance = 300.0) {
	
	new objectid = CreateObject(modelid, X, Y, Z, RX, RY, RZ, drawdistance);
	CallRemoteFunction("OnObjectImported", "dd", objects_imported_count, objectid);
	objects_imported_count ++;
	return objectid;
}


stock MAPMOVER_SetObjectMaterial(objectid, materialindex, modelid, txdname[], texturename[], materialcolor)
{
    SetObjectMaterial(objectid, materialindex, modelid, txdname, texturename, materialcolor);
	CallRemoteFunction("OnObjectTextured", "dddssd", objectid, materialindex, modelid, txdname, texturename, materialcolor);
    return 1;
}


stock MAPMOVER_SetObjectMaterialText(objectid, text[], materialindex = 0, materialsize = OBJECT_MATERIAL_SIZE_256x128, fontface[] = "Arial", fontsize = 24, bold = 1, fontcolor = 0xFFFFFFFF, backcolor = 0, textalignment = 0)
{
    SetObjectMaterialText(objectid, text, materialindex, materialsize, fontface, fontsize, bold, fontcolor, backcolor, textalignment);
	CallRemoteFunction("OnObjectTextTextured", "dsddsddddd", objectid, text, materialindex, materialsize, fontface, fontsize, bold, fontcolor, backcolor, textalignment);
    return 1;
}

stock MAPMOVER_SetDObjectMaterialText(objectid, materialindex = 0, text[], materialsize = OBJECT_MATERIAL_SIZE_256x128, fontface[] = "Arial", fontsize = 24, bold = 1, fontcolor = 0xFFFFFFFF, backcolor = 0, textalignment = 0)
{
    SetObjectMaterialText(objectid, text, materialindex, materialsize, fontface, fontsize, bold, fontcolor, backcolor, textalignment);
	CallRemoteFunction("OnObjectTextTextured", "dsddsddddd", objectid, text, materialindex, materialsize, fontface, fontsize, bold, fontcolor, backcolor, textalignment);
    return 1;
}
