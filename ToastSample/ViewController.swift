//
//  ViewController.swift
//  ToastSample
//
//  Created by Alvin George on 3/9/16.
//  Copyright © 2016 Alvin George. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

 override func viewDidLoad() {
  super.viewDidLoad()
  // Do any additional setup after loading the view, typically from a nib.
 }
 override func viewDidAppear(animated: Bool) {

  // basic usage
  self.view.makeToast("Sample Toast")

  // toast with a specific duration and position
  self.view.makeToast("Sample Toast", duration: 3.0, position: .Top)

  // toast with all possible options
  self.view.makeToast("Sample Toast", duration: 2.0, position: CGPoint(x: 110.0, y: 110.0), title: "Toast Title", image: UIImage(named: "ic_120x120.png"), style:nil) { (didTap: Bool) -> Void in
   if didTap {
    print("completion from tap")
   } else {
    print("completion without tap")
   }
  }

  //display toast with an activity spinner
  self.view.makeToastActivity(.Center)

  // display any view as toast
  let sampleView = UIView(frame: CGRectMake(100,100,200,200))
  sampleView.backgroundColor = UIColor(patternImage: UIImage(named: "ic_120x120")!)

  self.view.showToast(sampleView)
  self.view.showToast(sampleView, duration: 3.0, position: .Top, completion: nil)


  //Hide Toast
  self.view.hideToastActivity()


 }

 override func didReceiveMemoryWarning() {
  super.didReceiveMemoryWarning()
  // Dispose of any resources that can be recreated.
 }
 
 
}

