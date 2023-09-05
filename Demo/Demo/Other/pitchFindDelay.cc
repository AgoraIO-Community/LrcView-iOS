/*
 *  Copyright (c) 2023 Agora Uplink Audio Processing. All Rights Reserved.
 *
 *  @ Jimeng Zheng
 *  by what license terms? I don't know. this is not part of any open-source project
 */

#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "pitchFindDelay.h"

#define AGORA_KGE_SCORE_MIN(x, y) ((x) > (y) ? (y) : (x))
#define AGORA_KGE_SCORE_MAX(x, y) ((x) > (y) ? (x) : (y))

// return value: 0 = success, -1 = error
int agora_kge_score_finddelay(const KgeScoreFinddelayCfg_t* cfg,
    const float* rawRefPitch,
    float* tmpBuffer1,
    const float* rawUserPitch,
    float* tmpBuffer2,
    KgeScoreFinddelayResult_t* result)
{
    int refPitchCnt = 0;
    float refPitchLen = 0;
    int refLeftEdgeIdx = -1, refRightEdgeIdx = -1;
    int refEffLen = 0;
    int userPitchCnt = 0;
    float userPitchLen = 0;
    int userLeftEdgeIdx = -1, userRightEdgeIdx = -1;
    int userEffLen = 0;
    
    int refStartIdx = 0;
    int refStopIdx = 0;
    int refOffset = 0;
    float convRatio = 1.0f;

    int idx, refAccIdx, xAccCnt, yAccCnt, effAccCnt, bestIdx;
    float xVal, xRawVal, yVal, yRawVal, corrSum, xSqSum, ySqSum, yStd, xSqSumTotal, ySqSumTotal;
    float meanX, meanY, corrCoeff, bestCorrCoeff;
    float tmpFloat;

    FILE* FPtr = NULL;
    int FOpenTriedFlag = 0;

    float* refPitch = tmpBuffer1;
    float* userPitch = tmpBuffer2;

    if (cfg == NULL || rawRefPitch == NULL|| refPitch == NULL || rawUserPitch == NULL || userPitch == NULL || result == NULL) {
        return(-1);
    }
    if (cfg->refPitchLen == 0 || cfg->userPitchLen == 0 || cfg->refPitchInterval <= 0 || cfg->userPitchInterval <= 0) {
        return(-1);
    }

    convRatio = cfg->userPitchInterval / cfg->refPitchInterval;

    memset(result, 0, sizeof(KgeScoreFinddelayResult_t));
    result->usableFlag = 0;
    result->refPitchFirstIdx = -1;
    result->userPitchFirstIdx = -1;

    refPitch[0] = rawRefPitch[0];
    for (idx = 1; idx < cfg->refPitchLen; idx++) {
        if (rawRefPitch[idx] == 0) {
            refPitch[idx] = 0;
        }
        else {
            refPitch[idx] = refPitch[idx - 1] * 0.7f + 0.3f * rawRefPitch[idx];
        }
    }
    userPitch[0] = rawUserPitch[0];
    for (idx = 1; idx < cfg->userPitchLen; idx++) {
        if (rawUserPitch[idx] == 0) {
            userPitch[idx] = 0;
        }
        else {
            userPitch[idx] = userPitch[idx - 1] * 0.7f + 0.3f * rawUserPitch[idx];
        }
    }

    // find how many non-zero refPitch ......
    meanX = 0;
    xAccCnt = 0;
    for (idx = 0; idx < cfg->refPitchLen; idx++) {
        if (refPitch[idx] > 0) {
            refPitchCnt++;
            meanX += refPitch[idx];
            xAccCnt++;
        }
    }
    meanX = meanX / xAccCnt;
    refPitchLen = refPitchCnt * cfg->refPitchInterval;
    xSqSumTotal = 0;
    for (idx = 0; idx < cfg->refPitchLen; idx++) {
        if (refPitch[idx] > 0 && refLeftEdgeIdx == -1) {
            refLeftEdgeIdx = idx;
        }
        if (refPitch[idx] > 0) {
            refRightEdgeIdx = idx;
        }
        xSqSumTotal += (refPitch[idx]) * (refPitch[idx]);
        //if (refPitch[idx] > 0) {
        //    xSqSumTotal += (refPitch[idx] - meanX) * (refPitch[idx] - meanX);
        //}
    }

    // find how many non-zero userPitch is available ....
    meanY = 0;
    yAccCnt = 0;
    for (idx = 0; idx < cfg->userPitchLen; idx++) {
        if (userPitch[idx] > 0) {
            userPitchCnt++;
            meanY += userPitch[idx];
            yAccCnt++;
        }
    }
    meanY = meanY / yAccCnt;
    userPitchLen = userPitchCnt * cfg->userPitchInterval;
    ySqSumTotal = 0;
    for (idx = 0; idx < cfg->userPitchLen; idx++) {
        if (userPitch[idx] > 0 && userLeftEdgeIdx == -1) {
            userLeftEdgeIdx = idx;
        }
        if (userPitch[idx] > 0) {
            userRightEdgeIdx = idx;
        }
        ySqSumTotal += (userPitch[idx]) * (userPitch[idx]);
        //if (userPitch[idx] > 0) {
        //    ySqSumTotal += (userPitch[idx] - meanY) * (userPitch[idx] - meanY);
        //}
    }

    refEffLen = refRightEdgeIdx - refLeftEdgeIdx;
    userEffLen = userRightEdgeIdx - userLeftEdgeIdx;

    if (cfg->debugFlag != 0) {
        printf("Internal Debug:  Ref: [L = %d, R = %d, Len = %d]\n", refLeftEdgeIdx, refRightEdgeIdx, refEffLen);
        printf("Internal Debug:  User: [L = %d, R = %d, Len = %d]\n", userLeftEdgeIdx, userRightEdgeIdx, userEffLen);
        printf("RefPitchLen = %f, UserPitchLen = %f, Ratio = %f\n", refPitchLen, userPitchLen, (userPitchLen / (refPitchLen + 1)));
        result->refPicthLeft = refLeftEdgeIdx;
        result->refPicthRight = refRightEdgeIdx;
        result->userPicthLeft = userLeftEdgeIdx;
        result->userPicthRight = userRightEdgeIdx;
    }

    if (refLeftEdgeIdx == -1 || refRightEdgeIdx == -1 || refEffLen <= 0) {
        return(-1);  // reference message not usable
    }
    if (userLeftEdgeIdx == -1 || userRightEdgeIdx == -1 || userEffLen <= 0) {
        return(0);  // no enough data, we can do nothing
    }

    if (userPitchLen < cfg->minValidLen || (userPitchLen / (refPitchLen + 1)) < cfg->minValidRatio) {
        if (cfg->debugFlag != 0) {
            float tmpRatio = (userPitchLen / (refPitchLen + 1));
            printf("Warning! no enough userPitch points: userPitchLen = %f, miniValidLen = %f; data ratio = %f, miniValidRatio = %f\n",
                userPitchLen, cfg->minValidLen, tmpRatio, cfg->minValidRatio);
        }
        return(0);  // no enough userPitch points, we can do nothing
    }
    
    refStartIdx = -1 * (int)roundf(AGORA_KGESCORE_FINDDELAY_LEADING_WAITTIME / cfg->refPitchInterval);
    refStopIdx = refRightEdgeIdx - (int)roundf(AGORA_KGESCORE_FINDDELAY_SAFEGUARD / cfg->refPitchInterval);
    refStopIdx = AGORA_KGE_SCORE_MIN(refStopIdx,
        refLeftEdgeIdx + (int)roundf(AGOAR_KGESCORE_HEADLYRICSKIP_TIMELEN / cfg->refPitchInterval));
    
    bestCorrCoeff = -1.0f;
    bestIdx = 0;
    // Correlation core, to find the delay between the 2 time series
    //for (refOffset = refLeftEdgeIdx; refOffset < refStopIdx; refOffset++)
    for (refOffset = refStartIdx; refOffset < refStopIdx; refOffset++)
    {
        // x-array: refPitch[refOffset, ...]
        // y-array: userPitch[userStartIdx, ..., userEndIdx]
        
        //// first. find the mean of the each array ....
        //meanX = 0;
        //meanY = 0;
        //xAccCnt = 0;
        //yAccCnt = 0;
        //for (idx = userLeftEdgeIdx; idx <= userRightEdgeIdx; idx++) {
        //    refAccIdx = (int)roundf((idx - userLeftEdgeIdx) * convRatio);
        //    refAccIdx += refOffset;
        //    if (refAccIdx > refRightEdgeIdx) {
        //        break;
        //    }

        //    if (refAccIdx >= refLeftEdgeIdx && refPitch[refAccIdx] > 0) {
        //        meanX += refPitch[refAccIdx];
        //        xAccCnt++;
        //    }
        //
        //    if (userPitch[idx] > 0) {
        //        meanY += userPitch[idx];
        //        yAccCnt++;
        //    }
        //}
        //meanX = 0;  // meanX / xAccCnt;
        //meanY = 0;  // meanY / yAccCnt;


        // second. find the cross-correlation coefficient of x and y arrays
        corrSum = 0.0f;
        xSqSum = 0.0f;
        ySqSum = 0.0f;
        effAccCnt = 0;
        for (idx = userLeftEdgeIdx; idx <= userRightEdgeIdx; idx++) {
            refAccIdx = (int)roundf((idx - userLeftEdgeIdx) * convRatio);
            refAccIdx += refOffset;
            if (refAccIdx > refRightEdgeIdx) {
                break;
            }

            if (refAccIdx >= refLeftEdgeIdx && refPitch[refAccIdx] > 0) {
                xVal = refPitch[refAccIdx];   // -meanX;
                xRawVal = refPitch[refAccIdx];
            }
            else {
                xVal = 0;
                xRawVal = 0;
            }

            if (userPitch[idx] > 0) {
                yVal = userPitch[idx];  // -meanY;
                yRawVal = userPitch[idx];
            }
            else {
                yVal = 0;
                yRawVal = 0;
            }

            if (xRawVal > 0 && yRawVal > 0) {
                effAccCnt++;
            }
            
            corrSum += xVal * yVal;
            xSqSum += xVal * xVal;
            ySqSum += yVal * yVal;
        }
        // corrCoeff = fabs(corrSum) / (sqrtf(xSqSum * ySqSum) + 0.1f);
        corrCoeff = fabs(corrSum) / (sqrtf(xSqSumTotal * ySqSumTotal) + 0.1f);

        if (cfg->debugFlag != 0) {
            if (FPtr == NULL && FOpenTriedFlag == 0) {
                FPtr = fopen("AgoraKgeScoreFinddelayDebug.txt", "w+");
                FOpenTriedFlag = 1;
            }
            if (FPtr != NULL) {
                fprintf(FPtr, "%d, ", refOffset);
                fprintf(FPtr, "%1.3e, ", corrCoeff);
                fprintf(FPtr, "%1.3e, ", corrSum);
                fprintf(FPtr, "%1.3e, ", xSqSum);
                fprintf(FPtr, "%1.3e, ", ySqSum);
                fprintf(FPtr, "%d, ", effAccCnt);
                fprintf(FPtr, "\n");
            }
        }

        // third. update the best value ....
        if (effAccCnt > cfg->effCorrCntThr && corrCoeff > bestCorrCoeff) {
            bestCorrCoeff = corrCoeff;
            bestIdx = refOffset;
        }
        if (cfg->debugFlag == 3) {
            printf("EffAccCnt = %d (t = %d), Correaltion = %f (best = %f)\n", effAccCnt, cfg->effCorrCntThr, corrCoeff, bestCorrCoeff);
        }
    }

    if (cfg->debugFlag != 0) {
        printf("Internal Debug:  bestCorrCoeff = %f\n", bestCorrCoeff);
        printf("Internal Debug:  bestIdx = %d\n", bestIdx);
    }

    if (bestIdx >= 0) {
        result->refPitchFirstIdx = AGORA_KGE_SCORE_MAX(0, bestIdx);
        result->userPitchFirstIdx = AGORA_KGE_SCORE_MAX(0, userLeftEdgeIdx);
    }
    else {
        result->refPitchFirstIdx = 0;
        result->userPitchFirstIdx = AGORA_KGE_SCORE_MAX(0, userLeftEdgeIdx + (-bestIdx));
    }

    if (bestCorrCoeff > cfg->corrThr) {
        result->usableFlag = 1;
    }
    else {
        if (cfg->debugFlag != 0)
            printf("Internal Debug: Correlation Too Small, result = %1.3f, threshold = %1.3f\n", bestCorrCoeff, cfg->corrThr);
    }

    if (FPtr != NULL) {
        fclose(FPtr);
    }

    return(0);
}



