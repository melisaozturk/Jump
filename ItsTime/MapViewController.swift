//
//  MapViewController.swift
//  ItsTime
//
//  Created by melisa öztürk on 23.06.2019.
//  Copyright © 2019 melisa öztürk. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation
import UserNotifications

class MapViewController: UIViewController {

    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var locationInfo: UILabel!
    
    let regionInMeters: Double = 10000
    var locationManager = CLLocationManager()
    var previousLocation: CLLocation?
    var trackingAddressString: String = ""

    @IBOutlet weak var pinnedAddress: UILabel!
    
    var pinnedddress: CLPlacemark?
    var currentAddress: String?
    let geoCoder = CLGeocoder()
    var directionsArray = [MKDirections]()
    var currentLocation: CLLocation?
    var backgroundTask: UIBackgroundTaskIdentifier = .invalid

    override func viewDidLoad() {
        super.viewDidLoad()

        checkLocationServices()
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.pausesLocationUpdatesAutomatically = false
        
    }
    
    // MARK: Notifications
    
    func Notification() {
        let content = UNMutableNotificationContent()
        content.title = "Jumped!."
        content.body = "You arrived to the destination !.."
        content.sound = UNNotificationSound.default
        content.categoryIdentifier = "alarm"
        
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        let center = UNUserNotificationCenter.current()
//        center.removeAllPendingNotificationRequests()
        center.add(request, withCompletionHandler: { (error) in
            if let error = error {
                print("\n\t ERROR: \(error)")
            } else {
                print("\n\t request fulfilled \(request)")
            }
        })
                print("Destination successful..")

            let stopAction = UNNotificationAction(identifier: "DECLINE_ACTION", title: "Stop", options: [])//UNNotificationActionOptions(rawValue: 0))
            let category = UNNotificationCategory(identifier: "alarm", actions: [stopAction], intentIdentifiers: [])//, hiddenPreviewsBodyPlaceholder: "", options: [])//.customDismissAction)
            center.setNotificationCategories([category])
        
        let status = UIApplication.shared.applicationState
        
        if status == .active {
            UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        }
    }

    
//    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse,withCompletionHandler completionHandler: @escaping () -> Void) {
//
//        switch response.actionIdentifier {
//        case "DECLINE_ACTION":
//            endBackgroundTask()
//            break
//
//        default:
//            break
//        }
//        completionHandler()
//    }
//
//    func stopNotification() {
//        pinnedAddress.text = ""
//        pinnedddress = nil
//    }
    
    func registerBackgroundTask() {
        backgroundTask = UIApplication.shared.beginBackgroundTask { [weak self] in
            self?.endBackgroundTask()
        }
        assert(backgroundTask != .invalid)
    }
    
    func endBackgroundTask() {
        print("Background task ended.")
        UIApplication.shared.endBackgroundTask(backgroundTask)
        backgroundTask = .invalid
    }
    
    @IBAction func chooseDestination(_ sender: Any) {

        getDirections()
//        registerBackgroundTask()
        
            if pinnedddress != nil {
                    var addressString : String = ""
                    if pinnedddress?.subLocality != nil {
                        addressString = addressString + (pinnedddress?.subLocality!)! + ", "
                    }
                    if pinnedddress?.thoroughfare != nil {
                        addressString = addressString + (pinnedddress?.thoroughfare!)! + ", "
                    }
                    if pinnedddress?.locality != nil {
                        addressString = addressString + (pinnedddress?.locality!)! + ", "
                    }
                    if pinnedddress?.country != nil {
                        addressString = addressString + (pinnedddress?.country!)! + ", "
                    }
                    if pinnedddress?.postalCode != nil {
                        addressString = addressString + (pinnedddress?.postalCode!)! + " "
                    }
                    print("Pinned Address: ", addressString)

                    self.pinnedAddress.text = addressString

                }
    }
    
