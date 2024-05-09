//
//  Algorithm.c
//  AgoraLyricsScore
//
//  Created by ZYP on 2023/11/9.
//

#include "Algorithm.h"
#import <math.h>
//modify by xuguangjian
#define PTS_version "20231021001"

#define min(a, b) ((a) < (b) ? (a) : (b))
#define max(a, b) ((a) > (b) ? (a) : (b))


double pitchToToneC(double pitch) {
    double eps = 1e-6;
    return (fmax(0, log(pitch / 55 + eps) / log(2))) * 12;
}

float calculedScoreC(double voicePitch, double stdPitch, int scoreLevel, int scoreCompensationOffset) {
    if (voicePitch <= 0) {
        return 0;
    }
    if(stdPitch <= 0){
        return 0;
    }
    
    if(scoreLevel<=0){
        scoreLevel = 1;
    }else if(scoreLevel > 100){
        scoreLevel = 100;
    }
    
    if(scoreCompensationOffset<0){
        scoreCompensationOffset = 0;
    }else if(scoreCompensationOffset > 100){
        scoreCompensationOffset = 100;
    }
    
    double stdTone = pitchToToneC(stdPitch);
    double voiceTone = pitchToToneC(voicePitch);
    
    float match = 1 - (float)scoreLevel / 100 * fabs(voiceTone - stdTone) + (float)scoreCompensationOffset / 100;
    float rate = 1 + ((float)scoreLevel/(float)50);
    
    match = match * 100 * rate;
    
    match = max(0, match);
    match = min(100, match);
    return match;
}

//static double n;
//static double offset;


// octave pitch compensation v0.2
double handlePitchC(double stdPitch, double voicePitch, double stdMaxPitch) {
    
    int cnt = 0;
    double stdTone = pitchToToneC(stdPitch);
    double voiceTone = pitchToToneC(voicePitch);
    
    if (voicePitch <= 0) {
        return 0;
    }
    if(stdPitch <= 0){
        return 0;
    }
    
    if(fabs(voiceTone - stdTone) <= 6){
        return voicePitch;
    }
    else if(voicePitch < stdPitch){
        for(cnt = 0; cnt <11; cnt++){
            voicePitch = 2*voicePitch;
            voiceTone = pitchToToneC(voicePitch);
            if(fabs(voiceTone - stdTone) <= 6){
                return voicePitch;
            }
        }
    }
    else if(voicePitch > stdPitch){
        for(cnt = 0; cnt <11; cnt++){
            voicePitch = voicePitch/2;
            voiceTone = pitchToToneC(voicePitch);
            if(fabs(voiceTone - stdTone) <= 6){
                return voicePitch;
            }
        }
    }
    return voicePitch;
}

void resetC(void) {
//    offset = 0.0;
//    n = 0.0;
}
