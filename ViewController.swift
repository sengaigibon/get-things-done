//
//  ViewController.swift
//  GetThingsDone
//
//  Created by Javier Caballero on 7/12/17.
//  Copyright © 2017 Javier Caballero. All rights reserved.
//
// Documentation:
// https://github.com/stephencelis/SQLite.swift
// https://www.tutorialspoint.com/sqlite/sqlite_commands.htm

import Cocoa
import SQLite

class ViewController: NSViewController {

    //toolbar
    @IBOutlet weak var btnAddTask: NSButton!
    @IBOutlet weak var btnMarkDone: NSButton!
    @IBOutlet weak var btnRemove: NSButton!
    @IBOutlet weak var btnStopWatch: NSButton!
    @IBOutlet weak var fieldTaskTitle: NSTextField!
    @IBOutlet weak var btnResetTitle: NSButton!
    @IBOutlet weak var fieldTag: NSTextField!
    
    
    //Tasks tableView
    @IBOutlet weak var tableView: NSTableView!
    
    //Db connection
    let filePath: URL
    let db: Connection
    
    //DB tables
    let _tasks = Table("tasks")
    let _taskTracker = Table("taskTracker")

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
            _taskItems = Array(try db.prepare(_tasks.where(_status != "completed").order(_id.desc)))
        } catch {
            print("error getting tasks")
        }
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.action = #selector(onItemClicked)
    }

    //Action triggered by a click on the TableView
    @objc private func onItemClicked() {
        
        _lastClickedTask = tableView.clickedRow
        
        if (_lastClickedTask < 0) {
            dialogOK(title: "Reminder", text: "Please select a task.")
            return
        }
        
        switch(_taskItems[_lastClickedTask].get(_status)) {
            case "idle"?:
                btnStopWatch.image = NSImage(named: NSImage.Name(rawValue: "btnPlay"))
                break;
            
            case "active"?:
                btnStopWatch.image = NSImage(named: NSImage.Name(rawValue: "btnStop"))
                break;
            
            default:
                break;
        }
    }
    
    //Query db and reload tableView
    func reloadContent() {
        
        do {
            _taskItems = Array(try db.prepare(_tasks.where(_status != "completed").order(_id.desc)))
        } catch {
            print("error getting tasks")
        }
        
        tableView.reloadData()
    }
    
    //Displays a prompt message
    func dialogOK(title: String, text: String) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = text
        alert.alertStyle = NSAlert.Style.warning
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
    
    //Clear the text in the task tag and title fields
    @IBAction func actionClearField(_ sender: Any) {
        fieldTag.stringValue = "";
        fieldTaskTitle.stringValue = "";
    }
    
    //Create new task based on title field content,
    //stores it in the DB and display it the tableView
    @IBAction func actionAddNewTask(_ sender: Any) {
        
        var tTag = fieldTag.stringValue
        let tTitle = fieldTaskTitle.stringValue
        
        if (tTitle.isEmpty) {
            dialogOK(title: "Title can not be empty", text: "Type something to create a task.")
            return
        }
        
        if (tTag.isEmpty) {
            tTag = "General";
        }
        
        let date = Date()
        let formatter = DateFormatter()
        
        formatter.dateFormat = "yyy-MM-dd HH:mm:ss"
        
        let dstartDate = formatter.string(from: date)
        
        do {
            let insert = _tasks.insert(_tag <- tTag, _taskTitle <- tTitle, _startDate <- dstartDate)
            
            //if((db) != nil) {
                try db.run(insert)
                
                fieldTag.stringValue = ""
                fieldTaskTitle.stringValue = ""
                
                reloadContent()
            //}
        } catch {
            print("error")
        }

    }
    
    // Start/stop tracking a task
    @IBAction func actionStartStopwatch(_ sender: NSButton) {
        
        if (_lastClickedTask < 0) {
            dialogOK(title: "Reminder", text: "Please select a task.")
            return
        }
        
        let taskItem = _taskItems[_lastClickedTask]
        let status = taskItem.get(_status);
        let taskId = taskItem.get(_id);
        
        let date = Date()
        let formatter = DateFormatter()
        
        formatter.dateFormat = "yyy-MM-dd HH:mm:ss"
        
        let now = formatter.string(from: date)
 
        switch(status) {
            case "idle"?:
                
                do {
                    let insert = _taskTracker.insert(_trackerTaskId <- taskId!, _trackerStart <- now)
                    let updateItem = _tasks.filter(_id == taskItem.get(_id))
                    
                    try db.run(insert)
                    
                    try db.run(updateItem.update(_status <- "active"))
                    
                    btnStopWatch.image = NSImage(named: NSImage.Name(rawValue: "btnStop"))
                    
                    reloadContent()
                } catch {
                    print("error")
                }

                
                break;
            
            case "active"?:
                
                do {
                    let filteredTaskTracker = _taskTracker.filter(_trackerTaskId == taskItem.get(_id)!).order(_trackerTrackId.desc)
                    let updateItem = _tasks.filter(_id == taskItem.get(_id))
                    
                    
                    let trackItem = try db.pluck(filteredTaskTracker)
                    let trackItemId = trackItem?.get(_trackerTrackId)
                    let trackItemStart = trackItem?.get(_trackerStart)
                    
                    let startDate = formatter.date(from: trackItemStart!)
                    let totalTime = Calendar.current.dateComponents([.second], from: startDate!, to: date).second
                    
                    let updateTaskTracker = _taskTracker.filter(_trackerTrackId == trackItemId)
                    
                    try db.run(updateTaskTracker.update([_trackerStop <- now, _trackerTotal <- totalTime]))
                    
                    try db.run(updateItem.update(_status <- "idle"))
                    
                    btnStopWatch.image = NSImage(named: NSImage.Name(rawValue: "btnPlay"))
                    
                    reloadContent()

                } catch {
                    print("error")
                }

                
                break;
        
            default:
                break;
        }
    }
    
    //Delete selected task without prompting for confirmation
    @IBAction func deleteTaskAction(_ sender: Any) {
        
        if (_lastClickedTask < 0) {
            dialogOK(title: "Reminder", text: "Please select a task.")
            return
        }
        
        //this section would delete a selected task
    }
    
    @IBAction func completeTaskAction(_ sender: Any) {

        if (_lastClickedTask < 0) {
            dialogOK(title: "Reminder", text: "Please select a task.")
            return
        }
            
        do {
            
            let updateItem = _tasks.filter(_id == _taskItems[_lastClickedTask].get(_id))
            
            try db.run(updateItem.update(_status <- "completed"))
        
            _lastClickedTask = -1
            reloadContent()
        } catch {
            print("error")
        }
        

//        if(_lastClickedTask != -1) {
//            
//            do {
//                
//                let delItem = _tasks.filter(_id == _taskItems[_lastClickedTask].get(_id))
//                
//                if((db) != nil) {
//                    try db?.run(delItem.delete())
//                    
//                    _lastClickedTask = -1
//                    reloadContent()
//                }
//            } catch {
//                print("error")
//            }
//            
//        }
    }
    
