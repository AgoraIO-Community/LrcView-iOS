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
    
    KaraokeView *karaokeView = [[KaraokeView alloc] initWithFrame:CGRectZero loggers:@[[ConsoleLogger new], [FileLogger new]]];
    karaokeView.backgroundImage = [UIImage imageNamed:@"ktv_top_bgIcon"];
    karaokeView.spacing = 5;
    karaokeView.scoringEnabled = YES;
    karaokeView.frame = CGRectMake(0, 100, self.view.bounds.size.width, 380);
    [self.view addSubview:karaokeView];
    karaokeView.delegate = self;
    
    ScoringView *sView = karaokeView.scoringView;
    LyricsView *lView= karaokeView.lyricsView;
    sView.viewHeight = 160;
    sView.topMargin = 70;
    
    GradeView *gview = [[GradeView alloc] initWithFrame:CGRectMake(15, 110, UIScreen.mainScreen.bounds.size.width - 30, 50)];
    [gview setTitleWithTitle:@"123"];

    [self.view addSubview:gview];
    [self.view layoutIfNeeded];
    [gview setScoreWithCumulativeScore:1110 totalScore:4000];
    
    karaokeView.lyricsView.firstToneHintViewStyle.size = 15;
    karaokeView.lyricsView.firstToneHintViewStyle.topMargin = 25;
    karaokeView.lyricsView.firstToneHintViewStyle.backgroundColor = [UIColor redColor];
    
    IncentiveView *incentiveView = [IncentiveView new];
    incentiveView.frame = karaokeView.scoringView.bounds;
    [self.view addSubview:incentiveView];
    
    [incentiveView showWithScore:80];
    
    lView.draggable = YES;
    lView.noLyricsTipFont = [UIFont systemFontOfSize:23];
    lView.noLyricsTipText = @"没有歌词呢";
    lView.noLyricsTipColor = [UIColor redColor];
//    [karaokeView setLyricDataWithData:nil];
}


- (void)onKaraokeViewWithView:(KaraokeView *)view didDragTo:(NSInteger)position {
    
}

- (void)onKaraokeViewWithView:(KaraokeView *)view
            didFinishLineWith:(LyricLineModel *)model
                        score:(NSInteger)score
              cumulativeScore:(NSInteger)cumulativeScore
                    lineIndex:(NSInteger)lineIndex lineCount:(NSInteger)lineCount {}
/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (void)onLogWithContent:(NSString *)content tag:(NSString *)tag time:(NSString *)time level:(enum LoggerLevel)level {
    
}



@end
