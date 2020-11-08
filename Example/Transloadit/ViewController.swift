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

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, TransloaditDelegate {
    func tranloaditUploadProgress() {
        //
    }
    
    func transloaditUploadFailureBlock() {
        //
    }
    
    func transloaditCreationResult(forObject: APIObject, withResult: TransloaditResponse) {
        //
        if (withResult.success) {
            print("We did it!")
        } else {
            print(withResult.error)

        }
    }
    
    func transloaditGetResult(forObject: APIObject, withResult: TransloaditResponse) {
        //
    }
    
    func transloaditDeletionResult(forObject: APIObject, withResult: TransloaditResponse) {
        //
    }
    
    func transloaditProcessResult() {
        //
    }
    
    
    func transloaditProcessProgress() {
        //
    }
    

    let imagePicker = UIImagePickerController()

    
    override func viewDidLoad() {
        super.viewDidLoad()
        imagePicker.sourceType = .photoLibrary
        imagePicker.delegate = self
        Transloadit.shared.delegate = self
        
        present(imagePicker, animated: true, completion: nil)

        // Do any additional setup after loading the view, typically from a nib.
    }
    
    //MARK: Picker Delegate
    
        
       
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {

            if #available(iOS 11.0, *) {
                guard let imageURL = info[.imageURL] else {
                    return
                }
                
                
                var newSteps: [String: Any] = [:]
                newSteps["robot"] = "/image/resize"
                newSteps["width"] = 75
                let assembly: Assembly = Transloadit.shared.newAssembly()
                
                assembly.addStep(name: "resize", options: newSteps)
                assembly.addFile(withPathURL: imageURL as! URL)
                assembly.save()
                
                
            }
            
            dismiss(animated: true) {
            }
        }
    //
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            dismiss(animated: true, completion: nil)
        }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