//    private lazy var summaryVewController: NSViewController = {
//        
//    }()

}

extension ViewController: NSTableViewDataSource {
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return _taskItems.count
    }
    
}

extension ViewController: NSTableViewDelegate {
    
    fileprivate enum CellIdentifiers {
        static let idCell = "IdCell"
        static let tagCell = "TagCell"
        static let titleCell = "TitleCell"
        static let startCell = "StartCell"
        static let dueCell = "DueCell"
        static let statusCell = "StatusCell"
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        
        var text: String = ""
        var cellIdentifier: String = ""
        
        let item = _taskItems[row]
        
        if tableColumn == tableView.tableColumns[0] {
            
            text = String(item.get(_id)!)
            cellIdentifier = CellIdentifiers.idCell
            
        } else if tableColumn == tableView.tableColumns[1] {
            
            text = item.get(_tag)!
            cellIdentifier = CellIdentifiers.tagCell
            
        } else if tableColumn == tableView.tableColumns[2] {
            
            text = item.get(_taskTitle)
            cellIdentifier = CellIdentifiers.titleCell
            
        } else if tableColumn == tableView.tableColumns[3] {
            
            text = item.get(_startDate)
            cellIdentifier = CellIdentifiers.startCell
        } else if tableColumn == tableView.tableColumns[4] {
            
            text = item.get(_dueDate)!
            cellIdentifier = CellIdentifiers.dueCell
        } else if tableColumn == tableView.tableColumns[5] {
            
            text = item.get(_status)!
            cellIdentifier = CellIdentifiers.statusCell
        }
        
        if let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: cellIdentifier), owner: nil) as? NSTableCellView {
            cell.textField?.stringValue = text
            return cell
        }
        return nil
    }
}
