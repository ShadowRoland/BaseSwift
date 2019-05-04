//
//  MapViewController.swift
//  BaseSwift
//
//  Created by Gary on 2017/7/7.
//  Copyright © 2017年 shadowR. All rights reserved.
//

import SRKit
import Cartography
import JZLocationConverter

class MapViewController: BaseViewController {
    var constraintGroup = ConstraintGroup()
    var mapView: MAMapView!
    var mapSearch: AMapSearchAPI!
    var naviRoute: MANaviRoute?
    var gpsButton: UIButton!
    var userLocationAnnotationView: MAAnnotationView?
    weak var currentCalloutView: CustomCalloutView?
    var currentRoutePlanningType: RoutePlanningType = .none
    var selectedCoordinate: CLLocationCoordinate2D?
    var currentCoordinate: CLLocationCoordinate2D?
    var isSearchingHospital = false
    var isSuccessSearchHospital = false
    var pois: [AMapPOI] = []
    var annotations: [MAPointAnnotation] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        defaultNavigationBar("Nearby hospitals".localized)
        initView()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        mapView.userTrackingMode = .none
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        mapView.userTrackingMode = .follow
    }

    deinit {
        mapView.delegate = nil
        mapSearch.delegate = nil
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: Autorotate Orientation
    
    override func deviceOrientationDidChange(_ sender: AnyObject? = nil) {
        super.deviceOrientationDidChange(sender)
        
        initConstraint()
    }
    
    //MARK: - 视图初始化
    
    func initView() {
        mapView = MAMapView()
        view.addSubview(mapView)
        initConstraint()
        mapView.delegate = self
        mapView.showsUserLocation = true
        mapView.showsCompass = true
        mapView.showsScale = true
        mapView.zoomLevel = 16.1
        mapView.userTrackingMode = .follow

        gpsButton = UIButton()
        gpsButton.setImage(UIImage(named: "gps_stat1"), for: .normal)
        gpsButton.setImage(UIImage(named: "gps_stat2"), for: .selected)
        gpsButton.clicked(self, action: #selector(clickGpsButton(_:)))
        gpsButton.contentEdgeInsets = UIEdgeInsets(8.0, 8.0, 8.0, 8.0)
        mapView.addSubview(gpsButton)
        constrain(gpsButton) { (view) in
            view.bottom == view.superview!.bottom - 15.0
            view.leading == view.superview!.leading + 7.0
            view.width == 44.0
            view.height == 44.0
        }
        
        mapSearch = AMapSearchAPI()
        mapSearch.delegate = self
    }
    
    func initConstraint() {
        constraintGroup = constrain(mapView,
                                    self.car_topLayoutGuide,
                                    replace: constraintGroup) { (view, topLayoutGuide) in
            view.top == topLayoutGuide.bottom
            view.bottom == view.superview!.bottom
            view.leading == view.superview!.leading
            view.trailing == view.superview!.trailing
        }
    }
    
    //MARK: - 业务处理
    
    override func performViewDidLoad() {
        initConstraint()
        if !CLLocationManager.locationServicesEnabled()
            || CLLocationManager.authorizationStatus() == .denied {
            SRAlert.showToast("Please turn location on for your device".localized)
        }
    }
    
    func calculateRoute(_ poi: AMapPOI!) {
        let origin = AMapGeoPoint.location(withLatitude: CGFloat(currentCoordinate!.latitude),
                                           longitude: CGFloat(currentCoordinate!.longitude))
        let destination = AMapGeoPoint.location(withLatitude: CGFloat(poi.location.latitude),
                                                longitude: CGFloat(poi.location.longitude))
        switch currentRoutePlanningType {
        case .car:
            let request = AMapDrivingRouteSearchRequest()
            request.origin = origin
            request.destination = destination
            request.requireExtension = true
            request.strategy = 5
            mapSearch.aMapDrivingRouteSearch(request)
            
        case .bus:
            let request = AMapTransitRouteSearchRequest()
            request.origin = origin
            request.destination = destination
            request.city = poi.city
            request.requireExtension = true
            mapSearch.aMapTransitRouteSearch(request)
            
        case .foot:
            let request = AMapWalkingRouteSearchRequest()
            request.origin = origin
            request.destination = destination
            mapSearch.aMapWalkingRouteSearch(request)
            
        case .bike:
            let request = AMapRidingRouteSearchRequest()
            request.origin = origin
            request.destination = destination
            mapSearch.aMapRidingRouteSearch(request)
            
        default:
            break
        }
    }
    
    func isMatchRoutePlanningType(_ request: AMapRouteSearchBaseRequest!) -> Bool {
        switch currentRoutePlanningType {
        case .car:
            return request is AMapDrivingRouteSearchRequest
            
        case .bus:
            return request is AMapTransitRouteSearchRequest
            
        case .foot:
            return request is AMapWalkingRouteSearchRequest
            
        case .bike:
            return request is AMapRidingRouteSearchRequest
            
        default:
            return false
        }
    }
    
    //MARK: - 事件响应
    
    @objc func clickGpsButton(_ sender: Any) {
        if(mapView.userLocation.isUpdating && mapView.userLocation.location != nil) {
            mapView.setCenter(mapView.userLocation.location.coordinate, animated: true)
            gpsButton.isSelected = true
        }
    }
}

//MARK: MAMapViewDelegate

extension MapViewController: MAMapViewDelegate {
    func mapView(_ mapView: MAMapView!,
                 didUpdate userLocation: MAUserLocation!,
                 updatingLocation: Bool) {
        currentCoordinate = userLocation.coordinate
        if !updatingLocation && userLocationAnnotationView != nil {
            UIView.animate(withDuration: 0.1, animations: {
                let degree = CGFloat(userLocation.heading.trueHeading)
                self.userLocationAnnotationView?.transform =
                    CGAffineTransform(rotationAngle: degree * CGFloat.pi / 180.0)
            })
        }
        
        DispatchQueue.main.async {
            if !self.isSearchingHospital && !self.isSuccessSearchHospital {
                self.isSearchingHospital = true
                let request = AMapPOIAroundSearchRequest()
                request.location =
                    AMapGeoPoint.location(withLatitude: CGFloat(self.currentCoordinate!.latitude),
                                          longitude: CGFloat(self.currentCoordinate!.longitude))
                request.keywords = "Hospital".localized //查找附近的医院
                request.radius = 500000
                self.mapSearch.aMapPOIAroundSearch(request)
            }
        }
    }
    
    func mapView(_ mapView: MAMapView!, viewFor annotation: MAAnnotation!) -> MAAnnotationView! {
        if let annotation = annotation as? MANaviAnnotation {
            var annotationView =
                mapView.dequeueReusableAnnotationView(withIdentifier: "MANaviAnnotationView")
            if annotationView == nil {
                annotationView = MAAnnotationView(annotation: annotation,
                                                  reuseIdentifier: "MANaviAnnotationView")
                annotationView?.canShowCallout = true
                annotationView?.image = nil
                switch annotation.type {
                case .railway:
                    annotationView?.image = UIImage(named: "railway_station")
                    
                case .bus:
                    annotationView?.image = UIImage(named: "bus")
                    
                case .drive:
                    annotationView?.image = UIImage(named: "car")
                    
                case .walking:
                    annotationView?.image = UIImage(named: "man")
                    
                case .riding:
                    annotationView?.image = UIImage(named: "ride")
                    
                default:
                    break
                }
            }
            return annotationView
        } else if !(annotation is MAUserLocation) {
            var annotationView =
                mapView.dequeueReusableAnnotationView(withIdentifier: ReuseIdentifier)
                    as? MAPinAnnotationView
            if annotationView == nil {
                annotationView =
                    CustomAnnotationView(annotation: annotation, reuseIdentifier: ReuseIdentifier)
                (annotationView as! CustomAnnotationView).delegate = self
            }
            (annotationView as! CustomAnnotationView).poi = nil
            for i in 0 ..< annotations.count {
                if annotation.coordinate.latitude == annotations[i].coordinate.latitude
                    && annotation.coordinate.longitude == annotations[i].coordinate.longitude {
                    (annotationView as! CustomAnnotationView).poi = pois[i]
                    break
                }
            }
            annotationView!.image = UIImage(named: "hospital")
            return annotationView
        }
        return nil
    }
    
    func mapView(_ mapView: MAMapView!, didSelect view: MAAnnotationView!) {
        let coordinate = view.annotation.coordinate
        guard let annotationView = view as? CustomAnnotationView,
            coordinate.latitude != selectedCoordinate?.latitude
                || coordinate.longitude != selectedCoordinate?.longitude else {
                    return
        }
        
        currentCalloutView = annotationView.calloutView
        selectedCoordinate = annotationView.annotation.coordinate
        let annotation = annotationView.annotation
        for i in 0 ..< annotations.count {
            if annotation?.coordinate.latitude == annotations[i].coordinate.latitude
                && annotation?.coordinate.longitude == annotations[i].coordinate.longitude {
                calculateRoute(pois[i]) //延续之前的路线种类进行路线查询
                break
            }
        }
    }
    
    func mapView(_ mapView: MAMapView!, didAddAnnotationViews views: [Any]!) {
        guard let view = views.first as? MAAnnotationView, view.annotation is MAUserLocation else {
            return
        }
        
        let pre = MAUserLocationRepresentation()
        pre.image = UIImage(named: "user_position")
        mapView.update(pre)
        view.calloutOffset = CGPoint(0, 0)
        view.canShowCallout = false
        userLocationAnnotationView = view
    }
    
    func mapView(_ mapView: MAMapView!, rendererFor overlay: MAOverlay!) -> MAOverlayRenderer! {
        if overlay is LineDashPolyline {
            let naviPolyline: LineDashPolyline = overlay as! LineDashPolyline
            let renderer: MAPolylineRenderer = MAPolylineRenderer(overlay: naviPolyline.polyline)
            renderer.lineWidth = 8.0
            renderer.strokeColor = UIColor.red
            //renderer.lineDashPattern = [10, 15]
            return renderer
        }
        
        if overlay is MANaviPolyline {
            let naviPolyline: MANaviPolyline = overlay as! MANaviPolyline
            let renderer: MAPolylineRenderer = MAPolylineRenderer(overlay: naviPolyline.polyline)
            renderer.lineWidth = 8.0
            
            if naviPolyline.type == .walking {
                renderer.strokeColor = naviRoute?.walkingColor
            } else if naviPolyline.type == .railway {
                renderer.strokeColor = naviRoute?.railwayColor;
            } else {
                renderer.strokeColor = naviRoute?.routeColor;
            }
            
            return renderer
        }
        
        if overlay is MAMultiPolyline {
            let renderer =
                MAMultiColoredPolylineRenderer(multiPolyline: overlay as? MAMultiPolyline)!
            renderer.lineWidth = 8.0
            renderer.strokeColors = naviRoute?.multiPolylineColors
            return renderer
        }
        
        return nil
    }
    
    func mapView(_ mapView: MAMapView!, mapDidMoveByUser wasUserAction: Bool) {
        if gpsButton != nil {
            gpsButton.isSelected = mapView.centerCoordinate.latitude == currentCoordinate?.latitude
                && mapView.centerCoordinate.longitude == currentCoordinate?.longitude
        }
    }
    
    func mapView(_ mapView: MAMapView!, mapDidZoomByUser wasUserAction: Bool) {
        if gpsButton != nil {
            gpsButton.isSelected = mapView.centerCoordinate.latitude == currentCoordinate?.latitude
                && mapView.centerCoordinate.longitude == currentCoordinate?.longitude
        }
    }
}

//MARK: AMapSearchDelegate

extension MapViewController: AMapSearchDelegate {
    func onPOISearchDone(_ request: AMapPOISearchBaseRequest!, response: AMapPOISearchResponse!) {
        if let req = request as? AMapPOIAroundSearchRequest, "Hospital".localized == req.keywords {
            isSearchingHospital = false
            isSuccessSearchHospital = true
        }
        
        mapView.removeAnnotations(mapView.annotations)
        annotations.removeAll()
        
        pois = response.pois
        pois.forEach { poi in
            let annotation = MAPointAnnotation()
            annotation.coordinate =
                CLLocationCoordinate2DMake(CLLocationDegrees(poi.location.latitude),
                                           CLLocationDegrees(poi.location.longitude))
            annotation.title = poi.name
            annotations.append(annotation)
        }
        mapView.addAnnotations(annotations)
        mapView.showAnnotations(annotations, animated: true)
    }
    
    func onRouteSearchDone(_ request: AMapRouteSearchBaseRequest!,
                           response: AMapRouteSearchResponse!) {
        if CLLocationDegrees(request.destination.latitude) == selectedCoordinate?.latitude
            && CLLocationDegrees(request.destination.longitude) == selectedCoordinate?.longitude
            && isMatchRoutePlanningType(request) {
            naviRoute?.removeFromMapView()
            if response.count > 0 {
                var distance = 0
                var duration = 0
                if .bus == currentRoutePlanningType {
                    let transit = (response.route?.transits.first)!
                    naviRoute = MANaviRoute(for: transit,
                                            start: request.origin,
                                            end: request.destination)
                    distance = transit.distance + transit.walkingDistance
                    duration = transit.duration
                } else {
                    var type: MANaviAnnotationType = .drive
                    if .foot == currentRoutePlanningType {
                        type = .walking
                    } else if .bike == currentRoutePlanningType {
                        type = .riding
                    }
                    let path = (response.route?.paths.first)!
                    naviRoute = MANaviRoute(for: path,
                                            withNaviType: type,
                                            showTraffic: true,
                                            start: request.origin,
                                            end: request.destination)
                    distance = path.distance
                    duration = path.duration
                }
                naviRoute?.add(to: mapView)
                mapView.showOverlays(naviRoute?.routePolylines,
                                     edgePadding: UIEdgeInsets(),
                                     animated: true)
                mapView.addAnnotations(annotations)
                
                var distanceString = ""
                if distance < 1000 {
                    distanceString = String(int: distance) + Config.Unit.metre
                } else {
                    distanceString =
                        String(format: "%.2f", Float(distance) / 1000.0) + Config.Unit.kilometre2
                }
                distanceString = distanceString.isEmpty ? "" : distanceString + " "
                
                let hours = duration / (60 * 60)
                var minutes = duration % (60 * 60) / 60
                let seconds = duration % 60
                if duration < 60 || seconds > 30 { //小于1分钟按照1分钟算；将秒做四舍五入处理
                    minutes += 1
                }
                var durationString =
                    (hours != 0 ? String(format: "%d%@", hours, Config.Unit.hour2) : "")
                        + (minutes != 0 ? String(format: "%d%@", minutes, Config.Unit.minute2) : "")
                durationString = durationString.isEmpty ? "Arrived".localized : durationString
                
                currentCalloutView?.durationLabel.text = distanceString + durationString
            }
        }
    }
}

//MARK: CustomCalloutDelegate

extension MapViewController: CustomCalloutDelegate {
    func distance(of calloutView: CustomCalloutView!) -> String! {
        let current = CLLocation(latitude: currentCoordinate!.latitude,
                                 longitude: currentCoordinate!.longitude)
        let target = CLLocation(latitude: CLLocationDegrees(calloutView.poi.location.latitude),
                                longitude: CLLocationDegrees(calloutView.poi.location.longitude))
        let distance = current.distance(from: target)
        if distance < 1000 {
            return String(int: Int(distance)) + Config.Unit.metre
        } else {
            return String(format: "%.2f", distance / 1000.0) + Config.Unit.kilometre2
        }
    }
    
    func selectedRoutePlanningType(of calloutView: CustomCalloutView!) -> RoutePlanningType! {
        return currentRoutePlanningType
    }
    
    func calloutView(_ calloutView: CustomCalloutView!,
                     didSelected routePlanningType: RoutePlanningType) {
        guard MutexTouch else { return }
        
        currentRoutePlanningType = routePlanningType
        if routePlanningType == .none { //恢复显示所有的医院
            naviRoute?.removeFromMapView()
            mapView.showAnnotations(annotations, animated: true)
        } else { //为目的地选择了一种路线规划
            calculateRoute(calloutView.poi)
        }
    }
    
    func startNavigate(_ calloutView: CustomCalloutView!,
                       type routePlanningType: RoutePlanningType) {
        guard MutexTouch else { return }
        
        var applicationName = Bundle.main.infoDictionary?["CFBundleDisplayName"] as? String
        applicationName = isEmptyString(applicationName)
            ? Bundle.main.infoDictionary?["CFBundleName"] as? String
            : applicationName
        //iOS9以后需要在“Info.plist”中将要使用的URL Schemes列为白名单，才可正常检查其他应用是否安装
        //具体查看Info.plist文件中的LSApplicationQueriesSchemes对应的值
        if let url = URL(string: Config.Scheme.amap + "://"),
            UIApplication.shared.canOpenURL(url) { //首选高德地图，uri文档参考 http://lbs.amap.com/api/amap-mobile/guide/ios/ios-uri-information
            if routePlanningType == .none { //地图标注
                let query = ["sourceApplication" : applicationName ?? "",
                             "poiname" : calloutView.poi.name ?? "",
                             "lat" : calloutView.poi.location.latitude,
                             "lon" : calloutView.poi.location.longitude,
                             "dev" : 0] as ParamDictionary
                let string = String(format: "%@://viewMap?%@", Config.Scheme.amap, query.urlQuery)
                print(string)
                UIApplication.shared.openURL(URL(string: string)!)
            } else if routePlanningType == .car || routePlanningType == .foot { //导航，uri仅支持驾车和步行，高德地图当前版本v8.1.0.2063
                var t: Int?
                switch routePlanningType {
                case .car:
                    t = 0
                    
                case .foot:
                    t = 2
                    
                default:
                    break
                }
                var query = ["sourceApplication" : applicationName ?? "",
                             "backScheme" : Config.Scheme.base,
                             "poiname" : calloutView.poi.name ?? "",
                             "poiid" : calloutView.poi.uid ?? "",
                             "lat" : calloutView.poi.location.latitude,
                             "lon" : calloutView.poi.location.longitude,
                             "dev" : 0,
                             "style" : 0] as ParamDictionary
                if t != nil {
                    query["t"] = t!
                }
                let string = String(format: "%@://navi?%@", Config.Scheme.amap, query.urlQuery)
                print(string)
                UIApplication.shared.openURL(URL(string: string)!)
            } else if routePlanningType == .bus || routePlanningType == .bike { //路线规划
                var t: Int?
                switch routePlanningType {
                case .bus:
                    t = 1
                    
                case .bike:
                    t = 3
                    
                default:
                    break
                }
                var query = ["sourceApplication" : applicationName ?? "",
                             "slat" : currentCoordinate!.latitude,
                             "slon" : currentCoordinate!.longitude,
                             "sname" : "My position".localized,
                             "dlat" : calloutView.poi.location.latitude,
                             "dlon" : calloutView.poi.location.longitude,
                             "dname" : calloutView.poi.name ?? "",
                             "dev" : 0] as ParamDictionary
                if t != nil {
                    query["t"] = t!
                }
                let string = String(format: "%@://path?%@", Config.Scheme.amap, query.urlQuery)
                print(string)
                UIApplication.shared.openURL(URL(string: string)!)
            }
        } else if let url = URL(string: Config.Scheme.baiduMap + "://"),
            UIApplication.shared.canOpenURL(url) { //备选百度地图，uri文档参考 http://lbsyun.baidu.com/index.php?title=uri/api/ios
            if routePlanningType == .none {
                let query = ["src" : applicationName ?? "",
                             "location" : "\(calloutView.poi.location.latitude),\(calloutView.poi.location.longitude)",
                    "title" : calloutView.poi.name ?? "",
                    "content" : calloutView.poi.address ?? "",
                    "coord_type" : "gcj02"] as ParamDictionary
                let string = String(format: "%@://map/marker?%@", Config.Scheme.baiduMap, query.urlQuery)
                print(string)
                UIApplication.shared.openURL(URL(string: string)!)
            } else {
                var mode = ""
                switch routePlanningType {
                case .car:
                    mode = "driving"
                    
                case .bus:
                    mode = "transit"
                    
                case .foot:
                    mode = "walking"
                    
                case .bike:
                    mode = "riding"
                    
                default:
                    break
                }
                let query = ["src" : applicationName ?? "",
                             "origin" : "\(currentCoordinate!.latitude),\(currentCoordinate!.longitude)",
                    "destination" : "\(calloutView.poi.location.latitude),\(calloutView.poi.location.longitude)",
                    "mode" : mode,
                    "coord_type" : "gcj02"] as ParamDictionary
                let string = String(format: "%@://map/direction?%@", Config.Scheme.baiduMap, query.urlQuery)
                print(string)
                UIApplication.shared.openURL(URL(string: string)!)
            }
        } else { //调用原生地图
            let origin = MKMapItem(placemark: MKPlacemark(coordinate: JZLocationConverter.gcj02(toWgs84: currentCoordinate!),
                                                          addressDictionary: nil))
            let coordinate =
                CLLocationCoordinate2D(latitude: CLLocationDegrees(calloutView.poi.location.latitude),
                                       longitude: CLLocationDegrees(calloutView.poi.location.longitude))
            let destination =
                MKMapItem(placemark: MKPlacemark(coordinate: JZLocationConverter.gcj02(toWgs84: coordinate),
                                                 addressDictionary: nil))
            //destination.name = calloutView.poi.name
            var mode = ""
            switch routePlanningType {
            case .car:
                mode = MKLaunchOptionsDirectionsModeDriving
                
            case .bus:
                mode = MKLaunchOptionsDirectionsModeTransit
                
            case .foot:
                mode = MKLaunchOptionsDirectionsModeTransit
                
            default:
                if #available(iOS 10.0, *) {
                    mode = MKLaunchOptionsDirectionsModeDefault
                }
            }
            var options = [MKLaunchOptionsMapTypeKey : MKMapType.standard,
                           MKLaunchOptionsShowsTrafficKey : true] as [String : Any]
            if !mode.isEmpty {
                options[MKLaunchOptionsDirectionsModeKey] = mode
            }
            MKMapItem.openMaps(with: [origin, destination], launchOptions: options)
        }
    }
}
