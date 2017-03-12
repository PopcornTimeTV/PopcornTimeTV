

import Foundation
import MediaPlayer


public enum TableViewUpdates {
    case reload
    case insert
    case delete
}

public protocol AirPlayManagerDelegate: class {
    func updateTableView(dataSource newDataSource: [Any], updateType: TableViewUpdates, rows: [Int]?)
}

open class AirPlayManager: NSObject, MPAVRoutingControllerDelegate {
    
    public var dataSourceArray = [MPAVRoute]()
    public weak var delegate: AirPlayManagerDelegate?
    
    public let routingController = MPAVRoutingController()
    public let audioDeviceController = MPAudioDeviceController()
    
    public override init() {
        super.init()
        audioDeviceController.routeDiscoveryEnabled = true
        routingController.delegate = self
        updateRoutes()
    }
    
    public func updateRoutes() {
        routingController.fetchAvailableRoutes { (routes) in
            if routes.count > self.dataSourceArray.count {
                var rows = [Int]()
                for index in self.dataSourceArray.count..<routes.count {
                    rows.append(index)
                }
                self.dataSourceArray = routes
                self.delegate?.updateTableView(dataSource: self.dataSourceArray, updateType: .insert, rows: rows)
            } else if routes.count < self.dataSourceArray.count {
                var rows = [Int]()
                for (index, route) in self.dataSourceArray.enumerated() {
                    if !routes.contains(where: { $0.routeUID == route.routeUID }) // If the new array doesn't contain an object in the old array it must have been removed
                    {
                        rows.append(index)
                    }
                }
                self.dataSourceArray = routes
                self.delegate?.updateTableView(dataSource: self.dataSourceArray, updateType: .delete, rows: rows)
            } else {
                self.dataSourceArray = routes
                self.delegate?.updateTableView(dataSource: self.dataSourceArray, updateType: .reload, rows: nil)
            }
        }
    }
    
    public func didSelectRoute(_ selectedRoute: MPAVRoute) {
        routingController.pick(selectedRoute)
    }
    
    // MARK: - MPAVRoutingControllerDelegate
    
    public func routingControllerAvailableRoutesDidChange(_ controller: MPAVRoutingController) {
        updateRoutes()
    }
    
    public func routingController(_ controller: MPAVRoutingController, pickedRouteDidChange newRoute: MPAVRoute) {
        updateRoutes()
    }
}
