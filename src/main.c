#include "common.h"

#include "audio.h"
#include "dma.h"
#include "effect.h"
#include "error.h"
#include "gamemode.h"
#include "joy.h"
#include "memory.h"
#include "resources.h"
#include "stage.h"
#include "system.h"
#include "tools.h"
#include "tsc.h"
#include "vdp.h"
#include "xgm.h"

void aftervsync() {
	disable_ints;
    z80_request();

	DMA_flushQueue();
	vdp_fade_step();
	dqueued = FALSE;
	if(ready) {
		if(inFade) vdp_sprites_clear();
		vdp_sprites_update();
		ready = FALSE;
	}
	if(gamemode == GM_GAME) stage_update(); // Scrolling
	//joy_update();
    
    z80_release();
    enable_ints;

    joy_update();
}

int main() {
    setRandomSeed(0xC427); // initiate random number generator
    mem_init();
    vdp_init();
	xgm_init();
	if(system_checkdata() != SRAM_INVALID) {
		system_load_config();
	}
    DMA_init(0, 0);
	joy_init();
	enable_ints;
    // Initialize time and speed tables (framerate adjusted)
    if(pal_mode) {
		time_tab = time_tab_pal;
        speed_tab = speed_tab_pal;
	} else {
        time_tab = time_tab_ntsc;
        speed_tab = speed_tab_ntsc;
	}
    // let's the fun go on !
    
    sound_init();
	
	// Error Tests
	//__asm__("move.w (1),%d0"); // Address Error
	//__asm__("illegal"); // Illegal Instruction
	//__asm__("divu #0,%d0"); // Zero Divide
	//error_oom(); // Out of memory
	//error_other("Test test!\nTest!"); // Fatal message

	splash_main();
	intro_main();
    while(TRUE) {
		uint8_t select = titlescreen_main();
		if(select == 0) {
			select = saveselect_main();
			if(select >= 4) continue;
			game_main(select);
			credits_main();
		} else if(select == 2) {
			soundtest_main();
		} else if(select == 3) {
			config_main();
		} else {
			game_main(select);
			credits_main();
		}
    }
	return 0;
}
