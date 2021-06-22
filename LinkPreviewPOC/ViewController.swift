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
    private var linkView = LPLinkView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        self.view.addSubview(linkView)
        linkView.isHidden = true
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        linkView.frame = CGRect(x: 0, y: 350, width: self.view.frame.size.width, height: 200)
    }
    
    
    @IBAction func getUrlPreview(_ sender: Any) {
        let metadataProvider = LPMetadataProvider()
        guard var urlStr = urlTextField.text, urlStr.isValidURL else {
            print("Invalid URL inserted in TextField")
            return
        }
        if !urlStr.contains("http") || !urlStr.contains("https") {
            urlStr = "https://" + urlStr
        }
        let url = URL(string: urlStr)! //"https://developer.apple.com/documentation/linkpresentation/lplinkmetadata"
        metadataProvider.startFetchingMetadata(for: url) { metadata, error in
            if error != nil {
                print("Error occurred while fetching metadata from url - \(String(describing: error?.localizedDescription))")
                return
            }
            // self.linkView = LPLinkView(url: url)
            guard let metadataOfUrl: LPLinkMetadata = metadata else {
                return
            }
            
            print("Link Title - \(metadataOfUrl.title ?? "title missing")")
            if let originalUrl = metadataOfUrl.originalURL {
                print("Link URL - \(originalUrl.absoluteString)")
            }
            
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.linkView.metadata = metadataOfUrl
                self.linkView.isHidden = false
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
