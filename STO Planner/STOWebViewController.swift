//
// Created by Maarten Billemont on 2015-09-28.
// Copyright (c) 2015 Maarten Billemont. All rights reserved.
//

import UIKit

class STOWebViewController: UIViewController, UIWebViewDelegate {
    @IBInspectable var initialURL: String?
    @IBOutlet var      webView:    UIWebView!

    override func viewDidLoad() {
        super.viewDidLoad()

        if let initialURLString = initialURL, let url = NSURL( string: initialURLString ) {
            webView.loadRequest( NSURLRequest( URL: url ) )
        }
    }

    func webView(webView: UIWebView, didFailLoadWithError error: NSError?) {
        NSLog("error: %@", error!)
    }

    func webViewDidFinishLoad(webView: UIWebView) {
        NSLog( "finishLoad" )
    }

    func webViewDidStartLoad(webView: UIWebView) {
        NSLog( "startLoad" )
    }

    func webView(webView: UIWebView, shouldStartLoadWithRequest request: NSURLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        NSLog( "shouldStartLoadWithRequest: %@", request )
        return true
    }

    @IBAction func close(sender: UIBarButtonItem) {
        navigationController?.dismissViewControllerAnimated( true, completion: nil );
    }
}
