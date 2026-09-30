#ifndef _WZ265_DEF_H_
#define _WZ265_DEF_H_

// ****************************************
// error code
// error code < 0, means fatal error
// error code > 0, means warning or event
// ****************************************
enum {
  WZ_OK = (0x00000000),                     // Success codes
  WZ_FAIL = (0x80000001),                   //  Unspecified error
  WZ_OUTOFMEMORY = (0x80000002),            //  Out of memory
  WZ_POINTER = (0x80000004),                //  Invalid pointer
  WZ_NOTSUPPORTED = (0x80000008),           //  NOT support feature encountered
  WZ_AUTH_INVALID = (0x80000010),           //  Authentication invalid
  WZ_AUTH_FAIL_APP_ID = (0x80000011),       //  Auth failed use app id
  WZ_AUTH_FAIL_EXPIRE_TIME = (0x80000012),  //  Auth failed use expire time
  WZ_AUTH_FAIL_MTOOL = (0x80000014),        //  Auth failed use mtool
  WZ265_PARAM_BAD_NAME = (0x80000018),      //  Bad name pass to WZ265ConfigParse
  WZ265_PARAM_BAD_VALUE = (0x80000020),     //  Bad value pass to WZ265ConfigParse

  WZ_SEARCHING_ACCESS_POINT = (0x00010000),  // In process of searching first access point
  WZ_REF_PIC_NOT_FOUND = (0x00020000),       // Reference picture not found, can be ignored
  WZ_NEED_MORE_DATA = (0x00040000),          // need push more data
  WZ_BITSTREAM_ERROR = (0x00080000),         // detecting bit stream error, can be ignored
  WZ_SKIPPING_LP_PIC = (0x00100000),         // leading pic skipped, can be ignored
  WZ_SKIPPING_PIC = (0x00110000),            // skippable picture skipped, can be ignored
  WZ_CTU_REENCODE = (0x81000000),            // CTU re-encode
};

typedef enum NAL_UNIT_TYPE {
  NAL_UNIT_TYPE_TRAIL_N = 0,
  NAL_UNIT_TYPE_TRAIL_R = 1,

  NAL_UNIT_TYPE_TSA_N = 2,
  NAL_UNIT_TYPE_TSA_R = 3,

  NAL_UNIT_TYPE_STSA_N = 4,
  NAL_UNIT_TYPE_STSA_R = 5,

  NAL_UNIT_TYPE_RADL_N = 6,
  NAL_UNIT_TYPE_RADL_R = 7,

  NAL_UNIT_TYPE_RASL_N = 8,
  NAL_UNIT_TYPE_RASL_R = 9,

  // reserved
  NAL_UNIT_TYPE_RSV_VCL_N10 = 10,
  NAL_UNIT_TYPE_RSV_VCL_N12 = 12,
  NAL_UNIT_TYPE_RSV_VCL_N14 = 13,
  NAL_UNIT_TYPE_RSV_VCL_R11 = 11,
  NAL_UNIT_TYPE_RSV_VCL_R13 = 13,
  NAL_UNIT_TYPE_RSV_VCL_R15 = 15,

  NAL_UNIT_TYPE_BLA_W_LP = 16,
  NAL_UNIT_TYPE_BLA_W_RADL = 17,
  NAL_UNIT_TYPE_BLA_N_LP = 18,

  NAL_UNIT_TYPE_IDR_W_RADL = 19,
  NAL_UNIT_TYPE_IDR_N_LP = 20,

  NAL_UNIT_TYPE_CRA_NUT = 21,

  NAL_UNIT_TYPE_RSV_IRAP_VCL22 = 22,
  NAL_UNIT_TYPE_RSV_IRAP_VCL23 = 23,

  NAL_UNIT_TYPE_RSV_VCL24 = 24,
  NAL_UNIT_TYPE_RSV_VCL25 = 25,
  NAL_UNIT_TYPE_RSV_VCL26 = 26,
  NAL_UNIT_TYPE_RSV_VCL27 = 27,
  NAL_UNIT_TYPE_RSV_VCL28 = 28,
  NAL_UNIT_TYPE_RSV_VCL29 = 29,
  NAL_UNIT_TYPE_RSV_VCL30 = 30,
  NAL_UNIT_TYPE_RSV_VCL31 = 31,

  NAL_UNIT_TYPE_VPS_NUT = 32,
  NAL_UNIT_TYPE_SPS_NUT = 33,
  NAL_UNIT_TYPE_PPS_NUT = 34,
  NAL_UNIT_TYPE_AUD_NUT = 35,
  NAL_UNIT_TYPE_EOS_NUT = 36,
  NAL_UNIT_TYPE_EOB_NUT = 37,
  NAL_UNIT_TYPE_FD_NUT = 38,

  NAL_UNIT_TYPE_PREFIX_SEI_NUT = 39,
  NAL_UNIT_TYPE_SUFFIX_SEI_NUT = 40,

  NAL_UNIT_TYPE_RSV_NVCL41 = 41,
  NAL_UNIT_TYPE_RSV_NVCL42 = 42,
  NAL_UNIT_TYPE_RSV_NVCL43 = 43,
  NAL_UNIT_TYPE_RSV_NVCL44 = 44,
  NAL_UNIT_TYPE_RSV_NVCL45 = 45,
  NAL_UNIT_TYPE_RSV_NVCL46 = 46,
  NAL_UNIT_TYPE_RSV_NVCL47 = 47,

  NAL_UNIT_TYPE_UNSPEC48 = 48,
  NAL_UNIT_TYPE_UNSPEC49 = 49,
  NAL_UNIT_TYPE_UNSPEC50 = 50,
  NAL_UNIT_TYPE_UNSPEC51 = 51,
  NAL_UNIT_TYPE_UNSPEC52 = 52,
  NAL_UNIT_TYPE_UNSPEC53 = 53,
  NAL_UNIT_TYPE_UNSPEC54 = 54,
  NAL_UNIT_TYPE_UNSPEC55 = 55,
  NAL_UNIT_TYPE_UNSPEC56 = 56,
  NAL_UNIT_TYPE_UNSPEC57 = 57,
  NAL_UNIT_TYPE_UNSPEC58 = 58,
  NAL_UNIT_TYPE_UNSPEC59 = 59,
  NAL_UNIT_TYPE_UNSPEC60 = 60,
  NAL_UNIT_TYPE_UNSPEC61 = 61,
  NAL_UNIT_TYPE_UNSPEC62 = 62,
  NAL_UNIT_TYPE_UNSPEC63 = 63,
} NAL_UNIT_TYPE;

