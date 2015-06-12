//
//  ViewController.swift
//  iss-tracker-ios
//
//  Created by Jevin Anderson on 4/9/15.
//  Copyright (c) 2015 jevinanderson. All rights reserved.
//

import UIKit
import ArcGIS

class ViewController: UIViewController, AGSLayerDelegate, AGSMapViewLayerDelegate, AGSMapViewTouchDelegate, AGSQueryTaskDelegate, ISSPhotoViewControllerProtocol, UIPageViewControllerDataSource, UIPageViewControllerDelegate {
    var photosFeatureLayer : AGSFeatureLayer!
    var graphicsLayer : AGSGraphicsLayer!
    var spaceStationGraphicsLayer : AGSGraphicsLayer!
    var spaceStationGraphic : AGSGraphic!
    var spaceStationMarkerSymbol : AGSPictureMarkerSymbol!
    var oldPoint : AGSPoint!
    var queryTask : AGSQueryTask!
    var issPhotoViewControllers: NSMutableArray!
    let imageDispatchQueue = dispatch_queue_create("com.JevinAnderson.ImageDispatchQueue", DISPATCH_QUEUE_CONCURRENT)
    
    @IBOutlet var mapView: AGSMapView!
    @IBOutlet weak var animationView: UIView!
    @IBOutlet weak var trackStationSwitch: UISwitch!
    @IBOutlet weak var menuButton: UIButton!
    @IBOutlet weak var menu: UIView!
    var basemap : AGSTiledMapServiceLayer!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.mapView.layerDelegate = self
        self.mapView.touchDelegate = self
        
        self.addTiledBasemapToMap()
        
