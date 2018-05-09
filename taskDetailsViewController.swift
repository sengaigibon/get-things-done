//
//  taskDetailsViewController.swift
//  GetThingsDone
//
//  Created by Javier Caballero on 03/04/2018.
//  Copyright © 2018 Javier Caballero. All rights reserved.
//

import Cocoa
import SQLite

class taskDetailsViewController: NSViewController {

    //Db connection
    let filePath: URL
    let db: Connection
    let query: String
    
    var taskId = ""
    var period = ""
    
    //Action buttons and other elements
    @IBOutlet weak var btnSaveAndClose: NSButton!
    @IBOutlet weak var btnClose: NSButton!
    @IBOutlet weak var tvTasks: NSTableView!
    
    var _taskItem: Statement? = nil
    var _taskItemArr: [Any] = []
    
    required init?(coder lol: NSCoder) {
        filePath = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false).appendingPathComponent("GetThingsDone/tasks.sqlite");
        db = try! Connection(filePath.absoluteString)
        query = "select tt.taskId as taskId, t.title as title, tt.start as begin, tt.stop as end, tt.total as total from tasks t join taskTracker tt on tt.taskId = t.taskId"
        
        super.init(coder: lol)
    }
    
    override func viewDidLoad() {
        
        do {
            _taskItem = try db.run(query + period + " and t.taskId = \(taskId)")
        } catch {
            print("error getting tasks")
        }
        
        for row in _taskItem! {
            
            if let row3 = row[3] {
                _taskItemArr.append([row[0], row[1], row[2], row3, row[4]])
            } else {
                _taskItemArr.append([row[0], row[1], row[2], "-", row[4]])
            }
            
        }
        
        tvTasks.delegate = self
        tvTasks.dataSource = self
        
        super.viewDidLoad()
    }
    
    @IBAction func actionSaveAndClose(_ sender: Any) {
        print("saved")
        super.dismiss(sender)
    }
}


extension taskDetailsViewController: NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return _taskItemArr.count
    }
}

extension taskDetailsViewController: NSTableViewDelegate {
    
    fileprivate enum CellIdentifiers {
        static let taskCell = "TaskCell"
        static let beginsCell = "BeginsCell"
        static let endsCell = "EndsCell"
        static let durationCell = "DurationCell"
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        
        var content: String = ""
        var cellIdentifier: String = ""
        
        let item = _taskItemArr[row] as? [Any]
        
        if tableColumn == tableView.tableColumns[0] {
            content = item![1] as! String
            cellIdentifier = CellIdentifiers.taskCell
            
        } else if tableColumn == tableView.tableColumns[1] {
            content = item![2] as! String
            cellIdentifier = CellIdentifiers.beginsCell
            
        } else if tableColumn == tableView.tableColumns[2] {
            
            content = item![3] as! String
            cellIdentifier = CellIdentifiers.endsCell
            
        } else if tableColumn == tableView.tableColumns[3] {
            
            let tempTotal = item![4] as! Int64
            content = String(format: "%.3f", Float(String(describing: tempTotal))! / 3600)
            
//            if let tempTotal = item![4] {
//                content = String(format: "%.3f", Float(String(describing: tempTotal))! / 3600)
//            } else {
//                content = "-"
//            }
            
            cellIdentifier = CellIdentifiers.durationCell
        }
        
        if let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: cellIdentifier), owner: nil) as? NSTableCellView {
            cell.textField?.stringValue = content
            return cell
        }
        return nil
        
    }
}