typedef enum SEI_PAYLOAD_TYPE {
  BUFFERING_PERIOD = 0,
  PICTURE_TIMING = 1,
  PAN_SCAN_RECT = 2,
  FILLER_PAYLOAD = 3,
  USER_DATA_REGISTERED_ITU_T_T35 = 4,
  USER_DATA_UNREGISTERED = 5,
  RECOVERY_POINT = 6,
  SCENE_INFO = 9,
  FULL_FRAME_SNAPSHOT = 15,
  PROGRESSIVE_REFINEMENT_SEGMENT_START = 16,
  PROGRESSIVE_REFINEMENT_SEGMENT_END = 17,
  FILM_GRAIN_CHARACTERISTICS = 19,
  POST_FILTER_HINT = 22,
  TONE_MAPPING_INFO = 23,
  FRAME_PACKING = 45,
  DISPLAY_ORIENTATION = 47,
  SOP_DESCRIPTION = 128,
  ACTIVE_PARAMETER_SETS = 129,
  DECODING_UNIT_INFO = 130,
  TEMPORAL_LEVEL0_INDEX = 131,
  DECODED_PICTURE_HASH = 132,
  SCALABLE_NESTING = 133,
  REGION_REFRESH_INFO = 134,
  MASTERING_DISPLAY_INFO = 137,
  CONTENT_LIGHT_LEVEL_INFO = 144,
  ALTERNATIVE_TRANSFER_CHARACTERISTICS = 147,
  AMBIENT_VIEWING_ENVIRONMENT = 148,
} SEIPayloadType;

typedef struct WZ265SEIPayload {
  int payloadSize;        // actual bytes in payload
  int payloadBufferSize;  // bytes malloc for payload
  SEIPayloadType payloadType;
  unsigned char *payload;
} WZ265SEIPayload;

typedef struct WZ265SEI {
  int numPayloads;  // number of payloads has valid data
  WZ265SEIPayload *payloads;
} WZ265SEI;

// dobly vision rpu
typedef struct WZ265DoviRpu {
  int payloadSize;
  unsigned char *payloads;
} WZ265DoviRpu;

// ****************************************
// HRD
// ****************************************
typedef struct hrd_parameters {
  int bit_rate_scale;
  int cpb_size_scale;
  int initial_cpb_removal_delay_length;
  int cpb_removal_delay_length;
  int dpb_output_delay_length;
  int bit_rate_value;
  int cpb_size_value;
  int cbr_flag;
} hrd_parameters;

