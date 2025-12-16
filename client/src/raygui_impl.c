#include <stdlib.h>
#define TextToFloat TextToFloatRayguiImpl
static float TextToFloatRayguiImpl(const char* text);
#define RAYGUI_IMPLEMENTATION
#define RAYGUI_SUPPORT_TEXTBOXES
#define RAYGUI_SUPPORT_TEXTBOX_EXTENDED
#include "raygui.h"
#undef TextToFloat

float TextToFloatRayguiImpl(const char* text) { return strtof(text, NULL); }
