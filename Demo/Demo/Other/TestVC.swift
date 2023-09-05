//
//  TestVC.swift
//  Demo
//
//  Created by ZYP on 2023/9/5.
//

import UIKit
import AgoraLyricsScore

class TestVC: UIViewController {
    let k = KaraokeView(frame: .zero)
    override func viewDidLoad() {
        super.viewDidLoad()
//        test1()
//        test2()
//        test3()
//        test4()
        test5()
    }
    
    func test1() { /** yuping 唱全部歌词 **/
        // 计算累计分数，累计分数占据refPitch分数比例
        // refPitchLen:3990 userPitchLen:662
        // refPitchsNew:3892 userPitchsNew:640
        // refPitchsNew.filter > 0 -> 3387
        // all：3387 * 100/5 = 67740
        // 累计得分：15477 (max = 640 * 100 = 64000)
        // finaleScore:32.736267%
        // 总体：得分比较多，但是分不高。可能是跟音调补偿、agora_kge_score_finddelay、时间对不准有关
        
        let userPitchsName = "yp-1.txt"
        if let scoreRadio = calculatedScore(refPitchsName: "反方向的钟-原唱干声.pitch", userPitchsName: userPitchsName) {
            print("[\(userPitchsName)] 得分比：\(scoreRadio)")
        }
        else {
            print("[\(userPitchsName)] 得分比：-1")
        }
    }
    
    func test2() { /** like 唱全部歌词 **/
        let userPitchsName = "lk-1.txt"
        if let scoreRadio = calculatedScore(refPitchsName: "反方向的钟-原唱干声.pitch", userPitchsName: userPitchsName) {
            print("[\(userPitchsName)] 得分比：\(scoreRadio)")
        }
        else {
            print("[\(userPitchsName)] 得分比：-1")
        }
    }
    
    func test3() { /** like 唱全部歌词 **/
        let userPitchsName = "lk-2.txt"
        if let scoreRadio = calculatedScore(refPitchsName: "反方向的钟-原唱干声.pitch", userPitchsName: userPitchsName) {
            print("[\(userPitchsName)] 得分比：\(scoreRadio)")
        }
        else {
            print("[\(userPitchsName)] 得分比：-1")
        }
    }
    
    func test4() { /** like 唱全部歌词 好耳机 **/
        let userPitchsName = "lk-3.txt"
        if let scoreRadio = calculatedScore(refPitchsName: "反方向的钟-原唱干声.pitch", userPitchsName: userPitchsName) {
            print("[\(userPitchsName)] 得分比：\(scoreRadio)")
        }
        else {
            print("[\(userPitchsName)] 得分比：-1")
        }
    }
    
    func test5() { /** like 唱全部歌词 好耳机 **/
        // 计算累计分数，累计分数占据refPitch分数比例
        // refPitchLen:3990 userPitchLen:662
        // refPitchsNew:3892 userPitchsNew:640
        // refPitchsNew.filter > 0 -> 3387
        // all：3387 * 100/5 = 67740
        // 累计得分：15477 (max = 640 * 100 = 64000)
        // finaleScore:32.736267%
        // 总体：得分比较多，但是分不高。可能是跟音调补偿、agora_kge_score_finddelay、时间对不准有关
        let userPitchsName = "x.txt"
        if let scoreRadio = calculatedScore(refPitchsName: "反方向的钟-原唱干声.pitch", userPitchsName: userPitchsName) {
            print("[\(userPitchsName)] 得分比：\(scoreRadio)")
        }
        else {
            print("[\(userPitchsName)] 得分比：-1")
        }
    }
    
