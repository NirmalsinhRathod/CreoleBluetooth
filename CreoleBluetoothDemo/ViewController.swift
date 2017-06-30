//
//  ViewController.swift
//  CreoleBluetoothDemo
//
//  Created by Creole on 6/27/17.
//  Copyright © 2017 CreoleStudios. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

  override func viewDidLoad() {
    super.viewDidLoad()
    
   
    
    // Do any additional setup after loading the view, typically from a nib.
  }

  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }

  @IBAction func btnCentralClicked(_ sender: UIButton) {
    let centralVC = self.storyboard?.instantiateViewController(withIdentifier: "CentralViewController") as! CentralViewController
    self.navigationController?.pushViewController(centralVC, animated: true)
  }

  @IBAction func btnPeripheralClicked(_ sender: UIButton) {
    
    let peripheralVC = self.storyboard?.instantiateViewController(withIdentifier: "PeripheralViewController") as! PeripheralViewController
    self.navigationController?.pushViewController(peripheralVC, animated: true)
    
  }
  
 
}

