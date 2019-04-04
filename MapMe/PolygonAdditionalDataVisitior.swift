//
//  PolygonAdditionalDataVisitior.swift
//  MapMe
//
//  Created by fred song on 3/4/19.
//  Copyright © 2019 TomTom. All rights reserved.
//

import TomTomOnlineSDKSearch

class PolygonAdditionalDataVisitior: NSObject, TTADPGeoJsonObjectVisitor, TTADPGeoJsonGeoVisitor {
    
    var lineStrings: [TTADPLineString] = []
    
    func visit(_ featureCollection: TTADPFeatureCollection) {
        for feature in featureCollection.features {
            feature.visitResult(self)
        }
    }
    
    func visit(_ polygon: TTADPPolygon) {
        lineStrings.append(polygon.exteriorRing)
    }
    
    func visit(_ multiPolygon: TTADPMultiPolygon) {
        for polygon in multiPolygon.polygons {
            lineStrings.append(polygon.exteriorRing)
        }
    }
    
}
