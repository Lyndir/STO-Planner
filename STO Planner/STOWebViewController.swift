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
        err( "didFailLoadWithError: %@", error?.fullDescription() )
    }

    func webViewDidFinishLoad(webView: UIWebView) {
        dbg( "finishLoad" )
    }

    func webViewDidStartLoad(webView: UIWebView) {
        dbg( "startLoad" )
    }

    func webView(webView: UIWebView, shouldStartLoadWithRequest request: NSURLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        dbg( "shouldStartLoadWithRequest: %@, navigationType: %d", request, navigationType.rawValue )
        return true
    }

    @IBAction func close(sender: UIBarButtonItem) {
        navigationController?.dismissViewControllerAnimated( true, completion: nil );
    }
}
