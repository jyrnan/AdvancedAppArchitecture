/// Copyright (c) 2018 Razeware LLC
///
/// Permission is hereby granted, free of charge, to any person obtaining a copy
/// of this software and associated documentation files (the "Software"), to deal
/// in the Software without restriction, including without limitation the rights
/// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
/// copies of the Software, and to permit persons to whom the Software is
/// furnished to do so, subject to the following conditions:
///
/// The above copyright notice and this permission notice shall be included in
/// all copies or substantial portions of the Software.
///
/// Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
/// distribute, sublicense, create a derivative work, and/or sell copies of the
/// Software in any work that is designed, intended, or marketed for pedagogical or
/// instructional purposes related to programming, coding, application development,
/// or information technology.  Permission for such use, copying, modification,
/// merger, publication, distribution, sublicensing, creation of derivative works,
/// or sale is expressly withheld.
///
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
/// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
/// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
/// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
/// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
/// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
/// THE SOFTWARE.

import UIKit
import KooberUIKit
import KooberKit
import MapKit

class PickMeUpMapRootView: MKMapView {

  // MARK: - Properties
  let defaultMapSpan = MKCoordinateSpan(latitudeDelta: 0.006, longitudeDelta: 0.006)
  let mapDropoffLocationSpan = MKCoordinateSpan(latitudeDelta: 0.017, longitudeDelta: 0.017)

  var pickupLocation: Location? {
    didSet {
      if let pickupLocation = pickupLocation {
        pickupLocationAnnotation = MapAnnotationType.makePickupLocationAnnotation(for: pickupLocation)
      } else {
        pickupLocationAnnotation = nil
      }
    }
  }

  var dropoffLocation: Location? {
    didSet {
      dropoffLocationAnnotation = MapAnnotationType.makeDropoffLocationAnnotation(for: dropoffLocation)
      guard let coordinate = dropoffLocationAnnotation?.coordinate else { return }
      zoomOutToShowDropoffLocation(pickupCoordinate: coordinate)
    }
  }

  var imageCache: ImageCache

  var mapState = MapViewState() {
    didSet {
      let currentAnnotations = (annotations as! [MapAnnotation]) // In real world, cast instead of force unwrap.
      let updatedAnnotations = mapState.availableRideLocationAnnotations
        + mapState.pickupLocationAnnotations
        + mapState.dropoffLocationAnnotations

      let diff = MapAnnotionDiff.diff(currentAnnotations: currentAnnotations, updatedAnnotations: updatedAnnotations)
      if !diff.annotationsToRemove.isEmpty {
        removeAnnotations(diff.annotationsToRemove)
      }
      if !diff.annotationsToAdd.isEmpty {
        addAnnotations(diff.annotationsToAdd)
      }

      if !mapState.dropoffLocationAnnotations.isEmpty {
        zoomOutToShowDropoffLocation(pickupCoordinate: mapState.pickupLocationAnnotations[0].coordinate)
      } else {
        zoomIn(pickupCoordinate: mapState.pickupLocationAnnotations[0].coordinate)
      }
    }
  }

  var pickupLocationAnnotation: MapAnnotation? {
    didSet {
      guard oldValue != pickupLocationAnnotation else { return }
      removeAnnotation(oldValue)
      addAnnotation(pickupLocationAnnotation)
      guard let annotation = pickupLocationAnnotation else { return }
      zoomIn(pickupCoordinate: annotation.coordinate)
    }
  }

  var dropoffLocationAnnotation: MapAnnotation? {
    didSet {
      guard oldValue != dropoffLocationAnnotation else { return }
      removeAnnotation(oldValue)
      addAnnotation(dropoffLocationAnnotation)
    }
  }

  // MARK: - Methods
  init(frame: CGRect = .zero, imageCache: ImageCache) {
    self.imageCache = imageCache
    super.init(frame: frame)
    delegate = self
  }

  @available(*, unavailable)
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) is not supported by PickMeUpMapRootView.")
  }

  func removeAnnotation(_ annotation: MapAnnotation?) {
    guard let annotation = annotation else { return }
    removeAnnotation(annotation)
  }

  func addAnnotation(_ annotation: MapAnnotation?) {
    guard let annotation = annotation else { return }
    addAnnotation(annotation)
  }

  func zoomIn(pickupCoordinate: CLLocationCoordinate2D) {
    let center = pickupCoordinate
    let span = defaultMapSpan
    let region = MKCoordinateRegion(center: center, span: span)
    setRegion(region, animated: false)
  }

  func zoomOutToShowDropoffLocation(pickupCoordinate: CLLocationCoordinate2D) {
    let center = pickupCoordinate
    let span = mapDropoffLocationSpan
    let region = MKCoordinateRegion(center: center, span: span)
    setRegion(region, animated: true)
  }
}

extension PickMeUpMapRootView: MKMapViewDelegate {

  func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
    guard let annotation = annotation as? MapAnnotation else {
      return nil
    }
    let reuseID = reuseIdentifier(forAnnotation: annotation)
    guard let annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseID) else {
      return MapAnnotationView(annotation: annotation, reuseIdentifier: reuseID, imageCache: imageCache)
    }
    annotationView.annotation = annotation
    return annotationView
  }

  func reuseIdentifier(forAnnotation annotation: MapAnnotation) -> String {
    return annotation.imageIdentifier
  }
}
