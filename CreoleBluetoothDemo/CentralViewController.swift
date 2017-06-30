//
//  CentralViewController.swift
//  CreoleBluetoothDemo
//
//  Created by Creole on 6/27/17.
//  Copyright © 2017 CreoleStudios. All rights reserved.
//

import UIKit
import CoreBluetooth


class CentralViewController: UIViewController,CBCentralManagerDelegate, CBPeripheralDelegate{//,UITableViewDelegate,UITableViewDataSource {
    
    @IBOutlet weak var txtSendData: UITextView!
    var centralManager: CBCentralManager?
    var discoveredPeripheral: CBPeripheral?
    
    
    var connectedCBCharacteristic : CBCharacteristic?
    
    let data = NSMutableData()//store incoming data
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.rightBarButtonItem = UIBarButtonItem.init(title: "Send", style: .plain, target: self, action: #selector(self.rightSideMenuButtonPressed))
        
        //configure central manager
        centralManager = CBCentralManager.init(delegate: self, queue: nil)
        
        // Do any additional setup after loading the view.
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        print("Stopping scan")
        
        centralManager?.stopScan()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: - central manager Delegates
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn{
            scan()//start scanning
        }
    }
    
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        print("Discovered \(String(describing: peripheral.name)) at \(RSSI)")
        
        if self.discoveredPeripheral != peripheral{
            self.discoveredPeripheral = peripheral
            
            print("Connecting to peripheral \(peripheral)")
            
            //now connect with
            self.centralManager?.connect(peripheral, options: nil)
        }
        
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print("Failed to connect to \(peripheral). (\(error!.localizedDescription))")
        
        cleanup()
    }
    
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("Peripheral Connected")
        
        centralManager?.stopScan()
        
        print("Scanning stopped")
        
        data.length = 0
        
        peripheral.delegate = self
        //search our transfer service uuid
        peripheral.discoverServices([serviceUUID])
        
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if error == nil{
            
            for service in peripheral.services!{
                peripheral.discoverCharacteristics([characteristicUUID], for: service)
            }
            
        }else{
            cleanup()
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if error == nil{
            for characteristic  in service.characteristics!{
                if characteristic.uuid.isEqual(characteristicUUID){
                    connectedCBCharacteristic = characteristic
                    peripheral.setNotifyValue(true, for: characteristic)
                }
                
            }
            
        }else{
            cleanup()
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if error == nil{
            
            if let stringFromData = NSString(data: characteristic.value!, encoding: String.Encoding.utf8.rawValue){
                if stringFromData.isEqual(to: "EOM") {
                    
                    peripheral.setNotifyValue(false, for: characteristic)
                    
                    centralManager?.cancelPeripheralConnection(peripheral)
                    
                }else{
                    print("Received: \(stringFromData)")
                    self.txtSendData.text = self.txtSendData.text + "\n" + (stringFromData as String)
                }
            }
            
        }else{
            print("Error discovering services: \(error!.localizedDescription)")
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        print("Error changing notification state: \(String(describing: error?.localizedDescription))")
        
        if characteristic.uuid != characteristicUUID{
            if (characteristic.isNotifying) {
                print("Notification began on \(characteristic)")
            } else { // Notification has stopped
                print("Notification stopped on (\(characteristic))  Disconnecting")
                centralManager?.cancelPeripheralConnection(peripheral)
            }
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("Peripheral Disconnected")
        discoveredPeripheral = nil
        
        // We're disconnected, so start scanning again
        scan()
    }
    
    //MARK: - Other functions
    
    func scan() {
        
        centralManager?.scanForPeripherals(withServices: [serviceUUID], options: [CBCentralManagerScanOptionAllowDuplicatesKey : NSNumber.init(value: true)])
        
        print("Scanning started")
    }
    
    func cleanup(){
        if self.discoveredPeripheral?.state == .connected{
            if let services = discoveredPeripheral?.services{
                for service in services{
                    for characteristic in service.characteristics!{
                        if characteristic.uuid.isEqual(characteristicUUID) && characteristic.isNotifying{
                            self.discoveredPeripheral?.setNotifyValue(false, for: characteristic)
                            return
                        }
                    }
                }
            }else{
                centralManager?.cancelPeripheralConnection(discoveredPeripheral!)
                return
            }
        }else{
            return
        }
    }
    
    func rightSideMenuButtonPressed() {
        sendMessage()
    }
    
    
    
    
    //MARK: - TableView Delegate -
    
    //    func numberOfSections(in tableView: UITableView) -> Int {
    //        return 1
    //    }
    //
    //    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    //        return 10
    //    }
    //
    //    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    //        var cell = tableView.dequeueReusableCell(withIdentifier: "cell")
    //        if cell == nil{
    //            cell = UITableViewCell.init(style: .default, reuseIdentifier: "cell")
    //        }
    //        cell?.textLabel?.text = "Device Info"
    //        return cell!
    //    }
    //
    //    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    //        return 40
    //    }
    //
    //
    //    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    //
    //        sendMessage()
    //    }
    
    func sendMessage(){
        let input = "Hello World"
        let data = input.data(using: .utf8)!
        discoveredPeripheral?.writeValue(data, for: connectedCBCharacteristic!, type: CBCharacteristicWriteType.withResponse)
    }
    
    
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destinationViewController.
     // Pass the selected object to the new view controller.
     }
     */
    
}
