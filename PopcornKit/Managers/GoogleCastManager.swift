
#if os(iOS)
    
    import Foundation
    import GoogleCast
    
    public typealias CastMetaData = (title: String, image: URL?, contentType: String, subtitles: [Subtitle]?, url: String, mediaAssetsPath: URL, startPosition: TimeInterval)
    
    public protocol GoogleCastManagerDelegate: AirPlayManagerDelegate {
        func didConnectToDevice()
    }
    
    open class GoogleCastManager: NSObject, GCKDeviceScannerListener, GCKSessionManagerListener {
        
        public var dataSource = [GCKDevice]()
        public weak var delegate: GoogleCastManagerDelegate?
        
        public var deviceScanner = GCKDeviceScanner(filterCriteria: GCKFilterCriteria(forAvailableApplicationWithID: kGCKMediaDefaultReceiverApplicationID))
        
        /// If a user is connected to a device and wants to connect to another, a queue has to be made as the disconnect operation is asyncronous. When the user has successfully disconnected from the first device, this device should then be connected to.
        private var deviceAwaitingConnection: GCKDevice?
        public var castMetadata: CastMetaData?
        
        public override init() {
            super.init()
            deviceScanner.add(self)
            deviceScanner.startScan()
            GCKCastContext.sharedInstance().sessionManager.add(self)
        }
        
        /// If you chose to initialise with this method, no delegate requests will be recieved.
        public init(castMetadata: CastMetaData) {
            super.init()
            self.castMetadata = castMetadata
        }
        
        public func didSelectDevice(_ device: GCKDevice, castMetadata: CastMetaData? = nil) {
            self.castMetadata = castMetadata
            if let session = GCKCastContext.sharedInstance().sessionManager.currentSession {
                GCKCastContext.sharedInstance().sessionManager.endSession()
                if session.device != device {
                    deviceAwaitingConnection = device
                }
            } else {
                GCKCastContext.sharedInstance().sessionManager.startSession(with: device)
            }
        }
        
        // MARK: - GCKDeviceScannerListener
        
        public func deviceDidComeOnline(_ device: GCKDevice) {
            dataSource.append(device)
            delegate?.updateTableView(dataSource: dataSource, updateType: .insert, rows: [dataSource.count - 1])
        }
        
        
        public func deviceDidGoOffline(_ device: GCKDevice) {
            for (index, oldDevice) in dataSource.enumerated() where device === oldDevice {
                dataSource.remove(at: index)
                delegate?.updateTableView(dataSource: dataSource, updateType: .delete, rows: [index])
            }
        }
        
        public func deviceDidChange(_ device: GCKDevice) {
            for (index, oldDevice) in dataSource.enumerated() where device === oldDevice  {
                dataSource[index] = device
                delegate?.updateTableView(dataSource: dataSource, updateType: .reload, rows: [index])
            }
        }
        
        // MARK: - GCKSessionManagerListener
        
        public func sessionManager(_ sessionManager: GCKSessionManager, didEnd session: GCKSession, withError error: Error?) {
            guard error == nil else { return }
            if let device = deviceAwaitingConnection {
                GCKCastContext.sharedInstance().sessionManager.startSession(with: device)
            } else {
                delegate?.didConnectToDevice()
            }
        }
        
        public func sessionManager(_ sessionManager: GCKSessionManager, didStart session: GCKSession) {
            if let castMetadata = castMetadata {
                streamToDevice(sessionManager: sessionManager, castMetadata: castMetadata)
                delegate?.didConnectToDevice()
            } else {
                delegate?.didConnectToDevice()
            }
        }
        
        public func streamToDevice(_ mediaTrack: [GCKMediaTrack]? = nil, sessionManager: GCKSessionManager, castMetadata: CastMetaData) {
            let metadata = GCKMediaMetadata(metadataType: .movie)
            metadata.setString(castMetadata.title, forKey: kGCKMetadataKeyTitle)
            if let url = castMetadata.image {
                metadata.addImage(GCKImage(url: url, width: 480, height: 720))
            }
            let mediaInfo = GCKMediaInformation(contentID: castMetadata.url, streamType: .buffered, contentType: castMetadata.contentType, metadata: metadata, streamDuration: 0, mediaTracks: nil, textTrackStyle: GCKMediaTextTrackStyle.createDefault(), customData: nil)
            sessionManager.currentCastSession?.remoteMediaClient?.loadMedia(mediaInfo, autoplay: true, playPosition: castMetadata.startPosition)
        }
        
        
        deinit {
            if deviceScanner.scanning {
                deviceScanner.stopScan()
                deviceScanner.remove(self)
                GCKCastContext.sharedInstance().sessionManager.remove(self)
            }
            deviceAwaitingConnection = nil
            castMetadata = nil
        }
        
    }
    
    public func == (left: GCKDevice, right: GCKDevice) -> Bool {
        return left.deviceID == right.deviceID && left.uniqueID == right.uniqueID
    }
    
    public func != (left: GCKDevice, right: GCKDevice) -> Bool {
        return left.deviceID != right.deviceID && left.uniqueID != right.uniqueID
    }
    
#endif
