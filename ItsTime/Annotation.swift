//
//  Annotation.swift
//  ItsTime
//
//  Created by melisa öztürk on 30.06.2019.
//  Copyright © 2019 melisa öztürk. All rights reserved.
//

import EventKit

class Alarm: NSObject {
    var title: String?
    var proximity: String?
    var structuredLocation: EKStructuredLocation?

    init(title name: String?, proximity: String, structureLocation location: EKStructuredLocation) {
        self.title = name
        self.proximity = proximity
        self.structuredLocation = location
        super.init()
    }
//
//    var locationManager = CLLocationManager()
//    var pinnedCoordinate: CLLocation?
//    
//    init(pinnedCoordinate: CLLocation?) {
//        self.pinnedCoordinate = pinnedCoordinate
//    }
//    
////     var coordinate = self.pinnedCoordinate.coordinate //CLLocationCoordinate2D(latitude:  self.pinnedCoordinate , longitude: -122.418_433)
//    
}
