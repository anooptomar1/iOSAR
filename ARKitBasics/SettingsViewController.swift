//
//  SettingsViewController.swift
//  ARKitBasics
//
//  Created by Abhinav Prakash on 16/11/17.
//  Copyright © 2017 Apple. All rights reserved.
//

import UIKit

class SettingsViewController: UITableViewController {
    
    @IBOutlet weak var autoset: UISwitch!
    
    @IBAction func setAutoMode(_ sender: UISwitch) {
        Settings.sharedInstance.autoPlay = autoset.isOn
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
