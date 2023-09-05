/*
 *  Copyright (c) 2023 Agora Uplink Audio Processing. All Rights Reserved.
 *
 *  @ Jimeng Zheng
 *  by what license terms? I don't know. this is not part of open-source project
 */

#ifndef AGORA_PITCHFINDDELAY_H_
#define AGORA_PITCHFINDDELAY_H_

#include <stddef.h>
#include <stdint.h>


#define AGORA_PITCHFINDDELAY_VERSION (20230905)

#define AGORA_KGESCORE_FINDDELAY_LEADING_WAITTIME (4000.0f)   // in ms
// Jim: user can wait at most 4.0second before he pronounce the first song-word
#define AGORA_KGESCORE_FINDDELAY_SAFEGUARD (2000.0f)  // in ms
// Jim: each song cannot be less than 2.0seconds
#define AGOAR_KGESCORE_HEADLYRICSKIP_TIMELEN (3000.0f)  // in ms
// Jim: user can skip at most first 3.0seconds of song-words

typedef struct {
    size_t refPitchLen;       // length of the array refPitch
    float refPitchInterval;   // ref. pitch sample interval, in ms
    size_t userPitchLen;      // length of the array userPitch
    float userPitchInterval;  // user pitch sample interval, in ms

    float minValidLen;        // minimum length of voiced pitches, in ms
    float minValidRatio;      // minimum requirement of voiced pitches vs ref. pitches
    float corrThr;            // threshold on the correlation coefficient to assure reliable alignment
    int effCorrCntThr;        // threshold on the effective correlation points
    int debugFlag;            // flag to enable the module's debug-mode
}KgeScoreFinddelayCfg_t;

typedef struct {
    int usableFlag;   // 0: so far, the delay cannot be determined, 1: yes, usable, refPitchFirstIdx and userPitchFirstIdx contain meaningful value
    size_t refPitchFirstIdx;   // the first index of refPitch array to be used for score calculation
    size_t userPitchFirstIdx;   // the first index of userPitch array to be used for score calculation
    // which means: refPitch[refPitchFirstIdx] and userPitch[userPitchFirstIdx] are aligned
}KgeScoreFinddelayResult_t;

#ifdef __cplusplus
extern "C" {
#endif

// return value: 0 = success, -1 = error
int agora_kge_score_finddelay(const KgeScoreFinddelayCfg_t* cfg,
    const float* rawRefPitch, // array, [refPitchLen], containing the reference pitch
    float* tmpBuffer1,  // array, [refPitchLen], externally provided tmp buffer
    const float* rawUserPitch, // array, [userPitchLen], containing the user pitch
    float* tmpBuffer2,  // array, [userPitchLen], externally provided tmp buffer
    KgeScoreFinddelayResult_t* result   // retured results, externally provided buffer
);

#ifdef __cplusplus
}
#endif

#endif  // AGORA_PITCHFINDDELAY_H_
