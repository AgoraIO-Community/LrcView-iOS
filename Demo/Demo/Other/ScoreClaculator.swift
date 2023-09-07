//
//  PitchFindDelayWapper.swift
//  Demo
//
//  Created by ZYP on 2023/9/2.
//

import Foundation
import CommonCrypto

class ScoreClaculator {
    
    typealias CompleteBlock = (_ score: Float?, _ error: Error?) -> ()
    
    static func recognize(byfile name: String, title: String, completedHandler: @escaping CompleteBlock) {
        let url = URL(fileURLWithPath: Bundle.main.path(forResource: name, ofType: nil)!)
        let data = try! Data(contentsOf: url)
        
        recognize(byData: data, title: title, completedHandler: completedHandler)
    }
    
    static func recognize(byData wavData: Data,
                          title: String,
                          completedHandler: @escaping CompleteBlock) {
        let host = Config.host
        let path = "/v1/identify"
        
        let dataType = "audio"
        let signatureVersion: UInt8 = 1
        
        let httpMethod = "POST"
        let timeStamp = Date().timeIntervalSince1970 * 1000
        let sample_bytes = wavData.count
        
        let signature = sign(httpMethod: httpMethod,
                             httpUri: path,
                             accessKey: Config.accessKey,
                             access_secret: Config.access_secret,
                             dataType: dataType,
                             signatureVersion: signatureVersion,
                             timeStamp: timeStamp)
        
        let url = URL(string: "https://\(host)\(path)")!
        var request = URLRequest(url: url)
        request.httpMethod = httpMethod
        
        let parameters: [String: Any] = [
            "access_key": Config.accessKey,
            "sample_bytes": sample_bytes,
            "timestamp": timeStamp,
            "data_type": dataType,
            "signature_version": signatureVersion,
            "signature": signature,
            "title": title
        ]
        
        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        let httpBody = createBody(parameters: parameters, boundary: boundary, data: wavData, mimeType: "audio/mpeg", filename: "test.wav")
        request.httpBody = httpBody
        let session = URLSession.shared
        let task = session.dataTask(with: request) { data, resp, error in
            if let err = error {
                completedHandler(nil, err)
                return
            }
            if let resp = resp as? HTTPURLResponse,
                resp.statusCode == 200,
                let data = data {
                let string = String(data: data, encoding: .utf8)!
                print(string)
                
                let decoder = JSONDecoder()
                let respone = try! decoder.decode(Respone.self, from: data)
                
                guard respone.status.code == 0 else {
                    let e = ARCError(code: respone.status.code)
                    completedHandler(nil, e)
                    return
                }
                
                if !respone.metadata!.humming.isEmpty {
                    completedHandler(respone.metadata!.humming.first!.score, nil)
                }
            }
            
        }
        task.resume()
    }
    
    static func createBody(parameters: [String: Any],
                           boundary: String,
                           data: Data,
                           mimeType: String,
                           filename: String) -> Data {
            var body = Data()
            let boundaryPrefix = "--\(boundary)\r\n"
            
            for (key, value) in parameters {
                body.append(string: boundaryPrefix)
                body.append(string: "Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n")
                body.append(string: "\(value)\r\n")
            }
            
            body.append(string: boundaryPrefix)
            body.append(string: "Content-Disposition: form-data; name=\"sample\"; filename=\"\(filename)\"\r\n")
            body.append(string: "Content-Type: \(mimeType)\r\n\r\n")
            body.append(data)
            body.append(string: "\r\n")
            body.append(string: "--".appending(boundary.appending("--")))
            
            return body
        }
    
    static func sign(httpMethod: String,
                     httpUri: String,
                     accessKey: String,
                     access_secret: String,
                     dataType: String,
                     signatureVersion: UInt8,
                     timeStamp: TimeInterval) -> String {
        let stringToSign = httpMethod + "\n" + httpUri + "\n" + accessKey + "\n" + dataType + "\n" + "\(signatureVersion)" + "\n" + String(timeStamp)
        let signDatas = stringToSign.hmac(by: .SHA1, key: access_secret.bytes)
        let sign = signDatas.base64
        return sign
    }
    
