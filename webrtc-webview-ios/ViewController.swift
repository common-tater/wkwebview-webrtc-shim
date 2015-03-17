//
//  ViewController.swift
//  webrtc-webview-ios
//
//  Created by Jesse Tane on 3/13/15.
//  Copyright (c) 2015 Common Tater. All rights reserved.
//

import UIKit
import WebKit

class ViewController: UIViewController {

  var webView: WKWebView?

  override func loadView() {
    super.loadView()

    var contentController = WKUserContentController()
    var config = WKWebViewConfiguration()
    config.userContentController = contentController

    self.webView = WKWebView(frame: CGRectNull, configuration: config)
    self.view = self.webView!
    
    var webrtc = WKWebViewWebRTCPolyfill(webView: webView!, contentController: contentController)
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    var url = NSURL(string:"http://localhost:8080/listen/channels/-JjzTTFcz01JlWZWtrnU")
    var req = NSURLRequest(URL:url!)
    self.webView!.loadRequest(req)
  }

  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
  }

}
