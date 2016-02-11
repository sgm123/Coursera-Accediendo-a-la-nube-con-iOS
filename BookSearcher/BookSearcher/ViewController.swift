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
    @IBOutlet weak var resultTextView: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        inputTextField.delegate = self
    }
    
    func downloadBookDataWith(isbn isbn: String) {
        let urlString = "https://openlibrary.org/api/books?jscmd=data&format=json&bibkeys=ISBN:\(isbn)"
        let url = NSURL(string: urlString)
        if let url = url {
            let task = NSURLSession.sharedSession().dataTaskWithURL(url, completionHandler: { (data, response, error) -> Void in
                UIApplication.sharedApplication().networkActivityIndicatorVisible = false
                guard data != nil && error == nil else {
                    self.updateResultTextView("")
                    dispatch_async(dispatch_get_main_queue()) { () -> Void in
                        let alert = UIAlertController(title: "Error conexión", message: "No hay conexión a internet o el servidor no está accesible.", preferredStyle: .Alert)
                        alert.addAction(UIAlertAction(title: "Aceptar", style: .Default, handler: nil))
                        self.presentViewController(alert, animated: true, completion: nil)
                    }
                    return
                }
                let json = String(data: data!, encoding: NSUTF8StringEncoding)
                if let json = json {
                    self.updateResultTextView(json)
                } else {
                    self.updateResultTextView("Ha ocurrido un error")
                }
            })
            task.resume()
            UIApplication.sharedApplication().networkActivityIndicatorVisible = true
        } else {
            // Error building endpoint
            self.resultTextView.text = "Ha ocurrido un error generando la url \n \(urlString)"
        }
    }
    
    func updateResultTextView(text: String) {
        dispatch_async(dispatch_get_main_queue()) { () -> Void in
            self.resultTextView.text = text
        }
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

