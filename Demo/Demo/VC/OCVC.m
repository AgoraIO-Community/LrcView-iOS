//
//  OCVC.m
//  Demo
//
//  Created by ZYP on 2023/2/2.
//

#import "OCVC.h"
@import AgoraLyricsScore;
@import ScoreEffectUI;

@interface OCVC ()<KaraokeDelegate, ILogger>

@end

@implementation OCVC

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor blackColor];
    FileLogger *fileLogger = [[FileLogger alloc] init];
    KaraokeView *karaokeView = [[KaraokeView alloc] initWithFrame:CGRectZero
                                                          loggers:@[[ConsoleLogger new],fileLogger]];
    karaokeView.backgroundImage = [UIImage imageNamed:@"ktv_top_bgIcon"];
    karaokeView.spacing = 5;
    karaokeView.scoringEnabled = YES;
    karaokeView.frame = CGRectMake(0, 100, self.view.bounds.size.width, 380);
    [self.view addSubview:karaokeView];
    karaokeView.delegate = self;
    
    ScoringView *sView = karaokeView.scoringView;
    LyricsView *lView= karaokeView.lyricsView;
    sView.viewHeight = 160;
    sView.topSpaces = 70;
    
    GradeView *gview = [[GradeView alloc] initWithFrame:CGRectMake(15, 110, UIScreen.mainScreen.bounds.size.width - 30, 50)];
    [gview setTitleWithTitle:@"123" customCumulativeScoreText:nil];

    [self.view addSubview:gview];
    [self.view layoutIfNeeded];
    [gview setScoreWithCumulativeScore:1110 totalScore:4000 customCumulativeScoreText:nil];
    
    karaokeView.lyricsView.firstToneHintViewStyle.size = 15;
    karaokeView.lyricsView.firstToneHintViewStyle.bottomMargin = 25;
    karaokeView.lyricsView.firstToneHintViewStyle.backgroundColor = [UIColor redColor];
    
    IncentiveView *incentiveView = [IncentiveView new];
    incentiveView.frame = karaokeView.scoringView.bounds;
    [self.view addSubview:incentiveView];
    
    [incentiveView showWithScore:80];
    
    lView.draggable = YES;
    lView.noLyricTipsFont = [UIFont systemFontOfSize:23];
    lView.noLyricTipsText = @"没有歌词呢";
    lView.noLyricTipsColor = [UIColor redColor];
//    [karaokeView setLyricDataWithData:nil];
}


- (void)onKaraokeViewWithView:(KaraokeView *)view didDragTo:(NSInteger)position {
    
}

- (void)onKaraokeViewWithView:(KaraokeView *)view
            didFinishLineWith:(LyricLineModel *)model
                        score:(NSInteger)score
              cumulativeScore:(NSInteger)cumulativeScore
                    lineIndex:(NSInteger)lineIndex lineCount:(NSInteger)lineCount {}

- (void)onLogWithContent:(NSString *)content tag:(NSString *)tag time:(NSString *)time level:(enum LoggerLevel)level {
    
}

@end
