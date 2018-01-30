//
//  SummaryViewController.swift
//  GetThingsDone
//
//  Created by Javier Caballero on 17/08/2017.
//  Copyright © 2017 Javier Caballero. All rights reserved.
//

import Cocoa
import SQLite


class reportViewController: NSViewController {
    
    //Db connection
    let filePath = NSObject()
    let db = NSObject()
    
    //Tracks tableView
    @IBOutlet weak var reportTableView: NSTableView!
    
    //DB tables
    let _tasks = Table("tasks")
    let _taskTracker = Table("taskTracker")
    let _summaryView = Table("summary2")
    
    //Expressions for tasks table
    let _id = Expression<Int64?>("taskId")
    let _tag = Expression<String?>("tag")
    let _taskTitle = Expression<String>("title")
    let _startDate = Expression<String>("startDate")
    let _dueDate = Expression<String?>("dueDate")
    let _status = Expression<String?>("status")
    
    //Expressions for taskTracker table
    let _trackerTrackId = Expression<Int64?>("trackId")
    let _trackerTaskId = Expression<Int64>("taskId")
    let _trackerStart = Expression<String?>("start")
    let _trackerStop = Expression<String?>("stop")
    let _trackerTotal = Expression<Int?>("total")
    
    var _summaryTaskItems: Array<Row> = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let filePath = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false).appendingPathComponent("GetThingsDone/tasks.sqlite");
        let db = try? Connection(filePath.absoluteString)
        
        do {
            if((db) != nil) {
                
                _summaryTaskItems = Array(try db!.prepare(_summaryView))

            }
        } catch {
            print("error getting tasks")
        }
        
        reportTableView.delegate = self
        reportTableView.dataSource = self
        //reportTableView.action = #selector(onItemClicked)
    }

}

extension reportViewController: NSTableViewDataSource {
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return _summaryTaskItems.count
    }
    
}

extension reportViewController: NSTableViewDelegate {

    fileprivate enum CellIdentifiers {
        static let timeSpentCell = "TimeSpentCell"
        static let taskCell = "TaskCell"
    }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        
        var tempAsign: Int = 0;
        var text: String = ""
        var cellIdentifier: String = ""
        
        let item = _summaryTaskItems[row]
        
        if tableColumn == tableView.tableColumns[0] {
            
            //tempAsign = item.get(_trackerTotal)
            if(String(describing: item.get(_trackerTotal)) == "nil") {
                text = "0"
            } else {
                tempAsign = item.get(_trackerTotal)!
                text = String(Float(Float(tempAsign / 60) / 60))
            }
            cellIdentifier = CellIdentifiers.timeSpentCell
            
        } else if tableColumn == tableView.tableColumns[1] {
            
            text = item.get(_taskTitle)
            cellIdentifier = CellIdentifiers.taskCell
            
        }
        
        if let cell = tableView.make(withIdentifier: cellIdentifier, owner: nil) as? NSTableCellView {
            cell.textField?.stringValue = text
            return cell
        }
        return nil
        
    }
}
