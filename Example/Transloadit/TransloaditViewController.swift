//
//  TransloaditViewController.swift
//  Transloadit
//
//  Created by Mark Masterson on 9/4/17.
//  Copyright © 2017 Mark R. Masterson. All rights reserved.
//

import UIKit
import Photos
import Transloadit

class TransloaditViewController: UIViewController, UIPickerViewDelegate, UINavigationBarDelegate {
    
    let transloadit: Transloadit = Transloadit()
    let imagePicker: UIImagePickerController = UIImagePickerController()
    
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
        TestAssembly = Assembly(steps: AssemblyStepsArray, andNumberOfFiles: 1)
        
        
        let TestTemplate: Template = Template()
        // Do any additional setup after loading the view.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        self.selectFile("")
    }
    
    @IBAction func selectFile(_ sender: Any) {
        
        let status: PHAuthorizationStatus = PHPhotoLibrary.authorizationStatus()
        switch status {
        case .authorized:
            self.present(imagePicker, animated: true, completion: nil)
            break
        default:
            PHPhotoLibrary.requestAuthorization({
                (newStatus) in
                print("status is \(newStatus)")
                if newStatus ==  PHAuthorizationStatus.authorized {
                    /* do stuff here */
                    print("success")
                }
            })
            break
        }
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


