//
//  ViewController.swift
//  webrtc-webview-ios
//
//  Created by Jesse Tane on 3/13/15.
//  Copyright (c) 2015 Common Tater. All rights reserved.
//

import UIKit
import WebKit

class ViewController: UIViewController, WKScriptMessageHandler {
  
  var webView: WKWebView?
  
  override func loadView() {
    super.loadView()
    
    var contentController = WKUserContentController();
    
    var path = NSBundle.mainBundle().pathForResource("binding", ofType: "js")
    var bindingjs = String(contentsOfFile: path!, encoding: NSUTF8StringEncoding, error: nil)!
    
    var userScript = WKUserScript(
      source: bindingjs,
      injectionTime: WKUserScriptInjectionTime.AtDocumentStart,
      forMainFrameOnly: true
    )
    contentController.addUserScript(userScript)
    
    contentController.addScriptMessageHandler(
      self,
      name: "sync"
    )
    
    contentController.addScriptMessageHandler(
      self,
      name: "async"
    )
    
    var config = WKWebViewConfiguration()
    config.userContentController = contentController
    
    self.webView = WKWebView(
      frame: CGRectNull,
      configuration: config
    )
    
    self.view = self.webView!
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    var url = NSURL(string:"http://localhost:8080")
    var req = NSURLRequest(URL:url!)
    self.webView!.loadRequest(req)
  }
  
  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }
  
  func userContentController(userContentController: WKUserContentController, didReceiveScriptMessage message: WKScriptMessage) {
    
    var params = message.body as NSDictionary;
    
    switch (message.name) {
    case "sync":
      sync(webView!, params)
    case "async":
      async(webView!, params)
      break
    default:
      println("unrecognized method")
    }
  }
  
}

func sync (webView: WKWebView, params: NSDictionary) {
  var message = params.objectForKey("message") as String
  
  println("js called sync \(message)")
}

func async (webView: WKWebView, params: NSDictionary) {
  var message = params.objectForKey("message") as String
  var cbid = params.objectForKey("cbid") as NSString
  
  println("js called async \(message)")
  
  [webView.evaluateJavaScript("window._ios_webrtc_polyfill_callbacks['" + cbid + "'](new Error('bam'))", completionHandler: nil)]
}
