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


class ViewController: UIViewController, TTMapViewDelegate, TTReverseGeocoderDelegate, TTRouteResponseDelegate, TTAnnotationDelegate, TTAlongRouteSearchDelegate, OptionsViewDelegate {
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
    let mapOptionsView = OptionsView(labels: ["Basic", "Custom"], selectedID: 0)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        initTomTomService()
        initUIViews()
    }
    
    func initTomTomService(){
        tomtomMap.delegate = self
        tomtomMap.annotationManager.delegate = self
        tomtomMap.center(on: TTCoordinate.MELBOURNE(), withZoom: 10)
        tomtomMap.onMapReadyCompletion {
            self.onMapReady()
        }
        alongRouteSearch.delegate = self
        reverseGeocoder.delegate = self
        route.delegate = self
    }
    
    func initUIViews(){
        departureImage = TTAnnotationImage.createPNG(withName: "ic_map_route_departure")
        mapOptionsView.delegate = self
        view.addSubview(mapOptionsView)
        mapOptionsView.translatesAutoresizingMaskIntoConstraints = false
        mapOptionsView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -20).isActive = true
        mapOptionsView.heightAnchor.constraint(equalToConstant:36).isActive = true
        view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-20-[v0]-20-|", options: [], metrics: nil, views: ["v0": mapOptionsView]))
    }
    
    func onMapReady(){
        tomtomMap.isShowsUserLocation = true
        print("Map Ready")
    }
    
    func clearMap(){
        tomtomMap.routeManager.removeAllRoutes()
        tomtomMap.annotationManager.removeAllAnnotations()
        departurePosition = kCLLocationCoordinate2DInvalid
        destinationPosition = kCLLocationCoordinate2DInvalid
        wayPointPosition = kCLLocationCoordinate2DInvalid
        fullRoute = nil
    }
    
    func isDestinationPositionSet ()->Bool{
        return CLLocationCoordinate2DIsValid(self.destinationPosition)
    }
    
    func isDeparturePositionSet()->Bool{
        return CLLocationCoordinate2DIsValid(self.departurePosition)
    }
    // TTMapViewDelegate
    func mapView(_ mapView: TTMapView, didLongPress coordinate: CLLocationCoordinate2D){
        if (isDeparturePositionSet() && isDestinationPositionSet()){
            clearMap()
        }else{
            handleLongPress(coordinate)
        }
    }
    
    func handleLongPress(_ coordinate:CLLocationCoordinate2D){
        let query = TTReverseGeocoderQueryBuilder.create(with: coordinate).build()
        reverseGeocoder.reverseGeocoder(with: query)
    }
    
    // TTReverseGeocoderDelegate
    func reverseGeocoder(_ reverseGeocoder: TTReverseGeocoder, completedWith response: TTReverseGeocoderResponse) {
        var address = " "
        guard let firstAddress = response.result.addresses.first else { return }
        if let freeFormAddress = firstAddress.address.freeformAddress{
            address = freeFormAddress
        }
        processGeocodeResponse(firstAddress.position, address)
    }
    
    func reverseGeocoder(_ reverseGeocoder: TTReverseGeocoder, failedWithError error: TTResponseError) {
        print(error.userInfo)
    }
    
    func processGeocodeResponse(_ geocodePosition: CLLocationCoordinate2D, _ address:String){
        if (!CLLocationCoordinate2DIsValid(departurePosition)){
            departurePosition = geocodePosition
            createAndDisplayMarkerAtPosition(departurePosition, withAnnotationImage: departureImage, andBalloonText: address)
        } else {
            destinationPosition = geocodePosition
            drawRouteWithDeparture(departure: departurePosition, andDestination: destinationPosition)
        }
        
    }
    
    func drawRouteWithDeparture(departure: CLLocationCoordinate2D, andDestination destination: CLLocationCoordinate2D){
        drawRouteWithDeparture(departure: departure, andDestination: destination, andWayPoint: kCLLocationCoordinate2DInvalid)
    }
    
    func drawRouteWithDeparture(departure: CLLocationCoordinate2D, andDestination destination: CLLocationCoordinate2D, andWayPoint wayPoint :CLLocationCoordinate2D) {
        let query = createRouteQueryWithOrigin(origin:departure, andDestination:destination, andWayPoint:wayPoint)
        route.plan(with: query)
    }
    
    //TTRouteResponseDelegate
    func route(_ route: TTRoute, completedWith result: TTRouteResult) {
        guard let plannedRoute = result.routes.first else {
            return
        }
        addActiveRouteToMap(route: plannedRoute)
    }
    
    func route(_ route: TTRoute, completedWith responseError: TTResponseError) {
      print(responseError.userInfo)
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
        tomtomMap.routeManager.removeAllRoutes()
        fullRoute = route
        if (!CLLocationCoordinate2DIsValid(wayPointPosition)) {
            tomtomMap.annotationManager.removeAllAnnotations()
        }
        let mapRoute = TTMapRoute(coordinatesData: fullRoute,
                                  with: TTMapRouteStyle.defaultActive(),
                                  imageStart: TTMapRoute.defaultImageDeparture(),
                                  imageEnd: TTMapRoute.defaultImageDestination())
        tomtomMap.routeManager.add(mapRoute)
        tomtomMap.routeManager.bring(toFrontRoute: mapRoute)
    }
    
    func createAndDisplayMarkerAtPosition(_ coords:CLLocationCoordinate2D, withAnnotationImage image:TTAnnotationImage, andBalloonText text: String) {
        positionsPoisInfo[coords] = text
        tomtomMap.annotationManager.add(TTAnnotation.init(coordinate: coords, annotationImage: image, anchor: .center, type: TTAnnotationType.focal))
    }
    
    //OptionsViewDelegate
    func displayMap(ID: Int, on: Bool){
        switch ID {
        case 1:
            displayStyleCustom()
        default:
            displayStyleBasic()
        }
    }
    
    func displayStyleBasic() {
        tomtomMap.setStylePath(nil)
    }
    
    func displayStyleCustom() {
        let customStyle = Bundle.main.path(forResource: "style", ofType: "json")
        tomtomMap.setStylePath(customStyle)
    }}
