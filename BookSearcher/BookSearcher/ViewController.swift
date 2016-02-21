//
//  ViewController.swift
//  BookSearcher
//
//  Created by Sergio García on 11/2/16.
//  Copyright © 2016 Sergio García. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    @IBOutlet weak var inputTextField: UITextField!
//    @IBOutlet weak var resultTextView: UITextView!
    @IBOutlet weak var mainImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    
    var authors = [String]() {
        didSet {
            if let tableView = self.tableView {
                tableView.reloadData()
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        inputTextField.delegate = self
        self.tableView.dataSource = self
        self.tableView.allowsSelection = false
    }
    
    func downloadBookDataWith(isbn isbn: String) {
        let urlString = "https://openlibrary.org/api/books?jscmd=data&format=json&bibkeys=ISBN:\(isbn)"
        let url = NSURL(string: urlString)
        if let url = url {
            let task = NSURLSession.sharedSession().dataTaskWithURL(url, completionHandler: { (data, response, error) -> Void in
                UIApplication.sharedApplication().networkActivityIndicatorVisible = false
                guard data != nil && error == nil else {
                    self.updateResultTextView("", isbn: nil)
                    dispatch_async(dispatch_get_main_queue()) { () -> Void in
                        let alert = UIAlertController(title: "Error conexión", message: "No hay conexión a internet o el servidor no está accesible.", preferredStyle: .Alert)
                        alert.addAction(UIAlertAction(title: "Aceptar", style: .Default, handler: nil))
                        self.presentViewController(alert, animated: true, completion: nil)
                    }
                    return
                }
                let json = String(data: data!, encoding: NSUTF8StringEncoding)
                if let json = json {
                    self.updateResultTextView(json, isbn: isbn)
                } else {
                    self.updateResultTextView("Ha ocurrido un error", isbn: nil)
                }
            })
            task.resume()
            UIApplication.sharedApplication().networkActivityIndicatorVisible = true
        } else {
            // Error building endpoint
             print("Ha ocurrido un error generando la url \n \(urlString)")
            //self.resultTextView.text = "Ha ocurrido un error generando la url \n \(urlString)"
        }
    }
    
    func updateResultTextView(text: String, isbn: String?) {
        dispatch_async(dispatch_get_main_queue()) { () -> Void in
            print(text)
            let json = self.convertStringToDictionary(text)
            if let json = json, isbn = isbn {
                let stringArray = isbn.componentsSeparatedByCharactersInSet(
                    NSCharacterSet.decimalDigitCharacterSet().invertedSet)
                let newString = stringArray.joinWithSeparator("")
                let coverURL = "http://covers.openlibrary.org/b/isbn/\(newString)-L.jpg"
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), { () -> Void in
                    // do some task
                    let url = NSURL(string: coverURL)
                    if let url = url {
                        if let data = NSData(contentsOfURL: url) {
                            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                                self.mainImageView.image = UIImage(data: data)
                            })
                        } else {
                            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                                self.mainImageView.image = nil
                            })
                        }
                    }
                })
                let bookTitle = json["ISBN:\(isbn)"]?["title"] as? String
                let bookAuthors = json["ISBN:\(isbn)"]?["authors"] as? [[String: String]]
                if let bookAuthors = bookAuthors {
                    var names = [String]()
                    for author in bookAuthors {
                        names.append(author["name"] ?? "")
                    }
                    self.authors = names
                } else {
                    self.authors = [String]()
                }
                self.titleLabel.text = bookTitle
            } else {
                self.authors = [String]()
                // Borrar datos
            }
            //self.resultTextView.text = text
        }
    }
    
    private func convertStringToDictionary(text: String) -> [String:AnyObject]? {
        if let data = text.dataUsingEncoding(NSUTF8StringEncoding) {
            do {
                return try NSJSONSerialization.JSONObjectWithData(data, options: []) as? [String: AnyObject]
            } catch let error as NSError {
                print(error)
            }
        }
        return nil
    }
    
}

extension ViewController: UITextFieldDelegate {
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        if let text = textField.text where !text.isEmpty {
            downloadBookDataWith(isbn: text)
        }
        textField.resignFirstResponder()
        return true
    }
}

extension ViewController: UITableViewDataSource {
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "Autores"
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return authors.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .Default, reuseIdentifier: "default")
        cell.textLabel?.text = authors[indexPath.row]
        return cell
    }
}

