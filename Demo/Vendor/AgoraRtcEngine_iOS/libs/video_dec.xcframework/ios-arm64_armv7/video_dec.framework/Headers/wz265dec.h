///////////////////////////////////////////////////
//
//         visionular H265 Codec Library
//
//  Copyright(c) visionular Inc.
//              https://www.visionular.com/
//
///////////////////////////////////////////////////
#ifndef _WZ265_DECODER_INTERFACE_H_
#define _WZ265_DECODER_INTERFACE_H_

#include "wz265def.h"

// config parameters for Decoder
typedef struct WZ265DecConfig {
  void *pAuth;     // WZAuth, invalid if don't need aksk auth
  int threads;     // number of threads used in decoding (0: auto)
  int disableFPP;  // whether disable frame parallel, default 0;  1 indicates synchronization for
                   // RTC case
  // default 0: FPP start from the very start: first frame.
  // > 0: FPP will start with a delay of frames
  int fppStartFrame;
  int parallelledFrames;       // default 0: auto
  int bEnableOutputRecToFile;  // For debug: write reconstruct YUV to File
  char *strRecYuvFileName;     // For debug: file name of YUV
                               // when bEnableOutputRecToFile = 1
  int bEnableDumpBsToFile;     // For debug: write input bs to File
  char *strDumpBsFileName;     // for debug: file name of bs
  int logLevel;                // For debug: log level
  int calcMD5;      // For debug: calculate md5. 0, disabled;1.plane seperated; 2. yuv whole
  int checkMD5Sei;  // For debug: check md5 with md5 in sei
  int parseOnly;
} WZ265DecConfig;

// information of decoded frame
typedef struct WZ265FrameInfo {
  int nWidth;             // frame width
  int nHeight;            // frame height
  int chroma_format_idc;  // 0: Monochrome 1: 420 2: 422 3: 444
  int bitDepth;           // 8 or 10
  long long pts;          // time stamp
  int poc;
} WZ265FrameInfo;

// decoded frame with data and information
typedef struct WZ265Frame {
  int bValid;               // if == 0, no more valid output frame
  unsigned char *pData[3];  // Y U V
  short iStride[3];         // stride for each component
  WZ265FrameInfo frameinfo;
  double fAvgQp;
} WZ265Frame;

#if defined(__cplusplus)
extern "C" {
#endif  //__cplusplus

/************************************************************************************
 * I/F for all usrs
 ************************************************************************************/
// create decoder, return  handle of decoder
_h_dll_export void *wz265_decoder_create(WZ265DecConfig *pDecConfig, int *pStat);
// destroy decoder with specific handle
_h_dll_export void wz265_decoder_destroy(void *pDecoder);
// set config to specific decoder
_h_dll_export void wz265_decoder_config(void *pDecoder, WZ265DecConfig *pDecConfig, int *pStat);
// the input of this function should be one or more NALs;
// if only one wz265NAL, with or without start bytes are both OK
_h_dll_export void wz265_decode_frame(void *pDecoder, const unsigned char *pData, int iLen,
                                      int *pStat, const long long pts);
// bSkip = WZ_FALSE : same as wz265_decode_frame
// bSkip = WZ_TRUE : only decode slice headers in pData, slice data skipped
_h_dll_export void wz265_decode_frame_skip(void *pDecoder, const unsigned char *pData, int iLen,
                                           int *pStat, const long long pts, int bSkip);
// flush decoding, called at end
_h_dll_export void wz265_decode_flush(void *pDecoder, int bClearCachedPics, int *pStat);
// retrieve the output, the function are used for synchronized output, this function need to call
// several time until get NULL
_h_dll_export void wz265_decoder_get_frame(void *pDecoder, WZ265Frame *pFrame, int *pStat);
// return the frame buffer which WZ265DecoderGetOutput get from decoder, each valid
// WZ265DecoderGetOutput should match with a ReturnFrame
_h_dll_export void wz265_decoder_return_frame(void *pDecoder, WZ265Frame *pFrame);

/**
 * dump latest decoded VUI parameters
 * @param pDecoder :   decoder instance
 * @param vui :       fill with decoded vui parameters
 * @param bValid : =0 if no valid vui parameters decoded,
 *                      otherwise =1
 */
_h_dll_export void wz265_dump_vui_parameters(void *pDecoder, vui_parameters *vui, int *bValid);

#if defined(__cplusplus)
}
#endif  //__cplusplus

#endif  // header
