//
//  Assembly.swift
//  Pods
//
//  Created by Mark Robert Masterson on 11/17/19.
//

import UIKit

class Assembly: APIObject {

    var steps: Array<AssemblyStep>?
    var numberOfFiles: Int?
    
    convenience init(withSteps steps: Array<AssemblyStep>, andNumberOfFiles numOfFiles: Int) {
        self.init()
        self.steps = steps
        self.numberOfFiles = numOfFiles
    }
    
}