// ****************************************
// VUI
// ****************************************
typedef struct vui_parameters {
  // --- sample aspect ratio (SAR) ---
  unsigned char aspect_ratio_info_present_flag;
  unsigned char aspect_ratio_idc;
  unsigned short sar_width;  // sar_width and sar_height are zero if unspecified
  unsigned short sar_height;

  // --- overscan ---
  unsigned char overscan_info_present_flag;
  unsigned char overscan_appropriate_flag;

  // --- video signal type ---
  unsigned char video_signal_type_present_flag;
  unsigned char video_format;
  unsigned char video_full_range_flag;
  unsigned char colour_description_present_flag;
  unsigned char colour_primaries;
  unsigned char transfer_characteristics;
  unsigned char matrix_coeffs;

  // --- chroma / interlaced ---
  unsigned char chroma_loc_info_present_flag;
  unsigned char chroma_sample_loc_type_top_field;
  unsigned char chroma_sample_loc_type_bottom_field;
  unsigned char neutral_chroma_indication_flag;
  unsigned char field_seq_flag;
  unsigned char frame_field_info_present_flag;

  // --- default display window ---
  unsigned char default_display_window_flag;
  unsigned int def_disp_win_left_offset;
  unsigned int def_disp_win_right_offset;
  unsigned int def_disp_win_top_offset;
  unsigned int def_disp_win_bottom_offset;

  // --- timing ---
  unsigned char vui_timing_info_present_flag;
  unsigned int vui_num_units_in_tick;
  unsigned int vui_time_scale;

  unsigned char vui_poc_proportional_to_timing_flag;
  unsigned int vui_num_ticks_poc_diff_one;

  // --- hrd parameters ---
  unsigned char vui_hrd_parameters_present_flag;
  hrd_parameters vui_hrd_parameters;

  // --- bitstream restriction ---
  unsigned char bitstream_restriction_flag;
  unsigned char tiles_fixed_structure_flag;
  unsigned char motion_vectors_over_pic_boundaries_flag;
  unsigned char restricted_ref_pic_lists_flag;
  unsigned short min_spatial_segmentation_idc;
  unsigned char max_bytes_per_pic_denom;
  unsigned char max_bits_per_mincu_denom;
  unsigned char log2_max_mv_length_horizontal;
  unsigned char log2_max_mv_length_vertical;
} vui_parameters;

typedef struct mastering_display_colour_volume_sei {
  unsigned short display_primaries_x[3];
  unsigned short display_primaries_y[3];
  unsigned short white_point_x;
  unsigned short white_point_y;
  unsigned int max_display_mastering_luminance;
  unsigned int min_display_mastering_luminance;
} mastering_display_colour_volume_sei;

typedef struct content_light_level_info_sei {
  unsigned short max_content_light_level;
  unsigned short max_pic_average_light_level;
} content_light_level_info_sei;

// ambient viewing environment SEI
typedef struct ambient_viewing_environment_sei {
  unsigned int ambient_illuminance;
  unsigned int ambient_light_x;
  unsigned int ambient_light_y;
} ambient_viewing_environment_sei;

typedef struct buffering_period_sei {
  unsigned int m_cpbDelayOffset;
  unsigned int m_dpbDelayOffset;
  unsigned int m_concatenationFlag;
  unsigned int m_initialCpbRemovalDelay;
  unsigned int m_initialCpbRemovalDelayOffset;
  unsigned int m_auCpbRemovalDelayDelta;
} buffering_period_sei;

typedef struct picture_timing_sei {
  unsigned int m_picStruct;
  unsigned int m_sourceScanType;
  unsigned int m_duplicateFlag;
  unsigned int m_auCpbRemovalDelay;
  unsigned int m_picDpbOutputDelay;
} picture_timing_sei;

#ifdef WIN32
#define _h_dll_export __declspec(dllexport)
#else  // for GCC
#define _h_dll_export __attribute__((visibility("default")))
#endif

typedef void (*WZAuthWarning)(void);
typedef void (*WZLogPrintf)(const char *msg);

#if defined(__cplusplus)
extern "C" {
#endif  //__cplusplus

// @OBFUSAPI@

// log output callback function pointer
// if  pFuncCB == NULL, use the default printf
_h_dll_export void wz265_set_log_printf(WZLogPrintf pFuncCB);

// auth trouble warning callback function pointer
_h_dll_export void wz265_set_auth_warning(WZAuthWarning pFuncCB);

// auth info
// return auth_ok means auth ok, otherwize means auth fail
_h_dll_export int wz265_get_auth_info(void);

// libwz265 version number string
_h_dll_export extern const char strLibWZ265Version[];

// Get libwz265 version string
_h_dll_export const char *wz265_version_str(void);

#if defined(__cplusplus)
}
#endif  //__cplusplus

#endif
