//
//  ViewController.swift
//  TestSpreadSheetView
//
//  Created by Yuan on 2023/7/17.
//

import UIKit

class ViewController: UIViewController {
    
    private var spreadsheetVC: SpreadsheetViewController = .init(nibName: nil, bundle: nil)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        // Change vc to spreadsheetVC
        view.addSubview(spreadsheetVC.view)
        addChild(spreadsheetVC)
        spreadsheetVC.didMove(toParent: self)        
    }
    
    
}

