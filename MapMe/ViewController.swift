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
    var fullRoute: TTFullRoute!
    var departurePosition = kCLLocationCoordinate2DInvalid
    var destinationPosition = kCLLocationCoordinate2DInvalid
    var wayPointPosition = kCLLocationCoordinate2DInvalid
    var departureImage: TTAnnotationImage!
    let positionsPoisInfo = NSMutableDictionary.init()
    
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
    
    func isDestinationPositionSet ()->Bool{
        return CLLocationCoordinate2DIsValid(self.destinationPosition)
    }
    
    func isDeparturePositionSet()->Bool{
        return CLLocationCoordinate2DIsValid(self.departurePosition)
    }
    // TTMapViewDelegate
    func mapView(_ mapView: TTMapView, didLongPress coordinate: CLLocationCoordinate2D){
        if (self.isDeparturePositionSet() && self.isDestinationPositionSet()){
            self.clearMap()
        }else{
            self.handleLongPress(coordinate)
        }
    }
    
    func handleLongPress(_ coordinate:CLLocationCoordinate2D){
        let query = TTReverseGeocoderQueryBuilder.create(with: coordinate).build()
        self.reverseGeocoder.reverseGeocoder(with: query)
    }
    
    // TTReverseGeocoderDelegate
    func reverseGeocoder(_ reverseGeocoder: TTReverseGeocoder, completedWith response: TTReverseGeocoderResponse) {
        var address = " "
        guard let firstAddress = response.result.addresses.first else { return }
        if let freeFormAddress = firstAddress.address.freeformAddress{
            address = freeFormAddress
        }
        self.processGeocodeResponse(firstAddress.position, address)
    }
    
    func processGeocodeResponse(_ geocodePosition: CLLocationCoordinate2D, _ address:String){
        if (!CLLocationCoordinate2DIsValid(self.departurePosition)){
            self.departurePosition = geocodePosition
            self.createAndDisplayMarkerAtPosition(self.departurePosition, withAnnotationImage: self.departureImage, andBalloonText: address)
        } else {
            self.destinationPosition = geocodePosition
            self.drawRouteWithDeparture(departure: self.departurePosition, andDestination: self.destinationPosition)
        }
        
    }
    
    func drawRouteWithDeparture(departure: CLLocationCoordinate2D, andDestination destination: CLLocationCoordinate2D){
        self.drawRouteWithDeparture(departure: departure, andDestination: destination, andWayPoint: kCLLocationCoordinate2DInvalid)
    }
    
    func drawRouteWithDeparture(departure: CLLocationCoordinate2D, andDestination destination: CLLocationCoordinate2D, andWayPoint wayPoint :CLLocationCoordinate2D) {
        let query = self.createRouteQueryWithOrigin(origin:departure, andDestination:destination, andWayPoint:wayPoint)
        self.route.plan(with: query)
    }
    
    //TTRouteResponseDelegate
    func route(_ route: TTRoute, completedWith result: TTRouteResult) {
        guard let plannedRoute = result.routes.first else {
            return
        }
        self.addActiveRouteToMap(route: plannedRoute)
    }
    
    func createRouteQueryWithOrigin(origin:CLLocationCoordinate2D, andDestination destination:CLLocationCoordinate2D, andWayPoint wayPoint:CLLocationCoordinate2D)->TTRouteQuery {
        let builder = TTRouteQueryBuilder.create(withDest: destination, andOrig: origin)
        if (CLLocationCoordinate2DIsValid(wayPoint)) {
            var wayPoints = [wayPoint]
            builder.withWayPoints(&wayPoints, count: UInt(wayPoints.count))
        }
        return builder.build()
    }
    
    func addActiveRouteToMap(route:TTFullRoute) {
        self.tomtomMap.routeManager.removeAllRoutes()
        self.fullRoute = route
        if (!CLLocationCoordinate2DIsValid(self.wayPointPosition)) {
            self.tomtomMap.annotationManager.removeAllAnnotations()
        }
        let mapRoute = TTMapRoute(coordinatesData: self.fullRoute,
                                  with: TTMapRouteStyle.defaultActive(),
                                  imageStart: TTMapRoute.defaultImageDeparture(),
                                  imageEnd: TTMapRoute.defaultImageDestination())
        self.tomtomMap.routeManager.add(mapRoute)
        self.tomtomMap.routeManager.bring(toFrontRoute: mapRoute)
    }
    
    func createAndDisplayMarkerAtPosition(_ coords:CLLocationCoordinate2D, withAnnotationImage image:TTAnnotationImage, andBalloonText text: String) {
        self.positionsPoisInfo[coords] = text
        self.tomtomMap.annotationManager.add(TTAnnotation.init(coordinate: coords, annotationImage: image, anchor: .center, type: TTAnnotationType.focal))
    }
    
}