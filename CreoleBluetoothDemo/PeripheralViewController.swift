//
//  PeripheralViewController.swift
//  CreoleBluetoothDemo
//
//  Created by Creole on 6/27/17.
//  Copyright © 2017 CreoleStudios. All rights reserved.
//

import UIKit
import CoreBluetooth

class PeripheralViewController: UIViewController,CBPeripheralManagerDelegate {
    
    @IBOutlet weak var txtData: UITextView!
    var peripheralManager: CBPeripheralManager?
    var transferCharacteristic: CBMutableCharacteristic?
    var transferCharacteristicRead : CBMutableCharacteristic?
    var transferCharacteristicWrite : CBMutableCharacteristic?
    
    var dataToSend: Data?
    var sendDataIndex: Int?
    var sendingEOM = false
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.rightBarButtonItem = UIBarButtonItem.init(title: "Send", style: .plain, target: self, action: #selector(self.rightSideMenuButtonPressed))
        
        // Start up the CBPeripheralManager
        peripheralManager = CBPeripheralManager(delegate: self, queue: nil)//step2
        
        // Do any additional setup after loading the view.
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        // Don't keep it going while we're not showing.
        peripheralManager?.stopAdvertising()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: - Button action -
    
    func rightSideMenuButtonPressed() {
        let strSend = generateRandomStringWithLength(length: 24)
        
        dataToSend = strSend.data(using: String.Encoding.utf8)
        
        // Reset the index
        sendDataIndex = 0;
        
        sendData()
    }
    
    //MARK: - Peripheral delegate
    
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        if (peripheral.state == .poweredOn) {
            print("self.peripheralManager powered on.")
            
            // Start with the CBMutableCharacteristic
            transferCharacteristic = CBMutableCharacteristic(
                type: characteristicUUID,
                properties: CBCharacteristicProperties.notify,
                value: nil,
                permissions: CBAttributePermissions.readable
            )
            
            transferCharacteristicRead = CBMutableCharacteristic(
                type: characteristicUUID,
                properties: CBCharacteristicProperties.write,
                value: nil,
                permissions: CBAttributePermissions.writeable
            )
            
            // Then the service
            let transferService = CBMutableService(
                type: serviceUUID,
                primary: true
            )
            
            // Add the characteristic to the service
            transferService.characteristics = [transferCharacteristic! , transferCharacteristicRead!]
            
            // And add it to the peripheral manager
            peripheralManager!.add(transferService)
            
            peripheralManager!.startAdvertising([
                CBAdvertisementDataServiceUUIDsKey : [serviceUUID]
                ])
            
        }
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didSubscribeTo characteristic: CBCharacteristic) {
        self.txtData.text = "You are connected..."
        print("Central subscribed to characteristic")
    }
    
    
    func peripheralManagerIsReady(toUpdateSubscribers peripheral: CBPeripheralManager) {
        // Start sending again
        sendData()
    }
    
    func peripheralManagerDidStartAdvertising(_ peripheral: CBPeripheralManager, error: Error?) {
        print(error ?? "UNKNOWN ERROR")
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveWrite requests: [CBATTRequest]) {
        print("peripheral didReceiveWrite" + String(data: requests[0].value!, encoding: String.Encoding.utf8)!)
        
        self.txtData.text = self.txtData.text + "\n" + "\(String(data: requests[0].value!, encoding: String.Encoding.utf8)!)"

        self.peripheralManager?.respond(to: requests[0], withResult: .success)
    }
    
    
    //MARK: - Other function -
    
    func sendData() {
        
        if sendingEOM {
            // send it
            let didSend = peripheralManager?.updateValue(
                "EOM".data(using: String.Encoding.utf8)!,
                for: transferCharacteristic!,
                onSubscribedCentrals: nil
            )
            
            // Did it send?
            if (didSend == true) {
                
                // It did, so mark it as sent
                sendingEOM = false
                
                print("Sent: EOM")
            }
            
            // It didn't send, so we'll exit and wait for peripheralManagerIsReadyToUpdateSubscribers to call sendData again
            return
        }
        
        // We're not sending an EOM, so we're sending data
        
        // Is there any left to send?
        guard sendDataIndex! < (dataToSend?.count)! else {
            // No data left.  Do nothing
            return
        }
        var didSend = true
        
        while didSend {
            var amountToSend = dataToSend!.count - sendDataIndex!;
            
            if (amountToSend > NOTIFY_RSS) {
                amountToSend = NOTIFY_RSS;
            }
            
            // Copy out the data we want
            let chunk = dataToSend!.withUnsafeBytes{(body: UnsafePointer<UInt8>) in
                return Data(
                    bytes: body + sendDataIndex!,
                    count: amountToSend
                )
            }
            
            // Send it
            didSend = peripheralManager!.updateValue(
                chunk as Data,
                for: transferCharacteristic!,
                onSubscribedCentrals: nil
            )
            
            if (!didSend) {
                return
            }
            
            let stringFromData = NSString(
                data: chunk as Data,
                encoding: String.Encoding.utf8.rawValue
            )
            
            print("Sent: \(String(describing: stringFromData))")
            
            sendDataIndex! += amountToSend;
            
            if (sendDataIndex! >= dataToSend!.count) {
                sendingEOM = true
                
                // Send it
                let eomSent = peripheralManager!.updateValue(
                    "EOM".data(using: String.Encoding.utf8)!,
                    for: transferCharacteristic!,
                    onSubscribedCentrals: nil
                )
                
                if (eomSent) {
                    // It sent, we're all done
                    sendingEOM = false
                    print("Sent: EOM")
                }
                
                return
            }
        }
    }
    
    
    func generateRandomStringWithLength(length:Int) -> String {
        
        let randomString:NSMutableString = NSMutableString(capacity: length)
        
        let letters:NSMutableString = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        
        var i: Int = 0
        
        while i < length {
            
            let randomIndex:Int = Int(arc4random_uniform(UInt32(letters.length)))
            
            randomString.append("\(Character( UnicodeScalar( letters.character(at: randomIndex))!))")
            i += 1
        }
        
        return String(randomString)
    }
    
    
}