    //  MARK: Set and center current location
    func setupLocation() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }
    
    func centerViewOnUserLocation() {
        if let location = locationManager.location?.coordinate {
            let region = MKCoordinateRegion.init(center: location, latitudinalMeters: regionInMeters, longitudinalMeters: regionInMeters)
            mapView.setRegion(region, animated: true)
        }
    }
    
    func geocode(latitude: Double, longitude: Double, completion: @escaping (CLPlacemark?, Error?) -> ())  {
        CLGeocoder().reverseGeocodeLocation(CLLocation(latitude: latitude, longitude: longitude)) { completion($0?.first, $1) }
    }
    
    func getCenterLocation(for mapView: MKMapView) -> CLLocation {
        let latitude = mapView.centerCoordinate.latitude
        let longitude = mapView.centerCoordinate.longitude
        
        return CLLocation(latitude: latitude, longitude: longitude)
    }
    
    func getTrackingAddresses(location: CLLocation) -> String{
        
        geoCoder.reverseGeocodeLocation(location){ [weak self] (placemarks, error) in
            guard let self = self else {return}
            
            if let _ = error {
                //TODO: Show alert informing the user
                return
            }
            guard let placemark = placemarks?.first else {
                //TODO: Show alert informing the user
                return
            }
            
            var addressString : String = ""
            if placemark.subLocality != nil {
                addressString = addressString + placemark.subLocality! + ", "
            }
            if placemark.thoroughfare != nil {
                addressString = addressString + placemark.thoroughfare! + ", "
            }
            if placemark.locality != nil {
                addressString = addressString + placemark.locality! + ", "
            }
            if placemark.country != nil {
                addressString = addressString + placemark.country! + ", "
            }
            if placemark.postalCode != nil {
                addressString = addressString + placemark.postalCode! + " "
            }

            self.currentAddress = addressString
            print("Trackking/Current Address: ", addressString)
        }
        return trackingAddressString
    }
    
    // MARK: Check permissions
    func checkLocationServices() {
        //        Telefonun lokasyon servisi açık mı
        if CLLocationManager.locationServicesEnabled() {
            setupLocation()
            checkLocationAuthorization()
        }
        else {
            DispatchQueue.main.async {
                let alert = UIAlertController(title: "Warning! ", message: "Your location service is disabled.", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (action) in
                    exit(0)
                }))
                self.present(alert, animated: true)
            }
        }
    }
    
    
    func checkLocationAuthorization() {
        switch CLLocationManager.authorizationStatus() {
        case .authorizedWhenInUse:
            mapView.showsUserLocation = true
            DispatchQueue.main.async {
                let alert = UIAlertController(title: "Warning! Permission Needed.", message: "It's recommended you to choose authorized always for app to work properly.", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (action) in
                    guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {
                        return
                    }
                    if UIApplication.shared.canOpenURL(settingsUrl) {
                        UIApplication.shared.open(settingsUrl, completionHandler: { (success) in
                            print("Settings opened: \(success)") // Prints true
                        })
                    }
                }))
                self.present(alert, animated: true)
            }
            break
        case .notDetermined:
            locationManager.requestAlwaysAuthorization()
        case .restricted:
            break
        case .denied:
            break
        case .authorizedAlways:
            startTackingUserLocation()
            break
        @unknown default:
            print("Error")
        }
    }

    func startTackingUserLocation() {
        mapView.showsUserLocation = true
        centerViewOnUserLocation()
        locationManager.startUpdatingLocation()
        previousLocation = getCenterLocation(for: mapView)
    }
    //    MARK: Get directions
    
    func getDirections() {
        guard let location = locationManager.location?.coordinate else { return
            // kullanıcıya konumunun bizde olmadığını bildir
        }
        let request = createDirectionRequest(from: location)
        let directions = MKDirections(request: request)
        resetOverlays(withNew: directions)

        directions.calculate{ [unowned self] (response, error) in
            //Handle error if needed
            guard let response = response else { return
                DispatchQueue.main.async {
                    let alert = UIAlertController(title: "Sorry!", message: "I could't find any direction.", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                    self.present(alert, animated: true)
                }
            }
            for route in response.routes {
//                let steps = route.steps
                self.mapView.addOverlay(route.polyline)
                self.mapView.setVisibleMapRect(route.polyline.boundingMapRect, animated: true)
            }
        }
    }
    
    func createDirectionRequest(from coordinate: CLLocationCoordinate2D) -> MKDirections.Request {
        let destinationCoordinate = getCenterLocation(for: mapView).coordinate
        let startingLocation = MKPlacemark(coordinate: coordinate)
        let destination = MKPlacemark(coordinate: destinationCoordinate)
        
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: startingLocation)
        request.destination = MKMapItem(placemark: destination)
        request.transportType = .automobile
        request.requestsAlternateRoutes = true
        
        return request
    }
    
    func resetOverlays(withNew directions: MKDirections) {
        mapView.removeOverlays(mapView.overlays)
        let _ = self.directionsArray.map{$0.cancel()}
        directionsArray.append(directions)
    }
}

extension MapViewController: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
//          Lokasyon her update edildiğinde yapamak istediğimiz işlem burada olmalı        
        guard let location = locations.last else { return }
        if location == locations.last {
            _ = getTrackingAddresses(location: location)
            print("New location is \(location)")
            self.currentLocation = location
            
            if pinnedAddress.text != "" && self.currentAddress != "" {
                print("Pinned Addres: ", pinnedAddress.text!, "\n", "Current Address:  ", self.currentAddress!)
                if self.currentAddress == pinnedAddress.text {
                    Notification()
                }
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
//        Kullanıcı authorization değişikliği yaptığında yapılacak işlemler burada olacak
        checkLocationAuthorization()
    }
}


extension MapViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        let center = getCenterLocation(for: mapView)
        
        guard let previousLocation = self.previousLocation else {return}
        guard center.distance(from: previousLocation) > 20 else { return }
        self.previousLocation = center
        
        geoCoder.reverseGeocodeLocation(center){ [weak self] (placemarks, error) in
            guard let self = self else {return}
            
            if let _ = error {
                //TODO: Show alert informing the user
                return
            }
            guard let placemark = placemarks?.first else {
                //TODO: Show alert informing the user
                return
            }
            
            self.pinnedddress = placemark
//            Moving Pin Address
            var addressString : String = ""
            if placemark.subLocality != nil {
                addressString = addressString + placemark.subLocality! + ", "
            }
            if placemark.thoroughfare != nil {
                addressString = addressString + placemark.thoroughfare! + ", "
            }
            if placemark.locality != nil {
                addressString = addressString + placemark.locality! + ", "
            }
            if placemark.country != nil {
                addressString = addressString + placemark.country! + ", "
            }
            if placemark.postalCode != nil {
                addressString = addressString + placemark.postalCode! + " "
            }
            print("moving address :   ", addressString)
            
            DispatchQueue.main.async {
                self.locationInfo.text = addressString
            }
        }
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let renderer = MKPolylineRenderer(overlay: overlay as! MKPolyline)
        renderer.strokeColor = .red
        
        return renderer
    }
}
