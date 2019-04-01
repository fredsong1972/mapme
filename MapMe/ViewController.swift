//
//  ViewController.swift
//  MapMe
//
//  Created by Fred Song on 30/3/19.
//  Copyright © 2019 TomTom. All rights reserved.
//

import UIKit
import TomTomOnlineSDKMaps
import TomTomOnlineSDKSearch
import TomTomOnlineSDKRouting
import TomTomOnlineSDKMapsUIExtensions

class ViewController: UIViewController, TTMapViewDelegate, TTAnnotationDelegate, TTAlongRouteSearchDelegate {
    @IBOutlet weak var tomtomMap: TTMapView!
    let route = TTRoute()
    let reverseGeocoder = TTReverseGeocoder()
    let alongRouteSearch = TTAlongRouteSearch()
    var fullRoute: TTFullRoute?
    var departurePosition = kCLLocationCoordinate2DInvalid
    var destinationPosition = kCLLocationCoordinate2DInvalid
    var wayPointPosition = kCLLocationCoordinate2DInvalid
    var departureImage: TTAnnotationImage!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        self.initTomTomService()
        self.initUIViews()
    }
    
    func initTomTomService(){
        self.tomtomMap.delegate = self
        self.tomtomMap.annotationManager.delegate = self
        self.alongRouteSearch.delegate = self
    }
    
    func initUIViews(){
        self.departureImage = TTAnnotationImage.createPNG(withName: "ic_map_route_departure")
        
    }
    
    func clearMap(){
        self.tomtomMap.routeManager.removeAllRoutes()
        self.tomtomMap.annotationManager.removeAllAnnotations()
        self.departurePosition = kCLLocationCoordinate2DInvalid
        self.destinationPosition = kCLLocationCoordinate2DInvalid
        self.wayPointPosition = kCLLocationCoordinate2DInvalid
        self.fullRoute = nil
    }
    
}
