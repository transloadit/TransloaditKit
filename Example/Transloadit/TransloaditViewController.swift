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
    
    @objc func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        //-----------------------------------------------------
        // MARK: Picker
        //-----------------------------------------------------
        // !! NOTE !!
        // This is boilerplate imagepicker code. You do NOT need this for Transloadit.
        // This is strictly for the Example, and grabbing an image.
        
        self.dismiss(animated: true, completion: nil);
        let assetURL: URL = info[UIImagePickerControllerReferenceURL] as! URL
        let result: PHFetchResult = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .smartAlbumUserLibrary, options: nil)
        var assetCollection: PHAssetCollection = result.firstObject!
        let fetchResult: PHFetchResult = PHAsset.fetchAssets(withALAssetURLs: [assetURL], options: nil)
        let asset: PHAsset = fetchResult.firstObject!
        let photoManager: PHImageManager = PHImageManager()
        photoManager.requestImageData(for: asset, options: nil) { (imageData, dataUTI, orientation, info) in
            let documentDir: URL = FileManager.default.urls(for: FileManager.SearchPathDirectory.documentDirectory, in: FileManager.SearchPathDomainMask.allDomainsMask)[0]
            let fileURL: URL = documentDir.appendingPathComponent(UUID.init().uuidString)
            
            if ((try! imageData?.write(to: fileURL)) != nil) {
                //-----------------------------------------------------
                // MARK: Creating an Assembly
                //-----------------------------------------------------
                self.TestAssembly?.addFile(fileURL)
                self.transloadit.createAssembly(self.TestAssembly!)
                
                //-----------------------------------------------------
                // MARK: Blocks
                //-----------------------------------------------------
                self.transloadit.assemblyCompletionBlock = {(_ completionDictionary: [AnyHashable: Any]) -> Void in
                    /*Invoking The Assebmly does NOT need to happen inside the completion block. However for sake of a small UI it is.
                     We do however need to add the URL to the Assembly object so that we do invoke it, it knows where to go.
                     */
                    self.TestAssembly?.urlString = completionDictionary["assembly_ssl_url"] as! String
                    self.transloadit.invokeAssembly(self.TestAssembly!)
                    self.transloadit.check(self.TestAssembly!)
                }
            }
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


