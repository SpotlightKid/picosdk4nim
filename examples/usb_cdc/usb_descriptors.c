#include <tusb.h>
#include <bsp/board_api.h>

// total length of configuration descriptor
#define CONFIG_TOTAL_LEN    (TUD_CONFIG_DESC_LEN + CFG_TUD_CDC * TUD_CDC_DESC_LEN)

// define endpoint numbers
#define EPNUM_CDC_0_NOTIF   0x81 // notification endpoint for CDC 0
#define EPNUM_CDC_0_OUT     0x02 // out endpoint for CDC 0
#define EPNUM_CDC_0_IN      0x82 // in endpoint for CDC 0

enum {
    ITF_NUM_CDC_0 = 0,
    ITF_NUM_CDC_0_DATA,
    ITF_NUM_TOTAL
};

// String descriptors referenced with .i... in the descriptor tables
enum {
    STRID_LANGID = 0,   // 0: supported language ID
    STRID_MANUFACTURER, // 1: Manufacturer
    STRID_PRODUCT,      // 2: Product
    STRID_SERIAL,       // 3: Serials
    STRID_CDC_0,        // 4: CDC Interface 0
};

// configure descriptor (for 1 CDC interfaces)
uint8_t const desc_configuration[] = {
    // config descriptor | how much power in mA, count of interfaces, ...
    TUD_CONFIG_DESCRIPTOR(1, ITF_NUM_TOTAL, 0, CONFIG_TOTAL_LEN, 0x80, 100),
    // CDC 0: Communication Interface - TODO: get 64 from tusb_config.h
    TUD_CDC_DESCRIPTOR(ITF_NUM_CDC_0, 4, EPNUM_CDC_0_NOTIF, 8, EPNUM_CDC_0_OUT, EPNUM_CDC_0_IN, 64),
};

// array of pointer to string descriptors
char const *string_desc_arr[] = {
    // switched because board is little endian
    (const char[]) { 0x09, 0x04 },  // 0: supported language is English (0x0409)
    "Raspberry Pi",                 // 1: Manufacturer
    "Pico",                         // 2: Product
    NULL,                           // 3: Serials (null so it uses unique ID if available)
    "Custom CDC",                   // 5: CDC Interface 1,
    "RPiReset"                      // 6: Reset Interface
};

// buffer to hold the string descriptor during the request | plus 1 for the null terminator
static uint16_t _desc_str[32 + 1];

// --------------------------------------------------------------------+
// IMPLEMENTATION
// --------------------------------------------------------------------+
uint8_t const * tud_descriptor_configuration_cb(uint8_t index)
{
    // avoid unused parameter warning and keep function signature consistent
    (void)index;

    return desc_configuration;
}

uint16_t const *tud_descriptor_string_cb(uint8_t index, uint16_t langid)
{
    // TODO: check lang id
    (void) langid;
    size_t char_count;

    // Determine which string descriptor to return
    switch (index) {
        case STRID_LANGID:
            memcpy(&_desc_str[1], string_desc_arr[STRID_LANGID], 2);
            char_count = 1;
            break;

        case STRID_SERIAL:
            // try to read the serial from the board
            char_count = board_usb_get_serial(_desc_str + 1, 32);
            break;

        default:
            // COPYRIGHT NOTE: Based on TinyUSB example
            // Windows wants utf16le

            // Determine which string descriptor to return
            if ( !(index < sizeof(string_desc_arr) / sizeof(string_desc_arr[0])) ) {
                return NULL;
            }

            // Copy string descriptor into _desc_str
            const char *str = string_desc_arr[index];

            char_count = strlen(str);
            size_t const max_count = sizeof(_desc_str) / sizeof(_desc_str[0]) - 1; // -1 for string type
            // Cap at max char
            if (char_count > max_count) {
                char_count = max_count;
            }

            // Convert ASCII string into UTF-16
            for (size_t i = 0; i < char_count; i++) {
                _desc_str[1 + i] = str[i];
            }
            break;
    }

    // First byte is the length (including header), second byte is string type
    _desc_str[0] = (uint16_t) ((TUSB_DESC_STRING << 8) | (char_count * 2 + 2));

    return _desc_str;
}

