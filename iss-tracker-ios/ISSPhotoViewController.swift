//
//  ISSPhotoViewController.swift
//  iss-tracker-ios
//
//  Created by Jevin Anderson on 5/10/15.
//  Copyright (c) 2015 jevinanderson. All rights reserved.
//

import UIKit
import ArcGIS

protocol ISSPhotoViewControllerProtocol {
    func viewImageAtNasa(url: String)
    func zoomToISSPhotoLocation(location: AGSPoint)
    func dismissISSPhotoViewController(iSSPhotoViewController :ISSPhotoViewController)
}

class ISSPhotoViewController: UIViewController {
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var cameraButton: UIButton!
    var delegate : ISSPhotoViewControllerProtocol?
    var location : AGSPoint!
    var imageUrl : NSURL!
    var image : UIImage!
    var dispatchQueue : dispatch_queue_t!
    var loaded : Bool = false
    
    private var feature : AGSFeature!
    
    func setFeature(feature :AGSFeature){
        self.feature = feature
        
        if let longitude = feature.attributeForKey("longitude") as? Double, let latitude = feature.attributeForKey("latitude") as? Double{
            
            self.location = AGSPoint(x: longitude, y: latitude, spatialReference: AGSSpatialReference.wgs84SpatialReference())
        }
        
        if let frame = feature.attributeForKey("frame") as? String, let roll = feature.attributeForKey("roll") as? String, let mission = feature.attributeForKey("mission") as? String, let missionRollFrame = feature.attributeForKey("missionRollFrame") as? String{
            let imageUrlString = "\(Constants.Urls.NASAImage)mission=\(mission)&roll=\(roll)&frame=\(frame)"
            self.imageUrl = NSURL(string: imageUrlString)
            
            if let embeddedImgUrl = NSURL(string:"\(Constants.Urls.embeddedImage)\(mission)/\(missionRollFrame).JPG"){
                self.loadImageAsynchronously(embeddedImgUrl)
            }
        }
    }
    
    func loadImageAsynchronously(imageUrl: NSURL!){
        if let queue = self.dispatchQueue ?? dispatch_get_main_queue(){
            dispatch_async(queue, { () -> Void in
                if let data = NSData(contentsOfURL: imageUrl){
                    if let image = UIImage(data: data){
                        dispatch_async(dispatch_get_main_queue(), { () -> Void in
                            self.image = image
                            if let imageView = self.imageView {
                                imageView.image = image
                            }
                        })
                    }
                }
            })
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let image = self.image{
            self.imageView.image = image
        }
        
        if var imageView = self.cameraButton.imageView{
            if var image = imageView.image {
                image = image.imageWithRenderingMode(.AlwaysTemplate)
                cameraButton.setImage(image, forState: .Normal)
                self.cameraButton.tintColor = UIColor(red: 0, green: 122.0/255.0, blue: 1, alpha: 1)
            }
        }
        
        self.loaded = true
    }
    
    @IBAction func viewImageAtNasa(sender: UIButton) {
        if let delegate = self.delegate {
            if let imageUrl = self.imageUrl{
                UIApplication.sharedApplication().openURL(imageUrl)
            }
        }
    }
    
    @IBAction func zoomToImage(sender: UIButton) {
        if let delegate = self.delegate {
            delegate.zoomToISSPhotoLocation(self.location)
        }
    }
    
    @IBAction func dismiss(sender: AnyObject) {
        if let delegate = self.delegate {
            delegate.dismissISSPhotoViewController(self)
        }
    }
    
    
}
