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
    var trackingPlacemark: CLPlacemark?
    let destination = MKPointAnnotation()

    @IBOutlet weak var pinnedAddress: UILabel!
    
    var pinnedddress: CLPlacemark?
    var trackingAddress: String?
    let geoCoder = CLGeocoder()
    var directionsArray = [MKDirections]()
    //    var backgroundTask: UIBackgroundTaskIdentifier = .invalid
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        checkLocationServices()
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.pausesLocationUpdatesAutomatically = false
//        locationManager.activityType = CLActivityType.other
        checkBackgroundRefresh()
    }
    
    func checkBackgroundRefresh() {
        switch UIApplication.shared.backgroundRefreshStatus {
        case .restricted:
            DispatchQueue.main.async {
                let alert = UIAlertController(title: "Warning !.", message: "Ask for help to enable background app refresh. ", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                self.present(alert, animated: true)
            }
        case .denied:
            DispatchQueue.main.async {
                let alert = UIAlertController(title: "Warning !.", message: "Required to enable background app refresh. ", preferredStyle: .alert)
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
        case .available:
            break
        @unknown default:
            break
        }
    }
    
    // MARK: Notifications
    
    func Notification() {
        
        let content = UNMutableNotificationContent()
        content.title = "Jumped!."
        content.body = "You arrived to the destination !.."
        content.sound = UNNotificationSound.default
        
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

        // Define the custom actions.
        let stopAction = UNNotificationAction(identifier: "Stop_Action",
                                                 title: "Stop",
                                                 options: UNNotificationActionOptions(rawValue: 0))
        // Define the notification type
        let notificationCategory = UNNotificationCategory(identifier: "notification_category", actions: [stopAction], intentIdentifiers: [], hiddenPreviewsBodyPlaceholder: "", options: .customDismissAction)
        // Register the notification type.
        let notificationCenter = UNUserNotificationCenter.current()
        notificationCenter.setNotificationCategories([notificationCategory])
        
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
        destination.title = "Destination"
        let center = getCenterLocation(for: mapView)
        destination.coordinate = center.coordinate
        
        self.mapView.addAnnotation(destination)

    }
//    reset notification açılınca olacak şeyler
    @IBAction func resetDestination(_ sender: Any) {
        mapView.removeOverlays(mapView.overlays)
        let _ = self.directionsArray.map{$0.cancel()}
        locationManager.stopMonitoring(for: (self.pinnedddress?.region)!)
        locationManager.showsBackgroundLocationIndicator = false // Monitoring false olduğu için indicater'a ihtiyaç yok
        self.mapView.removeAnnotation(destination)
//        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
//        locationManager.stopUpdatingLocation()

        //Stop notifications araştır
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
        previousLocation = getCenterLocation(for: mapView) //Center konumumuzu alıyoruz. Daha sonra bu bizim previous lokasyonumuz olacak
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
//        guard let location = locations.last else { return }
//                if location == locations.last {
//                    print("New Location: ", location)
//        }
//    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        //        Kullanıcı authorization değişikliği yaptığında yapılacak işlemler burada olacak
        checkLocationAuthorization()
    }
    
    func locationManager(_ manager: CLLocationManager, didStartMonitoringFor region: CLRegion) {
        print("Started Monitoring")
        locationManager.showsBackgroundLocationIndicator = true
        checkNotificationPermission()
    }
    
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        print("Entering Region")
        Notification()
    }
    
    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        print("Exit Region")
    }
//    belirtilen koordinatın alanına girerse true çevirir
    func contains(_ coordinate: CLLocationCoordinate2D) -> Bool {
        return ((self.pinnedddress?.location?.coordinate) != nil)
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
//
extension MapViewController: UNUserNotificationCenterDelegate {
//
////    Bu method sadece uygulama forground'da çalışırken execute edilir
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {

        print("Test Foreground: \(notification.request.identifier)")

        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
//        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        
//        if notification.request.content.categoryIdentifier == "notification_category" {
//            // Retrieve the meeting details.
//            let meetingID = notification.request.content.userInfo["notification_id"] as! String
//            let userID = notification.request.content.userInfo["USER_ID"] as! String
//
//            // Add the meeting to the queue.
//            sharedMeetingManager.queueMeetingForDelivery(user: userID,
//                                                         meetingID: meetingID)
//
//            // Play a sound to let the user know about the invitation.
//            completionHandler(.sound)
//            return
//        }
//        else {
//            // Handle other notification types...
//        }

        // Don't alert the user for other types.
        completionHandler(UNNotificationPresentationOptions(rawValue: 0))

    }

//    Kullanıcı notification'a cevap verirse execute edilir.(Uygulamayı açmak, action seçmek gibi)

    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void){

        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
//        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }


}