        self.mapView.locationDisplay.startDataSource()
        self.mapView.locationDisplay.autoPanMode = .Default
    }
    
    func addTiledBasemapToMap(){
        var url = NSURL(string: Constants.Urls.WorldImageryBasemap)
        var basemap = AGSTiledMapServiceLayer(URL: url)
        basemap.delegate = self
        self.mapView.addMapLayer(basemap)
        self.basemap = basemap
    }
    
    func layer(layer: AGSLayer!, didFailToLoadWithError error: NSError!) {
        println("Layer(\(layer)) failed to load with error: \(error)")
    }
    
    func mapViewDidLoad(mapView: AGSMapView!) {
        mapView.minScale = 250000000.0;
        mapView.enableWrapAround()
        mapView.zoomToScale(2000000.0, animated: true)
        
        self.photosFeatureLayer = AGSFeatureLayer(URL: NSURL(string: Constants.Urls.PhotosLayer), mode: .OnDemand)
        self.photosFeatureLayer.delegate = self
        self.mapView.addMapLayer(self.photosFeatureLayer)
        
        self.graphicsLayer = AGSGraphicsLayer()
        self.graphicsLayer.renderer = AGSSimpleRenderer(symbol: AGSSimpleMarkerSymbol(color: UIColor.blueColor()))
        self.mapView.addMapLayer(self.graphicsLayer)
        
        self.spaceStationGraphicsLayer = AGSGraphicsLayer()
        self.mapView.addMapLayer(self.spaceStationGraphicsLayer)
        
        self.getIssLocation()
    }
    
    func getIssLocation(){
        var request : NSMutableURLRequest = NSMutableURLRequest()
        request.URL = NSURL(string: Constants.Urls.IssLocation)
        request.HTTPMethod = "GET"
        
        NSURLConnection.sendAsynchronousRequest(request, queue: NSOperationQueue(), completionHandler:{ (response:NSURLResponse!, data: NSData!, error: NSError!) -> Void in
            var error: AutoreleasingUnsafeMutablePointer<NSError?> = nil
            let jsonResult: NSDictionary! = NSJSONSerialization.JSONObjectWithData(data, options:NSJSONReadingOptions.MutableContainers, error: error) as? NSDictionary
            
            //Parsing JSON in swift is dumb
            if (jsonResult != nil) {
                self.updateIssGraphics(jsonResult)
            } else {
                println("Error: \(error)")
            }
            
            self.delay(2.0, closure: { () -> () in
                self.getIssLocation()
            })
        })
    }
    
    func updateIssGraphics(jsonResult: NSDictionary!){
        if let issPosition = jsonResult["iss_position"] as? NSDictionary {
            if let latitude = issPosition["latitude"] as? Double ,longitude = issPosition["longitude"] as? Double {
                let unconvertedPoint = AGSPoint(x: longitude, y: latitude, spatialReference: AGSSpatialReference.wgs84SpatialReference())
                let point = AGSGeometryEngine.defaultGeometryEngine().projectGeometry(unconvertedPoint, toSpatialReference: self.mapView.spatialReference) as? AGSPoint
                
                let graphic = AGSGraphic(geometry: point, symbol: nil, attributes: nil)
                self.graphicsLayer.addGraphic(graphic)
                
                if self.trackStationSwitch.on == true{
                    self.mapView.centerAtPoint(point, animated: false)
                }
                
                if self.spaceStationGraphic != nil {
                    let bearing = calculateBearing(oldPoint, newPoint: unconvertedPoint!)
                    self.spaceStationGraphic.geometry = point
                    spaceStationMarkerSymbol.angle = bearing
                }else{
                    if let path = NSBundle.mainBundle().pathForResource("rocket2", ofType: ".png"), image = UIImage(contentsOfFile: path) {
                        self.spaceStationMarkerSymbol = AGSPictureMarkerSymbol(image: image)
                        self.spaceStationMarkerSymbol.size = CGSize(width: 29.0, height: 50.0)
                        
                        self.spaceStationGraphic = AGSGraphic(geometry: point, symbol: self.spaceStationMarkerSymbol, attributes: nil)
                        self.spaceStationGraphicsLayer.addGraphic(self.spaceStationGraphic)
                    }
                    
                }
                oldPoint = unconvertedPoint
            }
        }
    }
    
    //http://stackoverflow.com/questions/3809337/calculating-bearing-between-two-cllocationcoordinate2ds
    
    func degreesToRadians(degrees: Double) -> Double {
        return degrees * M_PI / 180.0
    }
    
    func radiansToDegrees(radians: Double) -> Double {
        return radians * 180.0 / M_PI
    }
    
    func calculateBearing(oldPoint: AGSPoint, newPoint: AGSPoint) -> Double {
        let oldLat = degreesToRadians(oldPoint.y)
        let oldLong = degreesToRadians(oldPoint.x)
        
        let newLat = degreesToRadians(newPoint.y)
        let newLong = degreesToRadians(newPoint.x)
        
        var bearing = radiansToDegrees(atan2(sin(newLong - oldLong) * cos(newLat),
            cos(oldLat) * sin(newLat) - sin(oldLat) * cos(newLat) * cos(newLong - oldLong)));
        
        
        return (bearing >= 0) ? bearing : bearing + 360.0
    }
    
    //http://stackoverflow.com/questions/24034544/dispatch-after-gcd-in-swift
    func delay(delay:Double, closure:()->()) {
        dispatch_after(
            dispatch_time(
                DISPATCH_TIME_NOW,
                Int64(delay * Double(NSEC_PER_SEC))
            ),
            dispatch_get_main_queue(), closure)
    }
    
    func mapView(mapView: AGSMapView!, didClickAtPoint screen: CGPoint, mapPoint mappoint: AGSPoint!, features: [NSObject : AnyObject]!) {
        
        self.queryTask = AGSQueryTask(URL: NSURL(string: Constants.Urls.PhotosLayer))
        self.queryTask.delegate = self
        
        var query = AGSQuery()
        query.geometry = createEnvelope(mappoint, radius: 50000)
        query.returnGeometry = false
        query.outFields = ["*"]
        
        self.queryTask.executeWithQuery(query)
    }
    
    func createEnvelope(mapPoint: AGSPoint, radius: Double) -> AGSEnvelope {
        var envelope = AGSEnvelope.envelopeWithXmin(mapPoint.x - radius, ymin: mapPoint.y - radius, xmax: mapPoint.x + radius, ymax: mapPoint.y + radius, spatialReference: mapPoint.spatialReference) as! AGSEnvelope
        
        return envelope
    }
    
    func queryTask(queryTask: AGSQueryTask!, operation op: NSOperation!, didFailWithError error: NSError!) {
        println("Query task error: \(error)")
    }
    
    func queryTask(queryTask: AGSQueryTask!, operation op: NSOperation!, didExecuteWithFeatureSetResult featureSet: AGSFeatureSet!) {
        self.issPhotoViewControllers = NSMutableArray()
        
        for feature in featureSet.features{
            if let storyboard = self.storyboard {
                if let agsfeature = feature as? AGSFeature{
                    if let issPhotoVC = storyboard.instantiateViewControllerWithIdentifier(Constants.Identifiers.ISSPhotoViewController) as? ISSPhotoViewController{
                        issPhotoVC.dispatchQueue = self.imageDispatchQueue
                        issPhotoVC.setFeature(agsfeature)
                        issPhotoVC.delegate = self
                        self.issPhotoViewControllers.addObject(issPhotoVC)
                    }
                }
            }
        }
        if self.issPhotoViewControllers.count > 0{
            var pageVC = UIPageViewController(transitionStyle: .Scroll, navigationOrientation: UIPageViewControllerNavigationOrientation.Horizontal, options: nil)
            
            pageVC.modalPresentationStyle = .FormSheet
            pageVC.dataSource = self
            pageVC.delegate = self
            pageVC.setViewControllers([self.issPhotoViewControllers[0]], direction: UIPageViewControllerNavigationDirection.Forward, animated: false, completion: nil)
            self.presentViewController(pageVC, animated: true, completion: nil)
        }
    }
    
    func viewImageAtNasa(url: String) {
        
    }
    
    func zoomToISSPhotoLocation(location: AGSPoint) {
        self.dismissViewControllerAnimated(true, completion: nil)
        
        let geometryEngine = AGSGeometryEngine.defaultGeometryEngine()
        let projectedLocation = geometryEngine.projectGeometry(location, toSpatialReference: self.mapView.spatialReference) as! AGSPoint
        self.mapView.centerAtPoint(projectedLocation, animated: true)
        
    }
    
    func dismissISSPhotoViewController(iSSPhotoViewController: ISSPhotoViewController) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    
    func pageViewController(pageViewController: UIPageViewController, viewControllerBeforeViewController viewController: UIViewController) -> UIViewController? {
        
        var index = self.issPhotoViewControllers.indexOfObject(viewController)
        
        if (index == 0) || (index == NSNotFound) {
            return nil
        }
        
        index--
        return self.issPhotoViewControllers[index] as? UIViewController
    }
    
    func pageViewController(pageViewController: UIPageViewController, viewControllerAfterViewController viewController: UIViewController) -> UIViewController? {
        
        var index = self.issPhotoViewControllers.indexOfObject(viewController)
        
        if index == NSNotFound {
            return nil
        }
        
        index++
        if index == self.issPhotoViewControllers.count {
            return nil
        }
        
        return issPhotoViewControllers[index] as? UIViewController
    }
    
    func presentationCountForPageViewController(pageViewController: UIPageViewController) -> Int {
        return self.issPhotoViewControllers.count
    }
    
    func presentationIndexForPageViewController(pageViewController: UIPageViewController) -> Int {
        return 0
    }
    
    @IBAction func showMenu(sender: UIButton) {
        self.animationView.hidden = false
        
        UIView.animateWithDuration(0.35, delay: 0, options: .CurveEaseOut, animations: { () -> Void in
            self.animationView.layer.cornerRadius = 0
            self.animationView.frame = CGRect(x: 0, y: 0, width: self.view.frame.width, height: 90.0)
        }) { (finished) -> Void in
            self.menu.hidden = false
        }
    }
    
    @IBAction func hideMenu(sender: UIButton) {
        self.animationView.frame = CGRect(x: 0, y: 0, width: self.view.frame.width, height: 90.0)
        self.menu.hidden = true
        UIView.animateWithDuration(0.35, delay: 0, options: .CurveEaseOut, animations: { () -> Void in
            self.animationView.layer.cornerRadius = 15.0
            self.animationView.frame = self.menuButton.frame
            }) { (finished) -> Void in
                self.animationView.hidden = true
        }
    }
    
    @IBAction func zoomToStation(sender: UIButton) {
        self.mapView.centerAtPoint(self.spaceStationGraphic.geometry as! AGSPoint, animated: true)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        println("OH NO!!!! I recieved a memory warning!")
    }
}

