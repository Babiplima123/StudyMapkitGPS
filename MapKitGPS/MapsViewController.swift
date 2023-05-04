//
//  MapsViewController.swift
//  MapKitGPS
//
//  Created by Barbara Ann Pereira Lima on 29/01/23.


import UIKit
import MapKit

class MapsViewController: UIViewController {
    
    @IBOutlet weak var mapsView: MKMapView!
    
    let locationManager: CLLocationManager = CLLocationManager()
    var lastLocation: CLLocationCoordinate2D? = nil
    
    var selectedAddress: Address? = nil
    
    @IBOutlet weak var adressTextField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapsView.delegate        = self
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        
        if CLLocationManager.locationServicesEnabled(){
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
            locationManager.requestLocation()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        mapsView.showsUserLocation = true
        locationManager.startUpdatingLocation()
        
        if let address = selectedAddress {
            showRoute(address)
        }
    }
    
    @IBAction func tappedShowAdress(_ sender: Any) {
        getPossibleAdressesFromText()
    }
    
    private func getPossibleAdressesFromText(){
        var addresses: [Address] = []
        CLGeocoder().geocodeAddressString(adressTextField.text!) { (placemarks, error) in
            if error == nil {
                for placemark in placemarks! {
                    addresses.append(self.convertToAdress(placemark: placemark))
                }
                self.showAddressesTable(addresses:addresses)
            } else {
                let controller = UIAlertController(title: "Error", message: "Problem trying to fetch addresses From the text", preferredStyle: UIAlertController.Style.alert)
                self.present(controller, animated: true)
        }
    }
    
 }
    private func convertToAdress(placemark: CLPlacemark) -> Address {
        return Address(name: placemark.postalAddress!.street, placemark: placemark, postalAddress: placemark.postalAddress!);
    }
    
    private func showAddressesTable(addresses: [Address]){
        let addressesVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(identifier: "AddressesTableViewController") as!
          AddressesTableViewController
        addressesVC.addresses = addresses
        addressesVC.selectedAddress = { address in
            self.selectedAddress = address
    }
    self.navigationController?.pushViewController(addressesVC, animated: true)
  }
    
    private func showRoute(_ address:Address){
        let destinationAnnotation   = MKPointAnnotation()
        destinationAnnotation.coordinate = address.placemark.location!.coordinate
        destinationAnnotation.title = address.name
        self.mapsView.addAnnotation(destinationAnnotation)
        
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: lastLocation!))
        request.destination = MKMapItem(
            placemark: MKPlacemark(placemark: address.placemark))
        request.transportType = .automobile
        
        let directions = MKDirections(request: request)
        
        directions.calculate { (response, error) in
            guard let unwrappedResponse = response else { return }
            
            for route in unwrappedResponse.routes {
                self.mapsView.addOverlay(route.polyline)
                self.mapsView.setVisibleMapRect(route.polyline.boundingMapRect, animated: true)
            }
        }
    }
}

extension MapsViewController : CLLocationManagerDelegate {

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]){
        let location = locations.last
        self.lastLocation = location?.coordinate
        mapsView.centerCoordinate = location!.coordinate
        let region = mapsView.regionThatFits(MKCoordinateRegion(center: location!.coordinate, latitudinalMeters: 600.0, longitudinalMeters: 600.0))
        mapsView.setRegion(region, animated: false)
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print(error.localizedDescription)
    }

}

extension MapsViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let renderer = MKPolylineRenderer(polyline: overlay as! MKPolyline)
        renderer .strokeColor = .orange
        renderer.lineWidth = 5.0
        return renderer
    }
}
