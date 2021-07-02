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

    @IBOutlet weak var urlLabel: UILabel!
    @IBOutlet weak var urlTextField: UITextField!
    @IBOutlet weak var fetchPreviewBtn: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
    }
    
    
    @IBAction func getUrlPreview(_ sender: Any) {
        if let urlStr = urlTextField.text {
            var holderView = UIView(frame:CGRect.zero)
            holderView.frame = CGRect(x: 0, y: 350, width: self.view.frame.size.width, height: 100)
            holderView = self.view.addURLPreview(urlString: urlStr, frames: holderView.frame)
            holderView.backgroundColor = .clear
            self.view.addSubview(holderView)
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
    
    func addURLPreview(urlString: String, frames: CGRect) -> UIView {
        var urlStr = urlString
        let holderView = UIView(frame:CGRect.zero)
        holderView.backgroundColor = .clear
        
        let linkView = LPLinkView()
        linkView.frame = .zero
        let metadataProvider = LPMetadataProvider()
        guard !urlStr.isEmpty, urlStr.isValidURL else {
            //print("Invalid URL inserted in TextField")
            let alert = UIAlertController(title: "Error", message: "Invalid link entered in text box.", preferredStyle: UIAlertController.Style.alert)
            alert.addAction(UIAlertAction(title: "Click", style: .default, handler: nil))
            self.window?.rootViewController?.present(alert, animated: true, completion: {})
            return holderView
        }
        holderView.frame = frames
        linkView.frame = holderView.bounds
        holderView.addSubview(linkView)
        if !urlStr.lowercased().contains("http") && !urlStr.lowercased().contains("https") {
            urlStr = "https://" + urlStr
        }
        let url = URL(string: urlStr)! //"https://developer.apple.com/documentation/linkpresentation/lplinkmetadata"
        metadataProvider.startFetchingMetadata(for: url) { metadata, error in
            if error != nil {
                self.errorHandling(linkView: linkView, url: url, error: error!)
                return
            }
            guard let metadataOfUrl: LPLinkMetadata = metadata else {
                return
            }
            
            print("Link Title - \(metadataOfUrl.title ?? "title missing")")
            if let originalUrl = metadataOfUrl.originalURL {
                print("Link URL - \(originalUrl.absoluteString)")
            }
            
            DispatchQueue.main.async { [weak self] in
                guard self != nil else { return }
                linkView.metadata = metadataOfUrl
            }
        }
        return holderView
    }
    
    func errorHandling(linkView: LPLinkView, url: URL, error: Error?) {
        let errorHandlingMetadata = LPLinkMetadata()
        errorHandlingMetadata.title = "Unable to fetch meta data"
        errorHandlingMetadata.url = url
        errorHandlingMetadata.iconProvider = NSItemProvider.init(contentsOf: URL(fileURLWithPath: Bundle.main.path(forResource: "error", ofType: "png")!))
        linkView.metadata = errorHandlingMetadata
        if let currentError = error {
            print("Error occurred while fetching metadata from url - \(String(describing: currentError.localizedDescription))")
        }
    }
}
