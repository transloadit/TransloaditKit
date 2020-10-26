//
//  ViewController.swift
//  Transloadit
//
//  Created by mmasterson on 11/13/2019.
//  Copyright (c) 2019 mmasterson. All rights reserved.
//

import UIKit
import Transloadit
import TUSKit

class ViewController: UIViewController {

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Transloadit.shared.delegate = self
        
        var newSteps: [String: Any] = [:]
        newSteps["robot"] = "/image/resize"
        newSteps["width"] = 75
        let assembly: Assembly = Transloadit.shared.newAssembly()
        
        assembly.addStep(name: "resize", options: newSteps)
        assembly.addFile(withPathURL: URL(string: "http://google.com")!)
        assembly.save()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

