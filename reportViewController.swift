//
//  SummaryViewController.swift
//  GetThingsDone
//
//  Created by Javier Caballero on 17/08/2017.
//  Copyright © 2017 Javier Caballero. All rights reserved.
//

import Cocoa
import SQLite.Swift


class reportViewController: NSViewController {
    
    //Db connection
    let filePath: URL
    let db: Connection
    let query: String
    let groupAndOrderQuery: String
    var _period = " where date(tt.start) = date()"
    
    //Tasks tableView
    @IBOutlet weak var reportTableView: NSTableView!
    
    //Action buttons and other elements
    @IBOutlet weak var goSimplePeriodBtn: NSButton!
    @IBOutlet weak var periodSelector: NSPopUpButton!
    @IBOutlet weak var goExtendedPeriodBtn: NSButton!
    @IBOutlet weak var startDP: NSDatePicker!
    @IBOutlet weak var endDp: NSDatePicker!
    @IBOutlet weak var labelHours: NSTextField!
    
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
    let _trackerStart = Expression<Date?>("start")
    let _trackerStop = Expression<Date?>("stop")
    let _trackerTotal = Expression<Int?>("total")
    
    var _summaryTaskItemsArr: Statement? = nil
    var _formattedTasks: [Any] = []
    var _coderLOL: NSCoder
    //var _tasks: [Int: Array<Any>]
    
    
    var _summaryTaskItems: Statement? = nil
    
    required init?(coder lol: NSCoder) {
        filePath = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false).appendingPathComponent("GetThingsDone/tasks.sqlite");
        db = try! Connection(filePath.absoluteString)
        query = "select tt.taskId as taskId, t.title as title, tt.total as total, tt.start from tasks t join taskTracker tt on tt.taskId = t.taskId"
        groupAndOrderQuery = " order by taskId"
        _coderLOL = lol
        super.init(coder: lol)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        do {
            let localQuery = query + _period + groupAndOrderQuery
            _summaryTaskItemsArr = try db.run(localQuery)
        } catch {
            print("error getting tasks: \(error)")
        }
        
        processRecords()
        
        reportTableView.delegate = self
        reportTableView.dataSource = self
        
        let date = Date()
        startDP.dateValue = date
        endDp.dateValue = date
        
