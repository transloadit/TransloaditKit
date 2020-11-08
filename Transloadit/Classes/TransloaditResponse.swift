//
//  TransloaditResponse.swift
//  Pods
//
//  Created by Mark Robert Masterson on 11/17/19.
//

import UIKit

public class TransloaditResponse: Codable {
    public var success: Bool = true
    public var tusURL: String = ""
    public var assemblyURL: String = ""
    public var statusCode: Int = 0
    public var error: String = ""
    public var processing: Bool = false

}
