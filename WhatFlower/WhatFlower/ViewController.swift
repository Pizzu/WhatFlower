//
//  ViewController.swift
//  WhatFlower
//
//  Created by Luca Lo Forte on 04/04/18.
//  Copyright © 2018 Luca Lo Forte. All rights reserved.
//

import UIKit
import Vision
import CoreML
import Alamofire
import SwiftyJSON
import SDWebImage

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    let imagePicker = UIImagePickerController()
    @IBOutlet weak var extractLabel: UILabel!
    @IBOutlet weak var flowerImageView: UIImageView!
    
    
    let API_URL = "https://en.wikipedia.org/w/api.php"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        imagePicker.delegate = self
        imagePicker.sourceType = .photoLibrary
        imagePicker.allowsEditing = true
        
    }
    
    //MARK: - ImagePickerController delegate method
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        if let userPickedImage = info[UIImagePickerControllerEditedImage] as? UIImage {
            
            guard let ciImage = CIImage(image: userPickedImage) else {fatalError("Could not convert image to CIImage")}
            
            detect(flowerImage: ciImage)
            
        }
        imagePicker.dismiss(animated: true, completion: nil)
    }
    
    //MARK: - Detect flower image
    
    func detect(flowerImage: CIImage){
        
            guard let model = try? VNCoreMLModel(for: FlowerClassifier().model) else {fatalError("Loading CoreML model failed.")}
        
            let request = VNCoreMLRequest(model: model) { (request, error) in
                
                guard let results = request.results as? [VNClassificationObservation] else { fatalError("Model failed to process image.")}
            
                if let firstResult = results.first {
                    let flowerName = firstResult.identifier
                    self.navigationItem.title = firstResult.identifier.capitalized
                    print(Float(firstResult.confidence))
                    let parameters : [String : String] = [
                        "format" : "json",
                        "action" : "query",
                        "prop" : "extracts|pageimages",
                        "exintro" : "",
                        "explaintext" : "",
                        "titles" : flowerName,
                        "indexpageids" : "",
                        "redirects" : "1",
                        "pithumbsize": "500"
                    ]
                    
                    self.makeQueryToWikiAPI(parameters: parameters)
                    
                }
            }
            
            let handler = VNImageRequestHandler(ciImage: flowerImage)
            
            do{
                try handler.perform([request])
            } catch {
                print(error)
            }

    }
    
    //MARK: - Make the request to Wikipedia API
    
    func makeQueryToWikiAPI(parameters : [String : String]){
        Alamofire.request(API_URL, method: .get, parameters: parameters).responseJSON { (response) in
            if response.result.isSuccess {
                print("Success ! Got the response")
                
                let responseJSON : JSON = JSON(response.result.value!)
                print(responseJSON)
                self.getWikiData(flowerData : responseJSON)
                
            } else {
                print("Error \(String(describing: response.result.error))")
                
            }
        }
    }
    
    //MARK: - Get the data from Wikipedia API with SwiftyJSON
    func getWikiData(flowerData : JSON) {
        
        if let pageId = flowerData["query"]["pageids"][0].string {
            
            let extract = flowerData["query"]["pages"][pageId]["extract"].stringValue
            let flowerImageURL = flowerData["query"]["pages"][pageId]["thumbnail"]["source"].stringValue
            
            flowerImageView.sd_setImage(with: URL(string: flowerImageURL), completed: nil)
            
            extractLabel.text = extract
            
        } else {
            print("Error")
        }
    }

    //MARK: - Present imagePickerController
    
    @IBAction func takePhotoButton(_ sender: UIBarButtonItem) {
        present(imagePicker, animated: true, completion: nil)
    }
    

}