        reportTableView.doubleAction  = #selector(onItemDoubleClicked)
    }
    
    @objc private func onItemDoubleClicked() {
        let taskDetailsViewController:taskDetailsViewController = self.storyboard!.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier(rawValue: "taskDetails")) as! taskDetailsViewController
        let thisRow = _formattedTasks[reportTableView.clickedRow] as? [Any]
        taskDetailsViewController.taskId = String(describing: thisRow![0])
        taskDetailsViewController.period = _period
        self.presentViewControllerAsSheet(taskDetailsViewController)
    }
    
    func processRecords()
    {
        var taskId : Binding
        var taskName : Binding
        var totalTime : Binding
        var timeStamp : Binding

        var cPreviousTaskId = 0
        var cCurrentTaskId = 0
        var cTaskName = ""
        var cTaskTime : Float = 0
        var cTotalTaskTime : Float = 0
        var cAllTasksTime : Float = 0
        var cTimeStamp = ""

        var formatedTasks: Array<Any> = []
        var tasks = [Int: Array<Any>]()

        var index = 0
        var items = 0
        
        for record in _summaryTaskItemsArr! {
            
            items += 1
            
            if index == 1 {
                continue
            }
            taskId = record[0]!
            taskName = record[1]!
            totalTime = record[2]!
                
            cCurrentTaskId = Int(String(describing: taskId))!
            cTaskName = String(describing: taskName)
            cTaskTime = Float(String(describing: totalTime))!
            
            if cTaskTime == 0 {
                timeStamp = record[3]!
                cTimeStamp = String(describing: timeStamp)
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
                let date = formatter.date(from: cTimeStamp)
                let elapsed = Date().timeIntervalSince(date!)
                cTaskTime = Float(elapsed)
                print("next is calculated time:")
                print(cTaskTime)
                print(cTimeStamp)
            }
            
            cAllTasksTime += cTaskTime
            
            cTotalTaskTime = cTaskTime
            cPreviousTaskId = cCurrentTaskId
            tasks[cCurrentTaskId] = [cTaskName, cTotalTaskTime]
        
            print("\(taskId) -> \(cTotalTaskTime)")
            index = 1;
        }
        
        if items == 1 {
            formatedTasks.append([cCurrentTaskId, cTaskName, cTotalTaskTime])
        } else {
            for record in _summaryTaskItemsArr! {
                
                if index == 1 {
                    index += 1
                    continue
                }
                
                taskId = record[0]!
                taskName = record[1]!
                totalTime = record[2]!

                cCurrentTaskId = Int(String(describing: taskId))!
                cTaskName = String(describing: taskName)
                cTaskTime = Float(String(describing: totalTime))!

                if cTaskTime == 0 {
                    timeStamp = record[3]!
                    cTimeStamp = String(describing: timeStamp)
                    let formatter = DateFormatter()
                    formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
                    let date = formatter.date(from: cTimeStamp)
                    let elapsed = Date().timeIntervalSince(date!)
                    cTaskTime = Float(elapsed)
                    print("next is calculated time:")
                    print(cTaskTime)
                    print(cTimeStamp)
                }

                cAllTasksTime += cTaskTime
                
                if cPreviousTaskId == cCurrentTaskId {
                    cTotalTaskTime += cTaskTime
                    let tmpTime = Float(String(describing: tasks[cCurrentTaskId]![1]))
                    tasks[cCurrentTaskId]![1] = tmpTime! + cTaskTime
                } else {
                    formatedTasks.append([cPreviousTaskId, tasks[cPreviousTaskId]![0], tasks[cPreviousTaskId]![1]])
                    cTotalTaskTime = cTaskTime
                    cPreviousTaskId = cCurrentTaskId
                    tasks[cCurrentTaskId] = [cTaskName, cTotalTaskTime]
                }
                print("\(taskId) -> \(cTaskTime)")
                
                if index == items {
                    formatedTasks.append([cCurrentTaskId, cTaskName, cTotalTaskTime])
                }
                
                index += 1
            }
        }

        print("")
        print("cAllTasksTime:")
        print(cAllTasksTime)
        print("")
        print("tasks:")
        print(tasks)

        print("")
        print("next is array:")
        labelHours.stringValue = String(format: "%.3f", cAllTasksTime / 3600)
        print("")
        print("formatedTasks:")
        print(formatedTasks)
        print("")
        print("_summaryTaskItemsArr:")
        print(_summaryTaskItemsArr)
        _formattedTasks = formatedTasks
        //_tasks = tasks
    }
    
    @IBAction func actionClick(_ sender: Any) {
        let period = periodSelector.selectedItem?.title ?? ""
        var localQuery = ""
        
        switch(period) {
            case "Today":
                _period = " where date(tt.start) = date()"
                break;
        
            case "Yesterday":
                _period = " where date(tt.start) = date('now','-1 day')"
                break;
            
            case "This week":
                _period = " where strftime('%W', tt.start, 'localtime') = strftime('%W', 'now', 'localtime')"
                break;
            
            case "This month":
                _period = " where strftime('%m', tt.start, 'localtime') = strftime('%m', 'now', 'localtime')"
                break;
            
            case "This year":
                _period = " where strftime('%Y', tt.start, 'localtime') = strftime('%Y', 'now', 'localtime')"
                break;
            
            default:
                return;
        }
        localQuery =  query + _period + groupAndOrderQuery
        
        do {
            _summaryTaskItemsArr = try db.prepare(localQuery)
        } catch {
            print("error getting tasks: \(error)")
        }
        processRecords()
        reportTableView.reloadData()
    }
  
    @IBAction func actionRequestCustomPeriod(_ sender: Any) {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyy-MM-dd"
        
        let startDate = formatter.string(from: startDP.dateValue)
        let endDate = formatter.string(from: endDp.dateValue)
        
        _period = " where tt.start >= '" + startDate + "' and tt.start <= '" + endDate + "'"
        let localQuery = query + _period + groupAndOrderQuery;
        
        do {
            _summaryTaskItemsArr = try db.prepare(localQuery)
        } catch {
            print("error getting tasks: \(error)")
        }
        processRecords()
        
        reportTableView.reloadData()
    }
    
}

extension reportViewController: NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return _formattedTasks.count
    }
}

extension reportViewController: NSTableViewDelegate {

    fileprivate enum CellIdentifiers {
        static let timeSpentCell = "TimeSpentCell"
        static let taskCell = "TaskCell"
    }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        
        var tempTotal: Float;
        var content: String = ""
        var cellIdentifier: String = ""
        
//        let itemTotal = _summaryTaskItemsArr[row][2] ?? 0
//        let itemTaskName = _summaryTaskItemsArr[row][1] ?? ""
        let thisRow = _formattedTasks[row] as? [Any]
        let itemTotal = thisRow![2]
        let itemTaskName = thisRow![1]
        
        if tableColumn == tableView.tableColumns[0] {
            
            tempTotal = Float(String(describing: itemTotal))!
            if tempTotal == 0 {
                print("es cero")
            }
            
            content = String(format: "%.3f", tempTotal / 3600)
            cellIdentifier = CellIdentifiers.timeSpentCell
            
        } else if tableColumn == tableView.tableColumns[1] {
            
            content = String(describing: itemTaskName)
            cellIdentifier = CellIdentifiers.taskCell
            
        }
        
        if let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: cellIdentifier), owner: nil) as? NSTableCellView {
            cell.textField?.stringValue = content
            return cell
        }
        return nil
        
    }
}
