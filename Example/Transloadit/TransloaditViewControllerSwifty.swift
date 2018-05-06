//
//  TransloaditViewController.swift
//  Transloadit
//
//  Created by Mark Masterson on 9/4/17.
//  Copyright © 2017 Mark R. Masterson. All rights reserved.
//

import UIKit
import Transloadit

class TransloaditViewControllerSwifty: UIViewController, UIPickerViewDelegate, UINavigationBarDelegate {
    
    let transloadit: Transloadit = Transloadit()
    
    var TestAssembly: Assembly?
    //var TestTemplate: Template
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //-----------------------------------------------------
        // MARK: Assembly Setup
        //-----------------------------------------------------
        let AssemblyStepsArray: NSMutableArray = NSMutableArray()
        let Step1 = Step (key: "encode")
        Step1?.setValue("/image/resize", forOption: "robot")
        Step1?.setValue("75", forOption: "width")
        Step1?.setValue("75", forOption: "height")
        AssemblyStepsArray.add(Step1)

        TestAssembly = Assembly(steps: AssemblyStepsArray, andNumberOfFiles: 1)

        let path = Bundle.main.path(forResource: "test", ofType: "jpg")
        TestAssembly?.addFile(URL(fileURLWithPath: path!), andFileName: "testFile.jpg")
        
        self.transloadit.createAssembly(TestAssembly!)
        
        self.transloadit.assemblyCreationResultBlock = { assembly, completionDictionary in
            self.transloadit.invokeAssembly(assembly)
        }
        self.transloadit.assemblyCreationFailureBlock = { completionDictionary in
            
        }

        self.transloadit.assemblyResultBlock = { completionDictionary in
            
        }
        self.transloadit.assemblyStatusBlock = { completionDictionary in
        }
        
        self.transloadit.assemblyFailureBlock = { completionDictionary in
            
        }

        self.transloadit.uploadResultBlock = { url in
            
        }
        self.transloadit.uploadProgressBlock =  {bytesWritten, bytesTotal in
            
        }
        self.transloadit.uploadFailureBlock = { error in
            
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {

    }
    
    func upload() {
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destinationViewController.
     // Pass the selected object to the new view controller.
     }
     */
    
}


