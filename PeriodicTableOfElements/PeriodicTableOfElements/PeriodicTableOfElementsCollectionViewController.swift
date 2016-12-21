//
//  PeriodicTableOfElementsCollectionViewController.swift
//  PeriodicTableOfElements
//
//  Created by C4Q on 12/21/16.
//  Copyright © 2016 C4Q. All rights reserved.
//

import UIKit
import CoreData

private let reuseIdentifier = "Cell"

class PeriodicTableOfElementsCollectionViewController: UICollectionViewController, NSFetchedResultsControllerDelegate {
    
    var fetchedResultsController: NSFetchedResultsController<Element>!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false
        
        // Register cell classes
        self.collectionView!.register(UINib(nibName:"ElementCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: reuseIdentifier)
        getData()
        initializeFetchedResultsController()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using [segue destinationViewController].
     // Pass the selected object to the new view controller.
     }
     */
    
    // MARK: UICollectionViewDataSource
    
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        guard let sections = fetchedResultsController.sections else {
            fatalError("No sections in fetchedResultsController")
        }
        print(sections.count)
        return sections.count
    }
    
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        guard let sections = fetchedResultsController.sections else {
            fatalError("No sections in fetchedResultsController")
        }
        let sectionInfo = sections[section]
        //return sectionInfo.numberOfObjects
        return 7

    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        print(indexPath)
        guard let sections = fetchedResultsController.sections else {
            fatalError("No sections in fetchedResultsController")
        }
        let sectionInfo = sections[indexPath[0]].numberOfObjects
        
        let offset = 7 - sectionInfo
        
        if indexPath[1] < offset {
            return collectionView.dequeueReusableCell(withReuseIdentifier: "defaultCell", for: indexPath)
        } else {
            let offSetIndexPath: IndexPath = [indexPath[0], indexPath[1] - offset]
            return configureCell(indexPath: offSetIndexPath, collectionView: collectionView)
        }
    }
    
    func configureCell(indexPath: IndexPath, collectionView: UICollectionView) -> ElementCollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! ElementCollectionViewCell
        
        let currentElement = fetchedResultsController.object(at: indexPath)
        
        cell.elementView.symbolLabel.text = currentElement.symbol!
        cell.elementView.numberLabel.text = currentElement.number.description
        
        return cell
    }
    
    // MARK: Core Data Stuffs
    
    func getData() {
        APIRequestManager.manager.getData(endPoint: "https://api.fieldbook.com/v1/5859ad86d53164030048bae2/elements")  { (data: Data?) in
            if let validData = data {
                if let jsonData = try? JSONSerialization.jsonObject(with: validData, options:[]) {
                    if let elements = jsonData as? [[String:Any]] {
                        
                        // used to be our way of adding a record
                        // self.allArticles.append(contentsOf:Article.parseArticles(from: records))
                        
                        // create the private context on the thread that needs it
                        let moc = (UIApplication.shared.delegate as! AppDelegate).dataController.privateContext
                        
                        moc.performAndWait {
                            for ele in elements {
                                // now it goes in the database
                                let element = NSEntityDescription.insertNewObject(forEntityName: "Element", into: moc) as! Element
                                element.populate(from: ele)
                            }
                            do {
                                try moc.save()
                                
                                moc.parent?.performAndWait {
                                    do {
                                        try moc.parent?.save()
                                    }
                                    catch {
                                        fatalError("Failure to save context: \(error)")
                                    }
                                }
                            }
                            catch {
                                fatalError("Failure to save context: \(error)")
                            }
                            
                        }
                        DispatchQueue.main.async {
                            self.collectionView?.reloadData()
                        }
                        
                    }
                }
            }
        }
    }
    
    
    func initializeFetchedResultsController() {
        let moc = (UIApplication.shared.delegate as! AppDelegate).dataController.managedObjectContext
        
        let request = NSFetchRequest<Element>(entityName: "Element")
        let groupSort = NSSortDescriptor(key: "group", ascending: true)
        let numberSort = NSSortDescriptor(key: "number", ascending: true)
        let predicate = NSPredicate(format: "group < %@", "19")
        request.predicate = predicate
        request.sortDescriptors = [groupSort, numberSort]
        
        do {
            let els = try moc.fetch(request)
            
            for el in els {
                print("\(el.group) \(el.number) \(el.symbol)")
            }
        }
        catch {
            print("error fetching")
        }
        
        
        
        fetchedResultsController = NSFetchedResultsController(fetchRequest: request, managedObjectContext: moc, sectionNameKeyPath: "group", cacheName: nil)
        fetchedResultsController.delegate = self
        do {
            try fetchedResultsController.performFetch()
        } catch {
            fatalError("Failed to initialize FetchedResultsController: \(error)")
        }
    }
    
    
    
    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        switch kind {
        case UICollectionElementKindSectionHeader:
            let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "sectionHeaderView", for: indexPath)
            return headerView
        default:
            assert(false, "Unexpected element kind")
        }
    }
    
    // MARK: CollectionViewFlowDelegates
    


    
    // MARK: UICollectionViewDelegate
    
    /*
     // Uncomment this method to specify if the specified item should be highlighted during tracking
     override func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
     return true
     }
     */
    
    /*
     // Uncomment this method to specify if the specified item should be selected
     override func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
     return true
     }
     */
    
    /*
     // Uncomment these methods to specify if an action menu should be displayed for the specified item, and react to actions performed on the item
     override func collectionView(_ collectionView: UICollectionView, shouldShowMenuForItemAt indexPath: IndexPath) -> Bool {
     return false
     }
     
     override func collectionView(_ collectionView: UICollectionView, canPerformAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) -> Bool {
     return false
     }
     
     override func collectionView(_ collectionView: UICollectionView, performAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) {
     
     }
     */
    
    /*
     
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        collectionView.beginUpdates()
        collectionView.
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
        switch type {
        case .insert:
            collectionView.insertSections(IndexSet(integer: sectionIndex), with: .fade)
        case .delete:
            collectionView.deleteSections(IndexSet(integer: sectionIndex), with: .fade)
        case .move:
            break
        case .update:
            break
        }
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        guard let ip = indexPath else { return }
        switch type {
        case .insert:
            collectionView!.insertItems(at: [newIndexPath!])
        case .delete:
                collectionView?.deleteItems(at: [ip])
        case .update:
            if let ip = indexPath,
                let cell = collectionView.cellForRow(at: ip) {
                configureCell(cell, indexPath: ip)
            }
        case .move:
            collectionView.moveRow(at: indexPath!, to: newIndexPath!)
        }
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        collectionView.endUpdates()
    }
    */
}
