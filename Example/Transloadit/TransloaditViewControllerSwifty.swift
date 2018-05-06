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
    var TestTemplate: Template?
    var TestAssembly: Assembly?
    let path = Bundle.main.path(forResource: "test", ofType: "jpg")
    let StepArray: NSMutableArray = NSMutableArray()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        //-----------------------------------------------------
        // MARK:  Setup Steps
        //-----------------------------------------------------
        let Step1 = Step (key: "encode")
        Step1?.setValue("/image/resize", forOption: "robot")
        Step1?.setValue("75", forOption: "width")
        Step1?.setValue("75", forOption: "height")
        StepArray.add(Step1)

        self.transloadit.assemblyCreationResultBlock = { assembly, completionDictionary in
            print("Assembly created!")
            print("Assembly invoking!")
            self.transloadit.invokeAssembly(assembly)
        }
        self.transloadit.assemblyCreationFailureBlock = { completionDictionary in
            print("Assembly creation failed")
        }

        self.transloadit.assemblyResultBlock = { completionDictionary in
            print("Assembly finished executing!")
        }
        self.transloadit.assemblyStatusBlock = { completionDictionary in
            print("Assembly is executing!")
        }
        
        self.transloadit.assemblyFailureBlock = { completionDictionary in
            print("Assembly failed executing!")
        }

        self.transloadit.uploadResultBlock = { url in
            print("file uploaded!")
        }
        self.transloadit.uploadProgressBlock =  {bytesWritten, bytesTotal in
            print("Assembly uploading!")
        }
        self.transloadit.uploadFailureBlock = { error in
            print("Assembly failed uploading!")
        }
        
        self.transloadit.templateCreationResultBlock = { template, completionDictionary in
            print("Template created!")
            print("Creating assembly with template!")
            let assemblyWithTemplate = Assembly(template: template, andNumberOfFiles: 1)
            assemblyWithTemplate?.addFile(URL(fileURLWithPath: self.path!), andFileName: "testFile.jpg")
            assemblyWithTemplate?.addStep(with: Step())
            self.transloadit.createAssembly(assemblyWithTemplate!)
        }
        
        self.transloadit.templateCreationFailureBlock = { completionDictionary in
            print("Template failed creating!")
        }
        
    }
    
    @IBAction func runAssembly(_ sender: Any) {
        //Assembly Setup
        self.TestAssembly = Assembly(steps: self.StepArray, andNumberOfFiles: 1)
        self.TestAssembly!.addFile(URL(fileURLWithPath: self.path!), andFileName: "testFile.jpg")
        self.transloadit.createAssembly(self.TestAssembly!)
    }
    
    @IBAction func runTemplate(_ sender: Any) {
        //Template Setup
        self.TestTemplate = Template(steps: self.StepArray, andName: "New Template2")
        self.transloadit.createTemplate(self.TestTemplate!)
    }
    
    override func viewDidAppear(_ animated: Bool) {

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
