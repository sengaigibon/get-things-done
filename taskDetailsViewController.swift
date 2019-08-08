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
    
    //DB table
    let _taskTracker = Table("taskTracker")
    
    //Expressions for taskTracker table
    let _trackId = Expression<Int64?>("trackId")
    let _taskId = Expression<Int64>("taskId")
    let _start = Expression<String?>("start")
    let _stop = Expression<String?>("stop")
    let _total = Expression<Int?>("total")
    
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
        query = "select tt.taskId as taskId, t.title as title, tt.start as begin, tt.stop as end, tt.total as total, tt.trackId from tasks t join taskTracker tt on tt.taskId = t.taskId"
        
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
                _taskItemArr.append([row[0], row[1], row[2], row3, row[4], row[5]])
            } else {
                _taskItemArr.append([row[0], row[1], row[2], "-", row[4], row[5]])
            }
            
        }
        
        tvTasks.delegate = self
        tvTasks.dataSource = self
        print("start")
        super.viewDidLoad()
    }
    
    @IBAction func doSomething(_ sender: NSTextField) {
        print("permofrming something: " + (sender.stringValue))
    }
    
    
    @IBAction func change(_ sender: NSTextField) {
        //let typee = type(of: sender)
        print(sender.stringValue)
    }
    
    func textDidEndEditing(notification: NSNotification) {
        
        //guard let editor = notification.object as? NSTextView else { return }
        print("happening")
        // ...
    }
    
    @IBAction func actionSaveAndClose(_ sender: Any) {
        //print("saved")
        
        //var record: [Any] = []
        var i = 0;
        var startOriginal = ""
        var stopOriginal = ""
        var startModified = ""
        var stopModified = ""
        var shouldBeUpdated: Bool;
        
        let formatter = DateFormatter()
        
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        
//        for i in 0..<tvTasks.numberOfRows {
//            let data = tvTasks.view(atColumn: 2, row: i, makeIfNecessary: true)
//            print(data?.viewWithTag(0)?.value(at: 0))
//        }
        
//        for row in tvTasks.rowView(atRow: <#T##Int#>, makeIfNecessary: <#T##Bool#>) {
//
//        }
        
//        for record in _taskItem! {
//            let itemMod = tvTasks.rows
//
//            startOriginal = (record[2] as? String)!
//            if let row3 = record[3] {
//                stopOriginal = (row3 as? String)!
//            } else {
//                stopOriginal = "-"
//            }
//            startModified = (itemMod![2] as? String)!
//            stopModified = (itemMod![3] as? String)!
////            checkEquality = stopModified != "-"
//
//            shouldBeUpdated = startOriginal != startModified && stopOriginal != stopModified
//
//            if shouldBeUpdated {
//                let totalTime = Calendar.current.dateComponents([.second], from: formatter.date(from: startModified)!, to: formatter.date(from: stopModified)!).second
//
//                let updateTaskTracker = _taskTracker.filter(_trackId == (record[5] as! Int64))
//
//                do {
//                    try db.run(updateTaskTracker.update([_start <- startModified, _stop <- stopModified, _total <- totalTime]))
//                } catch {
//                    print("error updating task: \(error)")
//                }
//            } else if startOriginal != startModified {
//                let totalTime = Calendar.current.dateComponents([.second], from: formatter.date(from: startModified)!, to: formatter.date(from: stopOriginal)!).second
//
//                let updateTaskTracker = _taskTracker.filter(_trackId == (record[5] as! Int64))
//
//                do {
//                    try db.run(updateTaskTracker.update([_start <- startModified, _total <- totalTime]))
//                } catch {
//                    print("error updating task: \(error)")
//                }
//            } else if (stopOriginal != stopModified) {
//                let totalTime = Calendar.current.dateComponents([.second], from: formatter.date(from: startOriginal)!, to: formatter.date(from: stopModified)!).second
//
//                let updateTaskTracker = _taskTracker.filter(_trackId == (record[5] as! Int64))
//
//                do {
//                    try db.run(updateTaskTracker.update([_stop <- stopModified, _total <- totalTime]))
//                } catch {
//                    print("error updating task: \(error)")
//                }
//            }
//
//            i += 1;
//        }

        super.dismiss(sender)
    }
    
//    func unwrap(any:Any) -> Any {
//
//        let mi = Mirror(reflecting: any)
//        if mi.displayStyle != .Optional {
//            return any
//        }
//
//        if mi.children.count == 0 { return NSNull() }
//        let (_, some) = mi.children.first!
//        return some
//
//    }
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
