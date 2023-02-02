//
//  OCVC.m
//  Demo
//
//  Created by ZYP on 2023/2/2.
//

#import "OCVC.h"
@import AgoraLyricsScore;

@interface OCVC ()

@end

@implementation OCVC

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor blueColor];
    GradeView *gview = [[GradeView alloc] initWithFrame:CGRectMake(15, 300, UIScreen.mainScreen.bounds.size.width - 30, 50)];
    [gview setTitleWithTitle:@"123"];
    
    [self.view addSubview:gview];
    [self.view layoutIfNeeded];
    [gview setup];
    NSLog(@"");
    [gview setScoreWithCumulativeScore:0 totalScore:4000];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
