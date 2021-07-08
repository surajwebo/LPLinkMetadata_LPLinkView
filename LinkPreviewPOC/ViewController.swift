//
//  ViewController.swift
//  LinkPreviewPOC
//
//  Created by Suraj M on 21/06/21.
//

import UIKit
import LinkPresentation
import MobileCoreServices

class ViewController: UIViewController {
    @IBOutlet weak var holderStackView: UIStackView!
    @IBOutlet weak var urlLabel: UILabel!
    @IBOutlet weak var urlTextField: UITextField!
    @IBOutlet weak var fetchBtn: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        fetchBtn.layer.cornerRadius = 5
        fetchBtn.layer.borderColor = UIColor.darkGray.cgColor
        fetchBtn.layer.borderWidth = 1
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
    }
    
    
    @IBAction func getUrlPreview(_ sender: Any) {
        if let urlStr = urlTextField.text {
            let holderViewFrame = CGRect(x: 20, y: holderStackView.frame.maxY+20, width: UIScreen.main.bounds.size.width-40, height: UIScreen.main.bounds.height-(holderStackView.frame.maxY+100))
            let holderView = UIView.addURLPreview(urlString: urlStr, frames: holderViewFrame, parentController: self)
            if let holderView = holderView {
                holderView.backgroundColor = .clear
                self.view.addSubview(holderView)
            }
        }
    }
}

extension String {
    var isValidURL: Bool {
        let detector = try! NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
        if let match = detector.firstMatch(in: self, options: [], range: NSRange(location: 0, length: self.utf16.count)) {
            // it is a link, if the match covers the whole string
            return match.range.length == self.utf16.count
        } else {
            return false
        }
    }
}

extension UIView {
    
    @available(iOS 13.0, *)
    
    static func addURLPreview(urlString: String, frames: CGRect, parentController: UIViewController) -> UIView? {
        var urlStr = urlString
        let holderView = UIView(frame:CGRect.zero)
        holderView.backgroundColor = .clear
        holderView.layer.cornerRadius = 20
        holderView.layer.borderWidth = 1
        holderView.layer.borderColor = UIColor.brown.cgColor
        holderView.layer.masksToBounds = true
        
        let linkView = LPLinkView()
        linkView.frame = .zero
        let metadataProvider = LPMetadataProvider()
        guard !urlStr.isEmpty, urlStr.isValidURL else {
            let alert = UIAlertController(title: "Error", message: "Invalid link entered in text box.", preferredStyle: UIAlertController.Style.alert)
            alert.addAction(UIAlertAction(title: "Click", style: .default, handler: nil))
            parentController.present(alert, animated: true, completion: {})
            return holderView
        }
        holderView.frame = frames
        linkView.frame = holderView.bounds
        holderView.addSubview(linkView)
        
        let activityView = UIActivityIndicatorView(style: UIActivityIndicatorView.Style.medium)
        activityView.color = .black
        activityView.hidesWhenStopped = true
        holderView.addSubview(activityView)
        activityView.translatesAutoresizingMaskIntoConstraints = false
        activityView.centerXAnchor.constraint(equalTo: holderView.centerXAnchor).isActive = true
        activityView.centerYAnchor.constraint(equalTo: holderView.centerYAnchor).isActive = true
        activityView.startAnimating()
        
        if !urlStr.lowercased().contains("http") && !urlStr.lowercased().contains("https") {
            urlStr = "https://" + urlStr
        }
        let url = URL(string: urlStr)! //"https://developer.apple.com/documentation/linkpresentation/lplinkmetadata"
        if let cachedMetadata = StoreMetadataLocally.sharedInstance.getMetadataFor(url: url) {
            linkView.metadata = cachedMetadata
            DispatchQueue.main.async {
                activityView.stopAnimating()
                linkView.isHidden = false
            }
            return holderView
        } else {
            metadataProvider.startFetchingMetadata(for: url) { metadata, error in
                DispatchQueue.main.async {
                    activityView.stopAnimating()
                }
                if error != nil {
                    let errorHandlingMetadata = LPLinkMetadata()
                    errorHandlingMetadata.title = "Unable to fetch meta data"
                    errorHandlingMetadata.url = url
                    errorHandlingMetadata.iconProvider = NSItemProvider.init(contentsOf: URL(fileURLWithPath: Bundle.main.path(forResource: "error", ofType: "png")!))
                    linkView.metadata = errorHandlingMetadata
                    linkView.isHidden = false
                    if let currentError = error {
                        print("Error occurred while fetching metadata from url - \(String(describing: currentError.localizedDescription))")
                    }
                    return
                }
                guard let metadataOfUrl: LPLinkMetadata = metadata else {
                    return
                }
                DispatchQueue.main.async {
                    linkView.metadata = metadataOfUrl
                    linkView.isHidden = false
                    StoreMetadataLocally.sharedInstance.addToMetadataCache(url: url, metaData: metadataOfUrl)
                }
            }
            return holderView
        }
    }
}

@available(iOS 13.0, *)
@objcMembers
class StoreMetadataLocally: NSObject {
    private var enableMetadataCache: Bool = true // Flag to Enable/Disable the Metadata caching
    static let sharedInstance: StoreMetadataLocally = { return StoreMetadataLocally() }()
    var metaDataDict = [URL:LPLinkMetadata]()
    
    func addToMetadataCache(url: URL, metaData: LPLinkMetadata) { // Add new Metadata entries
        if enableMetadataCache, metaDataDict[url] == nil {
            metaDataDict[url] = metaData
        } else {
            metaDataDict.updateValue(metaData, forKey: url)
        }
    }
    
    func getMetadataFor(url: URL) -> LPLinkMetadata? { // Get Metadata of specific URL
        if let metaData = metaDataDict[url] {
            return enableMetadataCache ? metaData : nil
        }
        return nil
    }
    
    func removeMetadataFor(url: URL) { // Remove Metadata for specific URL
        metaDataDict.removeValue(forKey: url)
    }
    
    func flushMetadataCache() { // Clear all Metadata
        metaDataDict.removeAll()
    }
}
