// extracted from iTD, all rights to iPLEOMAX
// http://forum.sa-mp.com/showthread.php?t=376758 

native GetVirtualKeyState(key);

#define VKEYS_INTERVAL 25

enum {
	VK_KEY_A = 0x41,
	VK_KEY_B = 0x42,
	VK_KEY_C = 0x43,
	VK_KEY_D = 0x44,
	VK_KEY_E = 0x45,
	VK_KEY_F = 0x46,
	VK_KEY_G = 0x47,
	VK_KEY_H = 0x48,
	VK_KEY_I = 0x49,
	VK_KEY_J = 0x4A,
	VK_KEY_K = 0x4B,
	VK_KEY_L = 0x4C,
	VK_KEY_M = 0x4D,
	VK_KEY_N = 0x4E,
	VK_KEY_O = 0x4F,
	VK_KEY_P = 0x50,
	VK_KEY_Q = 0x51,
	VK_KEY_R = 0x52,
	VK_KEY_S = 0x53,
	VK_KEY_T = 0x54,
	VK_KEY_U = 0x55,
	VK_KEY_V = 0x56,
	VK_KEY_W = 0x57,
	VK_KEY_X = 0x58,
	VK_KEY_Y = 0x59,
	VK_KEY_Z = 0x5A,
	VK_LBUTTON = 0x01,
	VK_MBUTTON = 0x04,
	VK_RBUTTON = 0x02,
	VK_UP = 0x26,
	VK_DOWN	= 0x28,
	VK_LEFT	= 0x25,
	VK_RIGHT = 0x27,
	VK_LSHIFT = 0xA0,
	VK_RSHIFT = 0xA1,
	VK_SPACE = 0x20
}

#if (defined OnVirtualKeyRelease || defined OnVirtualKeyDown)
	static
		VirtualKeys[] = {
			VK_KEY_A << 24		| VK_KEY_B << 16	| VK_KEY_C << 8		| VK_KEY_D,
			VK_KEY_E << 24		| VK_KEY_F << 16	| VK_KEY_G << 8		| VK_KEY_H,
			VK_KEY_I << 24		| VK_KEY_J << 16	| VK_KEY_K << 8		| VK_KEY_L,
			VK_KEY_M << 24		| VK_KEY_N << 16	| VK_KEY_O << 8		| VK_KEY_P,
			VK_KEY_Q << 24		| VK_KEY_R << 16	| VK_KEY_S << 8		| VK_KEY_T,
			VK_KEY_U << 24		| VK_KEY_V << 16	| VK_KEY_W << 8		| VK_KEY_X,
			VK_KEY_Y << 24		| VK_KEY_Z << 16	| VK_LSHIFT << 8	| VK_RSHIFT,
			VK_UP << 24			| VK_DOWN << 16		| VK_LEFT << 8		| VK_RIGHT,
			VK_LBUTTON << 24	| VK_MBUTTON << 16	| VK_RBUTTON << 8	| VK_SPACE
	},
		bool: vPressed[sizeof VirtualKeys],
		vkeys_timer
	;

	forward VirtualKeysCheck();
	public VirtualKeysCheck() {
		new
			i = (sizeof VirtualKeys * 4)
		;
		while(i--) {
			if(GetVirtualKeyState(VirtualKeys{i}) & 0x8000) {
				if(vPressed{i} == false) {
					#if defined OnVirtualKeyDown
						OnVirtualKeyDown(VirtualKeys{i});
					#endif

					vPressed{i} = true;
				}
			} else if(vPressed{i}) {
				#if defined OnVirtualKeyRelease
					OnVirtualKeyRelease(VirtualKeys{i});
				#endif

				vPressed{i} = false;
			}
		}
		return true;
	}

	forward OnVirtualKeyDown(key);
	forward OnVirtualKeyRelease(key);
#endif

public OnFilterScriptInit() {
	#if (defined OnVirtualKeyRelease || defined OnVirtualKeyDown)
		vkeys_timer = SetTimer("VirtualKeysCheck", VKEYS_INTERVAL, true);
	#endif
	#if defined VKEYS_OnFilterScriptInit
		VKEYS_OnFilterScriptInit();
	#endif
}

public OnFilterScriptExit() {
	#if (defined OnVirtualKeyRelease || defined OnVirtualKeyDown)
		KillTimer(vkeys_timer);
	#endif
	#if defined VKEYS_OnFilterScriptExit
		VKEYS_OnFilterScriptExit();
	#endif
}

public OnGameModeInit() {
	#if (defined OnVirtualKeyRelease || defined OnVirtualKeyDown)
		vkeys_timer = SetTimer("VirtualKeysCheck", VKEYS_INTERVAL, true);
	#endif
	#if defined VKEYS_OnGameModeInit
		VKEYS_OnGameModeInit();
	#endif
}

#if defined _ALS_OnFilterScriptInit
	#undef OnFilterScriptInit
#else
	#define _ALS_OnFilterScriptInit
#endif
#if defined _ALS_OnFilterScriptExit
	#undef OnFilterScriptExit
#else
	#define _ALS_OnFilterScriptExit
#endif
#if defined _ALS_OnGameModeInit
	#undef OnGameModeInit
#else
	#define _ALS_OnGameModeInit
#endif

#define OnFilterScriptInit VKEYS_OnFilterScriptInit
#define OnFilterScriptExit VKEYS_OnFilterScriptExit
#define OnGameModeInit VKEYS_OnGameModeInit

#if defined VKEYS_OnFilterScriptInit
	forward VKEYS_OnFilterScriptInit();
#endif
#if defined VKEYS_OnFilterScriptExit
	forward VKEYS_OnFilterScriptExit();
#endif
#if defined VKEYS_OnGameModeInit
	forward VKEYS_OnGameModeInit();
#endif	