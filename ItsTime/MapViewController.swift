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
    var trackingAddressString: String = ""
    var isReset: Bool = false
    var trackingPlacemark: CLPlacemark?

    @IBOutlet weak var pinnedAddress: UILabel!
    
    var pinnedddress: CLPlacemark?
    var trackingAddress: String?
    let geoCoder = CLGeocoder()
    var directionsArray = [MKDirections]()
//    var currentLocation: CLLocation?
//    var backgroundTask: UIBackgroundTaskIdentifier = .invalid
    
    override func viewDidLoad() {
        super.viewDidLoad()

        checkLocationServices()
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.pausesLocationUpdatesAutomatically = false
//        locationManager.startMonitoringSignificantLocationChanges() //Daha fazla bilgi al bununla ilgili
        
//        DispatchQueue.main.async {
//            let alert = UIAlertController(title: "Important!", message: "You won't get notification, if you terminate the app.App should work at backgroud.", preferredStyle: .alert)
//            alert.addAction(UIAlertAction(title: "OK", style: .default, handler:nil))
//            self.present(alert, animated: true, completion: nil)
//        }

    }
   
    // MARK: Notifications
    
    func Notification() {
        
        let content = UNMutableNotificationContent()
        content.title = "Jumped!."
        content.body = "You arrived to the destination !.."
        content.sound = UNNotificationSound.default
//        content.categoryIdentifier = "alarm"
        
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        let center = UNUserNotificationCenter.current()

        center.add(request, withCompletionHandler: { (error) in
            if let error = error {
                print("\n\t ERROR: \(error)")
            } else {
                print("\n\t request fulfilled \(request)")
            }
        })
                print("Destination successful..")
        
//            let stopAction = UNNotificationAction(identifier: "DECLINE_ACTION", title: "Stop", options: UNNotificationActionOptions(rawValue: 0))
//            let category = UNNotificationCategory(identifier: "alarm", actions: [stopAction], intentIdentifiers: [], hiddenPreviewsBodyPlaceholder: "", options: .customDismissAction)
//            center.setNotificationCategories([category])

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

//    func stopNotification() {
//        pinnedAddress.text = ""
////        pinnedddress = nil
//    }
//
//    func startNotifications() {
//        pinnedAddress.text = self.pinned
//    }
//
//    func registerBackgroundTask() {
//        backgroundTask = UIApplication.shared.beginBackgroundTask { [weak self] in
//            self?.endBackgroundTask()
//        }
//        assert(backgroundTask != .invalid)
//    }
//
//    func endBackgroundTask() {
//        print("Background task ended.")
//        UIApplication.shared.endBackgroundTask(backgroundTask)
//        backgroundTask = .invalid
//    }

    @IBAction func chooseDestination(_ sender: Any) {

        getDirections()
        
//        let center = getCenterLocation(for: mapView)
//        self.pinnedLocation = center
//        print("Pinned Location: ", self.pinnedLocation!)
        locationManager.showsBackgroundLocationIndicator = true
        self.isReset = false
        
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
                    print("Pinned Region: ", pinnedddress?.region! as Any, pinnedddress!.thoroughfare as Any)
                    self.pinnedAddress.text = addressString
                }
        
//          var destinationImage = UIImage(named: "flag") How to put an image on specific map location
    }

    @IBAction func resetDestination(_ sender: Any) {
        locationManager.stopMonitoring(for: (self.pinnedddress?.region)!)
        mapView.removeOverlays(mapView.overlays)
        let _ = self.directionsArray.map{$0.cancel()}
        self.isReset = true
//        locationManager.stopUpdatingLocation()
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        locationManager.showsBackgroundLocationIndicator = false // Monitoring false olduğu için indicater'a ihtiyaç yok
    }
    
    //  MARK: Set and center current location
    func setupLocation() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest //..ForNavigation ile farkı ne ?
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
    
//    Lokasyonu belirtilen konumun adresini alıyoruz
    func getTrackingAddress(location: CLLocation) -> String{

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
            
            self.trackingAddress = addressString
            self.trackingPlacemark = placemark
            print("Tracking Address: ", addressString)
            
        }
        return trackingAddressString
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
                            print("Settings opened: \(success)")
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
        previousLocation = getCenterLocation(for: mapView) //Şu anki konumumuzu alıyoruz. Daha sonra bu bizim previous lokasyonumuz olacak
        locationManager.distanceFilter = 1 //Default değerini kullanabilirsin
    }
    //    MARK: Get directions
    
    func getDirections() {
        guard let location = locationManager.location?.coordinate else { return
            DispatchQueue.main.async {
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
//          Lokasyon her update edildiğinde yapamak istediğimiz işlem burada olmalı
//        let status = UIApplication.shared.applicationState
//        locationManager.showsBackgroundLocationIndicator = true
//        guard let location = locations.last else { return }
//        if location == locations.last {
//            _ = getTrackingAddress(location: location)
//            print("New location is \(location)")
//            self.currentLocation = location


//            if pinnedAddress.text != "" && self.trackingAddress != "" {
//                print("Regions: " , self.pinnedddress?.thoroughfare as Any, self.trackingPlacemark?.thoroughfare as Any)
////                print("SubLocality: " , self.pinnedddress?.subLocality as Any, self.currentPlacemark?.subLocality as Any)
//                if self.pinnedddress?.thoroughfare == self.trackingPlacemark?.thoroughfare { // self.pinnedddress?.subLocality == self.currentPlacemark?.subLocality
//                    if status == .background {
//                    Notification()
//                    }
//                    else{
//                        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
//                    }
//                }
//            }
//        }
//    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
//        Kullanıcı authorization değişikliği yaptığında yapılacak işlemler burada olacak
        checkLocationAuthorization()
    }
    
    func locationManager(_ manager: CLLocationManager, didStartMonitoringFor region: CLRegion) {
        print("Started Monitoring")
//        self.isMonitoring = true
    }

    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        print("Entering Region")
        let status = UIApplication.shared.applicationState
        
        if self.isReset == false {
                Notification()
        }
        else {
            UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        }
        
        if status == .active {
            UNUserNotificationCenter.current().removeAllDeliveredNotifications()

        }
    }

    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        print("Exit Region")
        locationManager.stopMonitoring(for: (self.pinnedddress?.region)!)
//        self.isMonitoring = false
        print("Stopped Monitoring")
        //gönderilern bildirimleri kapat - stop notifications
        //yeni notification: destination noktasını geçtiniz
    }
}  // uygulama kapatıldıktan sonra kullanıcı uygulamayı içerden sonlandırmamışsa çalışmaya devam eder stop monitoring ya da region'ı sıfırla


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
