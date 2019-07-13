//
//  MapViewController.swift
//  ItsTime
//
//  Created by melisa öztürk on 23.06.2019.
//  Copyright © 2019 melisa öztürk. All rights reserved.
//
// Kullanıcıdan alınan veriyi takip etmek için için startMonitoring(for region: CLRegion)
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
    var trackingPlacemark: CLPlacemark?
    let destination = MKPointAnnotation()
    //    var notificationAddress: String?
    //    var isReset: Bool! = false
    
    @IBOutlet weak var pinnedAddress: UILabel!
    //    var region: CLRegion?
    var pinnedddress: CLPlacemark?
    let geoCoder = CLGeocoder()
    var directionsArray = [MKDirections]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        checkLocationServices()
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.pausesLocationUpdatesAutomatically = false
        //        locationManager.startMonitoringSignificantLocationChanges()
        
    }
    
    // MARK: Notifications
    
    func Notification() {
        
        let content = UNMutableNotificationContent()
        content.title = "Jumped!."
        content.body = "You arrived to the destination!"//\n\(notificationAddress!)"
        content.sound = UNNotificationSound.default
        
        //        pinnedddress?.region?.notifyOnEntry = true
        //        pinnedddress?.region?.notifyOnExit = false
        //        let trigger = UNLocationNotificationTrigger(region: (self.pinnedddress?.region)! , repeats: false)
        
        let request = UNNotificationRequest(identifier: "jump", content: content, trigger: nil)
        let center = UNUserNotificationCenter.current()
        
        center.add(request, withCompletionHandler: { (error) in
            if let error = error {
                print("\n\t ERROR: \(error)")
            } else {
                print("\n\t request fulfilled \(request)")
            }
        })
        print("Destination successful..")
        
    }
    
    func ErrorNotification() {
        
        let content = UNMutableNotificationContent()
        content.title = "Error!."
        content.body = "An error occured."
        content.sound = UNNotificationSound.default
        
        let request = UNNotificationRequest(identifier: "error", content: content, trigger: nil)
        let center = UNUserNotificationCenter.current()
        
        center.add(request, withCompletionHandler: { (error) in
            if let error = error {
                print("\n\t ERROR: \(error)")
            } else {
                print("\n\t request fulfilled \(request)")
            }
        })
        print("Error")
    }
    
    func checkNotificationPermission(){
        // Request Notification Settings
        UNUserNotificationCenter.current().getNotificationSettings { (notificationSettings) in
            switch notificationSettings.authorizationStatus {
            case .notDetermined:
                UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound], completionHandler: {(granted, error) in
                    print("Local Notification Granted: \(granted)")
                })
            case .authorized: break
            // Schedule Local Notification
            case .denied:
                DispatchQueue.main.async {
                    let alert = UIAlertController(title: "Warning !.", message: "Notification permission required.", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (action) in
                        guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {
                            return
                        }
                        if UIApplication.shared.canOpenURL(settingsUrl) {
                            UIApplication.shared.open(settingsUrl, completionHandler: { (success) in
                                print("Settings opened: \(success)")
                            })
                        }
                    }))
                    self.present(alert, animated: true)
                }
            case .provisional:
                break
            @unknown default:
                break
            }
        }
    }
    
    @IBAction func chooseDestination(_ sender: Any) {
        
        getDirections()
        locationManager.showsBackgroundLocationIndicator = true
        checkNotificationPermission()
        
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
            
            locationManager.startMonitoring(for: (pinnedddress?.region)!)
            //            print("Pinned Region: ", pinnedddress?.region! as Any, pinnedddress!.thoroughfare as Any)
            
            self.pinnedAddress.text = addressString
            
            destination.subtitle = addressString
        }
        
        destination.title = "Destination"
        let center = getCenterLocation(for: mapView)
        destination.coordinate = center.coordinate
        
        self.mapView.addAnnotation(destination)
    }
    
    //    reset notification açılınca olacak şeyler
    @IBAction func resetDestination(_ sender: Any) {
        mapView.removeOverlays(mapView.overlays)
        let _ = self.directionsArray.map{$0.cancel()}
        self.mapView.removeAnnotation(destination)
        locationManager.showsBackgroundLocationIndicator = false
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
        locationManager.stopMonitoring(for: (pinnedddress?.region)!)
        locationManager.stopMonitoringSignificantLocationChanges()
        //        locationManager.stopUpdatingLocation()
        //        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["jump"])
    }
    
    
    //  MARK: Set and center current location
    func setupLocation() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }
    //      Bulunduğumuz konumu haritada ortalıyoruz
    func centerViewOnUserLocation() {
        if let location = locationManager.location?.coordinate {
            let region = MKCoordinateRegion.init(center: location, latitudinalMeters: regionInMeters, longitudinalMeters: regionInMeters)
            mapView.setRegion(region, animated: true)
        }
    }
    
    func geocode(latitude: Double, longitude: Double, completion: @escaping (CLPlacemark?, Error?) -> ())  {
        CLGeocoder().reverseGeocodeLocation(CLLocation(latitude: latitude, longitude: longitude)) { completion($0?.first, $1) }
    }
    //  Merkez konumu alıyoruz
    func getCenterLocation(for mapView: MKMapView) -> CLLocation {
        let latitude = mapView.centerCoordinate.latitude
        let longitude = mapView.centerCoordinate.longitude
        
        return CLLocation(latitude: latitude, longitude: longitude)
    }
    
    //     MARK: Check permissions
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
    
    
    func checkLocationAuthorization() {             //--------------------------> DEĞİŞİKLİK YAP WHEN IN USE'A GÖRE
        switch CLLocationManager.authorizationStatus() {
        case .authorizedWhenInUse:
            mapView.showsUserLocation = true
                        DispatchQueue.main.async {
                            let alert = UIAlertController(title: "Warning! Permission required.", message: "It's recommended you to choose authorized always for app to work properly.", preferredStyle: .alert)
                            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (action) in
                                guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {
                                    return
                                }
                                if UIApplication.shared.canOpenURL(settingsUrl) {
                                    UIApplication.shared.open(settingsUrl, completionHandler: { (success) in
                                        print("Settings opened: \(success)")
                                    })
                                }
                            }))
                            self.present(alert, animated: true)
                        }
