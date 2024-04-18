//
//  Algorithm.h
//  AgoraLyricsScore
//
//  Created by ZYP on 2023/11/9.
//

#ifndef Algorithm_h
#define Algorithm_h

#include <stdio.h>

double pitchToToneC(double pitch);
float calculedScoreC(double voicePitch, double stdPitch, int scoreLevel, int scoreCompensationOffset);

void resetC(void);
double handlePitchC(double stdPitch, double voicePitch, double stdMaxPitch);
#endif /* Algorithm_h */
