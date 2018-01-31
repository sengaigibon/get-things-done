//
//  CompletedTasksViewController.swift
//  GetThingsDone
//
//  Created by Javier Caballero on 31/01/2018.
//  Copyright © 2018 Javier Caballero. All rights reserved.
//

import Cocoa
import SQLite

class CompletedTasksViewController: NSViewController {
    
    @IBOutlet weak var completedTasksTableView: NSTableView!
    
    //Db connection
    let filePath: URL
    let db: Connection
    
    //DB tables
    let _tasks = Table("tasks")
    
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
    
    var _taskItems: Array<Row> = []
    var _lastClickedTask: Int = -1
    
    required init?(coder lol: NSCoder) {
        filePath = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false).appendingPathComponent("GetThingsDone/tasks.sqlite");
        db = try! Connection(filePath.absoluteString)
        super.init(coder: lol)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        do {
            _taskItems = Array(try db.prepare(_tasks.where(_status == "completed").order(_id.desc)))
        } catch {
            print("error getting tasks")
        }
        
        completedTasksTableView.delegate = self
        completedTasksTableView.dataSource = self
        //completedTasksTableView.action = #selector(onItemClicked)
    }
}

extension CompletedTasksViewController: NSTableViewDataSource {

    func numberOfRows(in completedTasksTableView: NSTableView) -> Int {
        return _taskItems.count
    }

}

extension CompletedTasksViewController: NSTableViewDelegate {

    fileprivate enum CellIdentifiers {
        static let idCell = "IdCell"
        static let tagCell = "TagCell"
        static let titleCell = "TitleCell"
        static let startCell = "StartCell"
        static let dueCell = "DueCell"
        static let statusCell = "StatusCell"
    }

    func tableView(_ completedTasksTableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {

        var text: String = ""
        var cellIdentifier: String = ""

        let item = _taskItems[row]

        if tableColumn == completedTasksTableView.tableColumns[0] {

            text = String(item.get(_id)!)
            cellIdentifier = CellIdentifiers.idCell

        } else if tableColumn == completedTasksTableView.tableColumns[1] {

            text = item.get(_tag)!
            cellIdentifier = CellIdentifiers.tagCell

        } else if tableColumn == completedTasksTableView.tableColumns[2] {

            text = item.get(_taskTitle)
            cellIdentifier = CellIdentifiers.titleCell

        } else if tableColumn == completedTasksTableView.tableColumns[3] {

            text = item.get(_startDate)
            cellIdentifier = CellIdentifiers.startCell
        } else if tableColumn == completedTasksTableView.tableColumns[4] {

            text = item.get(_dueDate)!
            cellIdentifier = CellIdentifiers.dueCell
        } else if tableColumn == completedTasksTableView.tableColumns[5] {

            text = item.get(_status)!
            cellIdentifier = CellIdentifiers.statusCell
        }

        if let cell = completedTasksTableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: cellIdentifier), owner: nil) as? NSTableCellView {
            cell.textField?.stringValue = text
            return cell
        }
        return nil
    }
}

