//
//  Task.swift
//  GetThingsDone
//
//  Created by Javier Caballero on 7/12/17.
//  Copyright © 2017 Javier Caballero. All rights reserved.
//

import Foundation


class Task {
    
    var id: Int64
    var tag: String
    var title: String
    var startDate: String
    var dueDate: String
    var totalTime: String
    var status: String
    
    enum statuses {
        case active
        case idle
        case completed
        case postponed
    }
    
    
    init(name: String, desc: String, start: String) {
        self.tag = name
        self.title = desc
        self.startDate = start
        
        self.id = Int64(arc4random())
        self.dueDate = ""
        self.totalTime = ""
        self.status = "idle";
    }
    
}

/*
 create table tasks (
 taskId INTEGER PRIMARY KEY AUTOINCREMENT,
 tag VARCHAR(32) DEFAULT '',
 title VARCHAR(254) NOT NULL,
 startDate DATETIME NOT NULL,
 dueDate VARCHAR(32) DEFAULT '',
 status VARCHAR(32) DEFAULT 'idle',
 totalTime TIME DEFAULT 0
 );
 
 create table taskTracker (
 trackId INTEGER PRIMARY KEY AUTOINCREMENT,
 taskId INT NOT NULL,
 start DATETIME NOT NULL,
 stop DATETIME,
 total INTEGER DEFAULT 0,
 FOREIGN KEY (taskId) REFERENCES tasks(taskId)
 );
 
 create table taskHistory (
 taskId INTEGER PRIMARY KEY AUTOINCREMENT,
 tag VARCHAR(32) DEFAULT NULL,
 title VARCHAR(254) NOT NULL,
 startDate DATETIME NOT NULL,
 dueDate VARCHAR(32) DEFAULT NULL,
 status VARCHAR(32) DEFAULT 'idle',
 totalTime TIME DEFAULT 0
 );
 
 status: active, idle, completed, postponed
 
 CREATE VIEW summary as select t.title, sum(tt.total) from tasks t join taskTracker tt on tt.taskId = t.taskId group by t.title;
 CREATE VIEW summary2 as select t.title as title, sum(tt.total) as total from tasks t join taskTracker tt on tt.taskId = t.taskId group by t.title;
 
 select t.title as title, date(tt.start), date(tt.stop), strftime("%H:%m:%S", tt.start), strftime("%H:%m:%S", tt.stop), tt.total from tasks t join taskTracker tt on tt.taskId = t.taskId order by title;
 
 */
