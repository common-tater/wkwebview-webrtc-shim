//
//  ViewController.swift
//  WKWebViewWebRTCShimTest
//
//  Created by Jesse Tane on 7/8/15.
//  Copyright (c) 2015 Common Tater LLC. All rights reserved.
//

import UIKit
import WebKit

class ViewController: UIViewController, WKUIDelegate, WKNavigationDelegate {

  var webViewConfiguration: WKWebViewConfiguration?
  var webView: WKWebView?

  override func loadView() {
    super.loadView()
    
    var controller = WKUserContentController()
    webViewConfiguration = WKWebViewConfiguration()
    webViewConfiguration!.userContentController = controller
    
    webView = WKWebView(frame: CGRectZero, configuration: webViewConfiguration!)
    webView!.frame = view.frame

    WKWebViewWebRTCShim(webView: webView!, contentController: controller)
    
    var request = NSURLRequest(URL: NSURL(string:"http://localhost:7357/__zuul")!)
    webView!.loadRequest(request)
    
    view.addSubview(webView!)
  }

  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }


}

