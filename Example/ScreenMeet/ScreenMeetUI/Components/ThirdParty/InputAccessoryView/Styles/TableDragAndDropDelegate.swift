//
//  TableDragAndDropDelegate.swift
//  Reports
//
//  Created by Apple on 10/11/20.
//  Copyright © 2020 Ross Stepaniak. All rights reserved.
//

import UIKit

protocol TableDragAndDropDelegate: AnyObject {
    func onDragStarted(_ sourceIndexPath: IndexPath)
    func onDropped(_ sourceIndexPath: IndexPath, _ destinationIndexPath: IndexPath?)
}
