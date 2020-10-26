//
//  String+HMAC.swift
//  TUSKit
//
//  Created by Mark Robert Masterson on 10/25/20.
//

import Foundation
import CommonCrypto

internal extension String {

    func hmac(key: String) -> String {
        var digest = [UInt8](repeating: 0, count: Int(CC_SHA1_DIGEST_LENGTH))
        CCHmac(CCHmacAlgorithm(kCCHmacAlgSHA1), key, key.count, self, self.count, &digest)
        let data = Data(bytes: digest)
        return data.map { String(format: "%02hhx", $0) }.joined()
    }

}
