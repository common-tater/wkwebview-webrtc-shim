//
//  ViewController.swift
//  WKWebViewWebRTCShimExample
//
//  Created by Jesse Tane on 7/9/15.
//  Copyright (c) 2015 Common Tater LLC. All rights reserved.
//

import UIKit
import WebKit

class ViewController: UIViewController, WKUIDelegate, WKNavigationDelegate {
  
  override func loadView() {
    var configuration = WKWebViewConfiguration()
    var controller = WKUserContentController()
    configuration.userContentController = controller
    
    var webView = WKWebView(frame: CGRectZero, configuration: configuration)
    
    // apply shim
    WKWebViewWebRTCShim(webView: webView, contentController: controller)
    
    var request = NSURLRequest(URL: NSURL(string:"http://localhost:7357/__zuul")!)
    webView.loadRequest(request)
    
    super.loadView()
    view.addSubview(webView)
    webView.frame = view.frame
  }
  
}
