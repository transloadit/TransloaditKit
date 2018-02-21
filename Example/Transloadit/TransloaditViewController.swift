//
//  TransloaditViewController.swift
//  Transloadit
//
//  Created by Mark Masterson on 9/4/17.
//  Copyright © 2017 Mark R. Masterson. All rights reserved.
//

import UIKit
import TransloaditKit

class TransloaditViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        var TL:Transloadit = Transloadit()
        var AssemblySteps: Array = Array<Step>()
        var Step1 = Step (key: "endcode")
        Step1?.setValue("/image/resize", forOption: "robot")
        var TestAssembly: Assembly = Assembly(steps: AssemblySteps as! NSMutableArray, andNumberOfFiles: 1)
        //TestAssembly.addFile(<#URL!#>)
        
        TL.createAssembly(TestAssembly)

        TL.assemblyCompletionBlock = {(_ completionDictionary: [AnyHashable: Any]) -> Void in
            /*Invoking The Assebmly does NOT need to happen inside the completion block. However for sake of a small UI it is.
             We do however need to add the URL to the Assembly object so that we do invoke it, it knows where to go.
             */
//            TestAssemblyWithSteps.urlString = completionDictionary.value(forKey: "assembly_ssl_url")
//            transloadit.invokeAssembly(TestAssemblyWithSteps)
//            TL.checkAssembly(TestAssemblyWithSteps)
        }
        // Do any additional setup after loading the view.
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

