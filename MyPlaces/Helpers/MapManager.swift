//
//  MapManager.swift
//  MyPlaces
//
//  Created by Максим Мосалёв on 18.12.2022.
//

import UIKit
import MapKit

class MapManager {
    
    let locationManager = CLLocationManager()

    
    var placeCoordinate: CLLocationCoordinate2D?
    let regionInMeters = 1000.00
    var directionsArray: [MKDirections] = []
    
    var trackingLabelText = ""
    var timeTrakingLabelText = ""
    
    
    // Маркер заведения
    func setupPlacemark(place: Place, mapView: MKMapView) {
        guard let location = place.location else { return }
        
        let geocoder = CLGeocoder()
        geocoder.geocodeAddressString(location) { (placemarks, error) in
            if let error = error {
                print(error)
                return
            }
            
            guard let placemarks = placemarks else {return}
            let placemark = placemarks.first
            
            let annotation = MKPointAnnotation()
            annotation.title = place.name
            annotation.subtitle = place.type
            
            guard let placemarkLocation = placemark?.location else { return }
            
            annotation.coordinate = placemarkLocation.coordinate
            self.placeCoordinate = placemarkLocation.coordinate
            
            mapView.showAnnotations([annotation], animated: true)
            
            mapView.selectAnnotation(annotation, animated: true)
            
        
        }
    }
    
    // Проверка доступности сервисов геоолокации
    func checkLocationServices(mapView: MKMapView, segueIdentifier: String, closure: () -> ()) {
        if CLLocationManager.locationServicesEnabled() {
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
            checkLocationAuthorization(mapView: mapView, segueIdentifier: segueIdentifier)
            closure()
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.showAlert(title: "Location Services are disabled", message: "Please turn on Location Sevices in your device settings")
            }
        }
    }
    
    // Проверка авторизации приложения для использования сервисов геолокации
    func checkLocationAuthorization(mapView: MKMapView, segueIdentifier: String) {
        switch locationManager.authorizationStatus {
        case .authorizedWhenInUse:
            mapView.showsUserLocation = true
            if segueIdentifier == "getAddress" {showUserLocation(mapView: mapView)}
            break
        case .denied:
            break
            // show alert
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .restricted:
            // alert
            break
        case . authorizedAlways:
            break
        @unknown default:
            print("New case is available")
        }
    }
    
    // Фокус карты на локацию пользователя
    func showUserLocation(mapView: MKMapView) {
        if let location = locationManager.location?.coordinate {
            let region = MKCoordinateRegion(center: location, latitudinalMeters: regionInMeters, longitudinalMeters: regionInMeters)
            
            mapView.setRegion(region, animated: true)
        }
    }
    
    // Построение маршрута от пользователя до заведения
    func getDirections(for mapView: MKMapView, previousLocation: (CLLocation) ->()) {
         
         guard let location = locationManager.location?.coordinate else {
             showAlert(title: "Error", message: "Current location is not found")
             return
         }
         
         locationManager.startUpdatingLocation()
        previousLocation(CLLocation(latitude: location.latitude, longitude: location.longitude))
         
         guard let request = createDirectionsRequests(from: location) else {
             showAlert(title: "Error", message: "Destination is not found")
             return
         }
         
         let directions = MKDirections(request: request)
        resetMapView(withView: directions, mapView: mapView)
         
         directions.calculate() { (response, error) in
             
             if let error = error {
                 print(error)
                 return
             }
             
             guard let response = response else {
                 self.showAlert(title: "Error", message: "Direction is not available")
                 return
             }
             
             for route in response.routes {
                 mapView.addOverlay(route.polyline)
                 mapView.setVisibleMapRect(route.polyline.boundingMapRect, animated: true)
                 
                 let distance = String(format: "%.1f", route.distance / 1000)
                 let timeInterval = route.expectedTravelTime
                 let timeIntervalHours = ((Int(timeInterval)) / 3600)
                 let timeIntervalMinutes = ((Int(timeInterval)) % 3600) / 60
                  

                 self.trackingLabelText = "Расстояние до места: \(distance) км."
               
                 self.timeTrakingLabelText = "Время в пути составит: \(timeIntervalHours) часов \(timeIntervalMinutes) минут"
                
             }
             
         }
     }
    
   // Настройка запроса для расчета маршрута
    func createDirectionsRequests(from coordinate: CLLocationCoordinate2D) -> MKDirections.Request? {
        
        guard let destinationCoordinate = placeCoordinate else { return nil }
        let startingLocation = MKPlacemark(coordinate: coordinate)
        let destination = MKPlacemark(coordinate: destinationCoordinate)
        
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: startingLocation)
        request.destination = MKMapItem(placemark: destination)
        request.transportType = .automobile
        request.requestsAlternateRoutes = true
        
        return request
    }
    
    // Изменение отображаемой области карты в соответствии с перемещением пользователя
    func startTrackingUserLocation(for mapView: MKMapView, and location: CLLocation?, closure: (_ currentLocation: CLLocation) -> ()) {
        
        guard let location = location else { return }
        let center = getCenterLocation(for: mapView)
        guard center.distance(from: location) > 50 else { return }
        
        closure(center)
    }
    
    // Сброс всех ранее построенных маршрутов
    func resetMapView(withView directions: MKDirections, mapView: MKMapView) {
        
        mapView.removeOverlays(mapView.overlays)
        directionsArray.append(directions)
        let _ = directionsArray.map { $0.cancel()}
        directionsArray.removeAll()
    }
    
    
    func getCenterLocation(for mapView: MKMapView) -> CLLocation {
        
        let latitude = mapView.centerCoordinate.latitude
        let longitude = mapView.centerCoordinate.longitude
        
        return CLLocation(latitude: latitude, longitude: longitude)
    }
    
    
    private func showAlert(title: String, message: String) {
        
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default)
        alert.addAction(okAction)
        
        let alertWindow = UIWindow(frame: UIScreen.main.bounds)
        alertWindow.rootViewController = UIViewController()
        alertWindow.windowLevel = UIWindow.Level.alert + 1
        alertWindow.makeKeyAndVisible()
        alertWindow.rootViewController?.present(alert, animated: true)
        
    }
    
}
