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
    let filePath: URL
    let db: Connection
    let query: String
    let groupAndOrderQuery: String
    
    //Tracks tableView
    @IBOutlet weak var reportTableView: NSTableView!
    
    //Action buttons and other elements
    @IBOutlet weak var goSimplePeriodBtn: NSButton!
    @IBOutlet weak var periodSelector: NSPopUpButton!
    @IBOutlet weak var goExtendedPeriodBtn: NSButton!
    @IBOutlet weak var startDP: NSDatePicker!
    @IBOutlet weak var endDp: NSDatePicker!
    
    
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
    
    var _summaryTaskItemsArr: Array<Statement.Element> = []
    
    required init?(coder lol: NSCoder) {
        filePath = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false).appendingPathComponent("GetThingsDone/tasks.sqlite");
        db = try! Connection(filePath.absoluteString)
        query = "select t.title as title, sum(tt.total) as total from tasks t join taskTracker tt on tt.taskId = t.taskId"
        groupAndOrderQuery = " group by t.taskId order by total desc"
        super.init(coder: lol)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        do {
            let localQuery = query + " where date(tt.start) = date()" + groupAndOrderQuery
            _summaryTaskItemsArr = Array(try db.prepare(localQuery))
        } catch {
            print("error getting tasks")
        }
        
        reportTableView.delegate = self
        reportTableView.dataSource = self
        
        let date = Date()
        startDP.dateValue = date
        endDp.dateValue = date
        
        //reportTableView.action = #selector(onItemClicked)
    }
    
    @IBAction func actionClick(_ sender: Any) {
        let period = periodSelector.selectedItem?.title ?? ""
        var localQuery = ""
        
        switch(period) {
            case "Today":
                localQuery = query + " where date(tt.start) = date()"
                break;
        
            case "Yesterday":
                localQuery = query + " where date(tt.start) = date('now','-1 day')"
                break;
            
            case "This week":
                localQuery = query + " where strftime('%W', tt.start, 'localtime') = strftime('%W', 'now', 'localtime')"
                break;
            
            case "This month":
                localQuery = query + " where strftime('%m', tt.start, 'localtime') = strftime('%m', 'now', 'localtime')"
                break;
            
            case "This year":
                localQuery = query + " where strftime('%Y', tt.start, 'localtime') = strftime('%Y', 'now', 'localtime')"
                break;
            
            default:
                return;
        }
        localQuery += groupAndOrderQuery
        
        do {
            _summaryTaskItemsArr = Array(try db.prepare(localQuery))
        } catch {
            print("error getting tasks")
        }
        
        reportTableView.reloadData()
    }
  
    @IBAction func actionRequestCustomPeriod(_ sender: Any) {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyy-MM-dd"
        
        let startDate = formatter.string(from: startDP.dateValue)
        let endDate = formatter.string(from: endDp.dateValue)
        
        let localQuery = query + " tt.start >= '" + startDate + "' and tt.start <= '" + endDate + "'" + groupAndOrderQuery;
        
        do {
            _summaryTaskItemsArr = Array(try db.prepare(localQuery))
        } catch {
            print("error getting tasks")
        }
        
        reportTableView.reloadData()
    }
    
}

extension reportViewController: NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return _summaryTaskItemsArr.count
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
        
        let itemTotal = _summaryTaskItemsArr[row][1] ?? 0
        let itemTaskName = _summaryTaskItemsArr[row][0] ?? ""
        
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