    func calculatedScore(refPitchsName: String,
                         userPitchsName: String,
                         refPitchInterval: Float = 10,
                         userPitchInterval: Float = 16) -> Float? {
        let refPitchUrl = URL(fileURLWithPath: Bundle.main.path(forResource: refPitchsName, ofType: nil)!)
        let refPitchData = try! Data(contentsOf: refPitchUrl)
        let refModel = KaraokeView.parsePitchData(data: refPitchData)!
        let refPitchs = refModel.items.map({ Float($0.value) })
        
//        let fileUrl = URL(fileURLWithPath: Bundle.main.path(forResource: userPitchsName, ofType: nil)!)
//        let fileData = try! Data(contentsOf: fileUrl)
//        let pitchFileString = String(data: fileData, encoding: .utf8)!
//        let userPitchs = parse(pitchFileString: pitchFileString).map({ Float($0) })
        
        let userPitchs: [Float] = [0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000,
                 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 151.920, 141.050, 145.430, 152.010, 155.870, 165.800, 170.850, 176.780, 171.470, 168.820, 169.250, 157.910, 151.250, 0.000, 0.000, 0.000, 177.850, 199.030, 216.710, 149.370, 155.980, 153.850, 153.850, 153.850, 153.850, 153.850, 153.850, 150.650,
                 136.460, 0.000, 0.000, 0.000, 0.000, 172.470, 184.900, 0.000, 0.000, 0.000, 0.000, 0.000, 119.060, 123.370, 125.000, 127.670, 128.420, 129.740, 130.060, 129.030, 129.030, 125.960, 122.490, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 120.830, 127.730, 118.360, 117.890, 121.410, 124.320, 119.470, 120.240, 115.180, 119.660, 118.940, 119.990, 125.260, 123.590, 114.430, 111.520, 117.220, 122.560, 113.690, 114.090, 119.930, 119.580, 117.160, 113.550, 111.510, 111.930, 117.580, 120.160, 111.350, 109.360, 111.110, 114.070, 115.410, 114.290, 114.290, 114.290, 114.290, 114.290, 114.290, 0.000, 0.000, 0.000, 126.570, 126.990, 129.030, 129.030, 129.030, 131.510, 130.380, 128.640, 129.030, 126.630, 125.260, 120.510, 0.000, 0.000, 131.240, 127.480, 0.000, 0.000, 0.000, 0.000, 95.250, 96.759, 94.196, 97.741, 100.250, 99.866, 100.410, 99.418, 102.700,
                 103.870, 102.560, 99.926, 100.360, 103.300, 103.280, 103.860, 103.040, 102.370, 102.560, 105.360, 107.800, 107.710, 106.180, 106.270, 105.770, 103.900, 105.260, 107.840, 111.130, 109.990, 109.690, 113.470, 115.890, 116.280, 116.970, 116.300, 117.410, 118.260, 116.190, 113.470, 114.990, 114.490, 113.340, 114.290, 114.290, 112.650, 112.920, 114.380, 112.880, 113.020, 111.350, 123.010, 118.690, 114.560, 117.060, 115.970, 113.370, 112.910, 114.290, 117.030, 115.590, 109.360, 0.000, 0.000, 0.000, 128.010, 119.250, 119.450, 121.210, 121.210, 121.210, 122.510, 125.380, 125.500, 126.400, 127.210, 124.830, 128.880, 127.000, 123.370, 123.570, 118.880, 119.960, 121.510, 121.210, 123.360, 125.430, 127.740, 136.470, 0.000, 0.000, 0.000, 260.690, 258.940, 266.670, 0.000, 132.310, 125.990, 122.350, 121.390, 119.820, 121.210, 121.210, 121.210, 119.460, 120.300, 128.520, 131.570, 128.800,
                 124.670, 119.880, 0.000, 0.000, 115.880, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 135.260, 0.000, 129.690, 120.930, 114.070, 0.000, 0.000, 198.500, 0.000, 0.000, 0.000, 193.600, 165.100, 148.910, 168.330, 169.330, 172.520, 176.560, 173.910, 170.130, 158.480, 159.610, 176.360, 0.000, 0.000, 0.000, 0.000, 149.200, 150.710, 147.680, 146.190, 148.150, 153.630, 156.440, 153.850, 151.260, 149.780, 148.430, 147.950, 142.320, 141.380, 136.190, 125.670, 121.050, 124.800, 119.220, 119.510, 124.990, 125.870, 128.540, 130.550, 130.430, 126.600, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 119.910, 114.360, 113.030, 114.290, 114.290, 103.330, 113.760, 120.270, 126.840, 128.830, 111.900, 111.640, 121.840, 113.360, 112.220, 114.470, 114.290, 111.520, 113.970, 118.610, 118.800, 119.780, 122.400, 123.100, 0.000,
                 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 123.310, 108.110, 106.800, 112.920, 109.690, 114.830, 115.640, 111.730, 120.860, 0.000, 111.900, 114.360, 110.320, 0.000, 0.000, 126.750, 0.000, 131.400, 124.710, 121.400, 124.190, 123.450, 120.410, 116.630, 111.140, 108.540, 105.510, 104.940, 101.020, 99.200, 97.287, 97.451, 99.836, 101.120, 102.270, 108.710, 114.920, 109.200, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 107.110, 104.200, 101.860, 100.340, 101.890, 106.250, 103.390, 100.350, 100.600, 100.740, 102.720, 102.870, 105.370, 103.490, 107.400, 104.720, 101.620, 102.060, 100.880, 99.831, 99.199, 101.380, 105.850, 104.730, 101.510, 108.920, 110.260, 117.550, 108.110, 98.757, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000,
                 184.460, 186.420, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 140.810, 151.450, 155.990, 163.530, 168.890, 169.030, 166.670, 161.090, 156.060, 160.000, 152.490, 157.550, 176.220, 151.550, 150.120, 147.080, 146.180, 148.150, 148.150, 148.150, 148.150, 148.150, 148.150, 148.150, 148.150, 148.150, 148.150, 156.210, 153.850, 145.260, 148.150, 148.150, 148.150, 150.230, 148.670, 146.460, 148.150, 142.180, 0.000, 0.000, 0.000, 0.000, 173.470, 184.510, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 112.280, 111.000, 113.260, 118.550, 119.090, 125.670, 128.970, 128.360, 130.520, 129.030, 119.030, 111.880, 128.480, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 115.870, 113.270, 115.940, 113.420, 113.480, 114.290, 114.290, 117.120, 115.450, 113.510, 114.290, 117.120,
                 115.020, 116.570, 114.880, 112.790, 117.520, 124.620, 137.450, 157.000, 0.000, 0.000, 0.000, 0.000, 118.320, 125.690, 125.660, 121.850, 113.970, 113.230, 112.730, 111.730, 109.010, 109.070, 111.520, 110.130, 106.960, 108.110, 108.110, 108.110, 111.840, 115.240, 115.380, 114.290, 114.290, 118.060, 117.160, 117.630, 120.460, 122.220, 122.180, 126.420, 121.270, 120.080, 123.330, 126.050, 125.910, 125.000, 125.000, 125.000, 125.000, 125.000, 125.000, 125.000, 125.000, 125.000, 118.660, 113.360, 117.650, 114.870, 102.630, 144.170, 114.010, 101.570, 94.569, 91.104, 91.319, 95.144, 95.908, 99.570, 101.580, 100.000, 0.000, 0.000, 0.000, 83.718, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 117.000, 110.400, 105.730, 109.580, 112.940, 113.240, 116.730, 114.290, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 127.460, 125.290,
                 125.850, 127.120, 122.270, 122.840, 126.370, 125.000, 125.000, 122.170, 118.670, 127.270, 136.640, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 155.230, 158.390, 147.960, 145.030, 152.990, 161.960, 161.530, 165.280, 169.470, 166.670, 166.670, 175.870, 176.410, 167.530, 153.050, 167.550, 172.790, 161.000, 158.550, 153.580, 151.650, 153.850, 153.850, 153.850, 153.850, 153.850, 153.850, 149.980, 145.190, 144.960, 141.390, 142.090, 142.860, 142.860, 132.240, 120.780, 121.890, 122.260, 119.560, 129.470, 131.640, 129.030, 121.290, 115.820, 120.150, 122.360, 110.540, 108.180, 111.110, 111.110, 111.110, 109.350, 110.070, 111.540, 112.550,
                 114.630, 114.530, 114.290, 114.290, 112.470, 112.130, 114.260, 114.060, 114.290, 111.360, 109.880, 111.110, 111.110, 114.360, 115.440, 114.290, 116.150, 114.290, 114.290, 117.650, 108.230, 127.960, 0.000, 0.000, 0.000, 0.000, 0.000, 119.430, 116.190, 121.380, 122.130, 121.210, 124.870, 126.660, 125.000, 125.000, 122.930, 117.700, 112.150, 112.230, 99.413, 0.000, 0.000, 0.000, 0.000, 0.000, 97.428, 101.450, 101.140, 101.450, 100.690, 99.159, 98.370, 98.177, 97.521, 98.376, 97.960, 97.722, 97.687, 98.613, 93.954, 87.722, 93.701, 101.890, 97.561, 99.791, 100.980, 101.480, 104.890, 102.200, 101.270, 99.328, 103.120, 96.235, 105.130, 103.290, 103.470, 106.160, 106.410, 118.730, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000,
                 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 372.270, 0.000, 0.000, 142.340, 149.270, 150.000, 155.340, 158.850, 161.600, 164.370, 167.590, 167.490, 166.670, 166.670, 166.670, 166.670, 163.060, 158.220, 158.190, 160.000, 156.090, 152.200, 146.860, 146.130, 148.150, 148.150, 148.150, 150.320, 149.190, 144.810, 144.880, 140.450, 126.820, 0.000, 0.000, 0.000, 0.000, 0.000, 127.350, 117.780, 118.110, 120.980, 119.250, 118.880, 124.940, 125.080, 128.170, 125.240, 123.820, 122.810, 116.890, 112.020, 110.060, 103.660, 100.810, 104.130, 100.340, 103.740, 103.300, 103.640, 111.000, 109.930, 110.850, 110.440, 112.540, 111.440, 110.420, 111.110, 112.710, 111.110, 112.440, 111.510, 103.660, 100.920, 107.970,
                 110.500, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 121.800, 116.910, 115.120, 114.810, 112.790, 114.290, 116.560, 117.260, 116.460, 117.150, 117.650, 0.000, 0.000, 0.000, 0.000, 0.000, 134.150, 124.160, 123.580, 121.770, 119.940, 121.210, 121.210, 121.210, 124.130, 119.160, 111.560, 106.610, 104.890, 106.700, 104.380, 101.100, 102.060, 100.800, 99.413, 100.410, 101.810, 100.120, 98.976, 101.340, 101.970, 101.930, 103.120, 100.660, 102.060, 103.390, 102.560, 102.560, 99.869, 99.750, 100.140, 102.240, 103.680, 101.690, 101.480, 103.950, 99.558, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 117.340, 109.250, 113.360, 111.930, 108.730, 109.330, 110.050, 107.590, 119.410, 106.330, 113.080, 112.300, 111.110, 111.110, 115.300, 115.020, 114.290, 112.600, 114.290, 112.010, 116.960, 106.410, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000,
                 120.300, 123.750, 125.000, 122.820, 120.190, 124.680, 124.340, 124.790, 120.950, 116.770, 0.000, 0.000, 0.000, 122.400, 0.000, 0.000, 124.910, 131.790, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 127.660, 133.540, 148.180, 162.780, 166.100, 171.170, 167.920, 159.940, 162.510, 168.410, 168.410, 166.670, 166.670, 166.670, 166.670, 0.000, 169.730, 149.670, 143.950, 148.150, 148.150, 148.150, 148.150, 148.150, 143.830, 146.930, 0.000, 140.390, 147.600, 156.540, 0.000, 0.000, 0.000, 0.000, 125.900, 125.030, 124.940, 123.380, 125.000, 125.000, 125.000, 125.000, 125.000, 125.000, 125.000, 125.000, 115.780, 126.420, 137.170, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 120.500, 114.970, 114.180, 111.180, 106.600, 109.130, 112.120, 111.110, 111.110, 106.210, 103.210,
                 109.330, 110.180, 109.600, 108.300, 105.880, 109.100, 109.310, 108.110, 108.110, 90.001, 0.000, 0.000, 0.000, 182.030, 165.330, 126.330, 112.780, 111.520, 113.510, 114.290, 114.290, 114.290, 114.290, 113.130, 110.610, 109.540, 111.110, 115.240, 113.590, 110.360, 110.230, 111.110, 112.950, 118.990, 114.760, 122.710, 116.470, 115.380, 117.950, 115.620, 116.890, 118.020, 119.630, 122.210, 122.070, 121.210, 126.190, 126.390, 125.000, 121.340, 121.080, 120.580, 116.490, 116.890, 114.050, 124.270, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 85.388, 0.000, 0.000, 106.610, 98.523, 98.346, 98.500, 99.738, 102.270, 104.640, 109.170, 101.980, 94.306, 86.010, 90.338, 0.000, 94.285, 0.000, 0.000, 116.240, 112.970, 113.010, 113.640, 110.310, 110.390, 111.110, 108.770, 110.880, 105.940, 106.750, 106.100, 107.410, 108.370, 106.400,
                 107.310, 111.220, 115.460, 107.910, 104.310, 104.270, 112.170, 109.180, 104.140, 104.180, 106.260, 117.230, 105.570, 113.240, 122.730, 119.060, 117.650, 117.650, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 222.220, 203.750, 200.820, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000,
                 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 203.810, 210.530, 206.120, 179.110, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000,
                 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000]
        
        let refPitchLen = refPitchs.count
        let userPitchLen: Int = userPitchs.count
        
        let config = ScoreClaculator.Config(refPitchLen: refPitchLen,
                                            refPitchInterval: refPitchInterval,
                                            userPitchLen: userPitchLen,
                                            userPitchInterval: userPitchInterval)
        return ScoreClaculator.calculate(config: config,
                                         refPitchs: refPitchs,
                                         userPitchs: userPitchs)
        
    }

    private func parse(pitchFileString: String) -> [Double] {
        if pitchFileString.contains("\r\n") {
            let array = pitchFileString.split(separator: "\r\n").map({ Double($0)! })
            return array
        }
        else {
            let array = pitchFileString.split(separator: "\n").map({ Double($0)! })
            return array
        }
    }
    
}