//            startTackingUserLocation()
            break
        case .notDetermined:
            locationManager.requestAlwaysAuthorization()
        case .restricted:
            break
        case .denied:
            break
        case .authorizedAlways:
            startTackingUserLocation()
//            DispatchQueue.main.async {
//                let alert = UIAlertController(title: "Warning! Permission required.", message: "Authorization when in use is recommended.", preferredStyle: .alert)
//                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (action) in
//                    guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {
//                        return
//                    }
//                    if UIApplication.shared.canOpenURL(settingsUrl) {
//                        UIApplication.shared.open(settingsUrl, completionHandler: { (success) in
//                            print("Settings opened: \(success)")
//                        })
//                    }
//                }))
//                self.present(alert, animated: true)
//            }
            break
        @unknown default:
            print("Error")
            break
        }
    }
    
    func startTackingUserLocation() {
        mapView.showsUserLocation = true
        centerViewOnUserLocation()
        locationManager.startUpdatingLocation()
        previousLocation = getCenterLocation(for: mapView) //Center konumumuzu alıyoruz. Daha sonra bu bizim previous lokasyonumuz olacak
        locationManager.distanceFilter = 1 //Default değerini kullanabilirsin
    }
    //    MARK: Get directions
    
    func getDirections() {
        guard let location = locationManager.location?.coordinate else { return
            DispatchQueue.main.async {//Check your internet connection or location authorization and maybe battery
                let alert = UIAlertController(title: "Sorry!", message: "I could't find your location.", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                self.present(alert, animated: true)
            }        }
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
                //                let steps = route.steps daha sonra bak new feature olarak ekle
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
    
    //    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    //        guard let location = locations.last else { return }
    //                if location == locations.last {
    //                    print("New Location: ", location)
    //                    if  self.region == pinnedddress?.region! {//&& !isReset{
    //                        DispatchQueue.main.async {
    //                            let alert = UIAlertController(title: "Info!", message: "You are already at the destination.", preferredStyle: .alert)
    //                            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
    //                            self.present(alert, animated: true)
    //                        }
    
    
    //                    }
    //                    locationManager.stopMonitoringSignificantLocationChanges()
    //        }
    //    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        //        Kullanıcı authorization değişikliği yaptığında yapılacak işlemler burada olacak
        checkLocationAuthorization()
    }
    
    func locationManager(_ manager: CLLocationManager, didStartMonitoringFor region: CLRegion) {
        print("Started Monitoring")
        
        //            DispatchQueue.main.async {
        //                let alert = UIAlertController(title: "Info!", message: "Monitoring started.", preferredStyle: .alert)
        //                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        //                self.present(alert, animated: true)
        //            }
        
    }
    
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        print("Entered Region")
        Notification()
        
    }
    
    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        print("Exit Region")
        
        DispatchQueue.main.async {
            let alert = UIAlertController(title: "Warning!", message: "You left the destination.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(alert, animated: true)
        }
    }
}


extension MapViewController: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        let center = getCenterLocation(for: mapView)
        
        guard let previousLocation = self.previousLocation else {return}
        guard center.distance(from: previousLocation) > 20 else { return }
        self.previousLocation = center // Eski lokasyon ve yeni lokasyonu değiştiriyoruz
        
        geoCoder.reverseGeocodeLocation(center){ [weak self] (placemarks, error) in
            guard let self = self else {return}
            
            if let _ = error {
                //TODO: Show alert informing the user
                self.ErrorNotification()
                return
            }
            guard let placemark = placemarks?.first else {
                //TODO: Show alert informing the user
                self.ErrorNotification()
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
            //            print("Moving Address :   ", addressString)
            
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