    static func convertPCMToWAV(pcmData: Data) -> Data {
        let headerSize = 44
        let totalAudioLen = pcmData.count
        let totalDataLen = totalAudioLen + headerSize - 8
        let longSampleRate = 16000
        let channels = 1
        let byteRate = 32 * longSampleRate * channels / 8
        
        var header = Data()
        header.append(contentsOf: [UInt8]("RIFF".utf8)) // RIFF chunk identifier
        header.append(contentsOf: withUnsafeBytes(of: UInt32(totalDataLen).littleEndian) { Data($0) }) // RIFF chunk size
        header.append(contentsOf: [UInt8]("WAVE".utf8)) // RIFF format
        header.append(contentsOf: [UInt8]("fmt ".utf8)) // fmt subchunk identifier
        header.append(contentsOf: withUnsafeBytes(of: UInt32(16).littleEndian) { Data($0) }) // fmt subchunk size (16 for PCM)
        header.append(contentsOf: withUnsafeBytes(of: UInt16(1).littleEndian) { Data($0) }) // audio format (1 for PCM)
        header.append(contentsOf: withUnsafeBytes(of: UInt16(channels).littleEndian) { Data($0) }) // number of channels
        header.append(contentsOf: withUnsafeBytes(of: UInt32(longSampleRate).littleEndian) { Data($0) }) // sample rate
        header.append(contentsOf: withUnsafeBytes(of: UInt32(byteRate).littleEndian) { Data($0) }) // byte rate
        header.append(contentsOf: withUnsafeBytes(of: UInt16(channels * 16 / 8).littleEndian) { Data($0) }) // block align
        header.append(contentsOf: withUnsafeBytes(of: UInt16(16).littleEndian) { Data($0) }) // bits per sample
        header.append(contentsOf: [UInt8]("data".utf8)) // data subchunk identifier
        header.append(contentsOf: withUnsafeBytes(of: UInt32(totalAudioLen).littleEndian) { Data($0) }) // data subchunk size
        var wavData = header
        wavData.append(pcmData)
        return wavData
    }
}


extension String {
    func hmac(by algorithm: Algorithm, key: [UInt8]) -> [UInt8] {
        let count = Int(algorithm.digestLength())
        var result = [UInt8](repeating: 0, count: count)
        CCHmac(algorithm.algorithm(), key, key.count, self.bytes, self.bytes.count, &result)
        return result
    }
    
    var bytes: [UInt8] {
        return [UInt8](self.utf8)
    }
}

enum Algorithm {
    case MD5, SHA1, SHA224, SHA256, SHA384, SHA512
    
    func algorithm() -> CCHmacAlgorithm {
        var result: Int = 0
        switch self {
        case .MD5:    result = kCCHmacAlgMD5
        case .SHA1:   result = kCCHmacAlgSHA1
        case .SHA224: result = kCCHmacAlgSHA224
        case .SHA256: result = kCCHmacAlgSHA256
        case .SHA384: result = kCCHmacAlgSHA384
        case .SHA512: result = kCCHmacAlgSHA512
        }
        return CCHmacAlgorithm(result)
    }
    
    func digestLength() -> Int {
        var result: CInt = 0
        switch self {
        case .MD5:
            result = CC_MD5_DIGEST_LENGTH
        case .SHA1:
            result = CC_SHA1_DIGEST_LENGTH
        case .SHA224:
            result = CC_SHA224_DIGEST_LENGTH
        case .SHA256:
            result = CC_SHA256_DIGEST_LENGTH
        case .SHA384:
            result = CC_SHA384_DIGEST_LENGTH
        case .SHA512:
            result = CC_SHA512_DIGEST_LENGTH
        }
        return Int(result)
    }
}

extension String {
    var base64Encoded: String {
        return self.data(using: .utf8)!.base64EncodedString()
    }
}

extension Array where Element == UInt8 {
    var base64: String {
        let data = Data(self)
        return data.base64EncodedString()
    }
}

extension Data {
    mutating func append(string: String) {
        if let data = string.data(using: .utf8) {
            append(data)
        }
    }
}

extension URLRequest {

    var curlString: String {
        guard let url = url else { return "" }
        var baseCommand = "curl \(url.absoluteString)"
        
        if let httpMethod = httpMethod, httpMethod != "GET" {
            baseCommand += " -X \(httpMethod)"
        }
        
        allHTTPHeaderFields?.forEach { key, value in
            baseCommand += " -H '\(key): \(value)'"
        }
        
        if let httpBody = httpBody, let bodyString = String(data: httpBody, encoding: .utf8) {
            var escapedBody = bodyString.replacingOccurrences(of: "\\\"", with: "\\\\\\\"")
            escapedBody = escapedBody.replacingOccurrences(of: "\"", with: "\\\"")
            
            baseCommand += " -d \"\(escapedBody)\""
        }
        
        return baseCommand
    }
}

extension ScoreClaculator {
    struct Status: Codable {
        let msg: String
        let version: String
        let code: Int
    }
    
    struct Humming: Codable {
        let play_offset_ms: Int
        let duration_ms: Int
        let title: String
        let score: Float
    }
    
    struct Metadata: Codable {
        let humming: [Humming]
    }
    
    struct Respone: Codable {
        let cost_time: Double?
        let status: Status
        let metadata: Metadata?
    }
    
    struct ARCError: Error, LocalizedError {
        let code: Int
        
        var errorDescription: String? {
            return "ARCError \(code)"
        }
    }
}
