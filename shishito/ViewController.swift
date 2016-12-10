//
//  ViewController.swift
//  shishito
//
//  Created by Mathieu Mangeot on 06/12/2016.
//  Copyright © 2016 Université Savoie Mont Blanc. All rights reserved.
//

import UIKit
import Fuzi

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, XMLParserDelegate {
// https://grokswift.com/simple-rest-with-swift/
//https://medium.com/@ronm333/a-simple-table-view-example-in-swift-cbf9a405f975#.8viy2fgos

    var entries = NSMutableArray()
    var entry = NSMutableDictionary()
    
    @IBOutlet var myTableView: UITableView! {
        didSet {
            myTableView.dataSource = self
        }
    }
    @IBOutlet weak var searchField: UITextField!

    
    @IBAction func buttonPressed(_ sender: Any) {
        print("You clicked the button")
        self.callURL()
    }
    
    func callURL () {
        var queryWord = searchField.text
        queryWord = queryWord?.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)
        let queryUrl: String = "https://jibiki.imag.fr/jibiki/api/Cesselin/jpn/cdm-writing/" + queryWord! + "/entries/?strategy=equal"
        
        guard let url = URL(string: queryUrl) else {
            print("Error: cannot create URL")
            return
        }
 
        let urlRequest = URLRequest(url: url)
        
        let session = URLSession.shared
        
        let task = session.dataTask(with: urlRequest) {
            (data, response, error) in
            // check for any errors
            guard error == nil else {
                print("error calling GET on url")
                print(error!)
                return
            }
            // make sure we got data
            guard let responseData = data else {
                print("Error: did not receive data")
                return
            }
            // parse the result as XML, since that's what the API provides
            do {
                let document = try XMLDocument(data: responseData)
                document.definePrefix("d", defaultNamespace: "http://www-clips.imag.fr/geta/services/dml")
                self.entries = []
                for article in document.xpath("/d:entry-list/d:entry/volume/d:contribution/d:data/article") {
                    print("id:"+article["id"]!)
                    self.entry = [:]
                    for (index, vedette) in article.xpath("./forme/vedette/vedette-jpn/text()").enumerated() {
                         self.entry["vedette-jpn"] = vedette.stringValue
                        if index == 1 {
                            break
                        }
                    }
                    for (index, vedette) in article.xpath("./forme/vedette/vedette-romaji/text()").enumerated() {
                        self.entry["vedette-romaji"] = vedette.stringValue
                        if index == 1 {
                            break
                        }
                    }
                    for (index, vedette) in article.xpath("./forme/vedette/vedette-hiragana/text()").enumerated() {
                        self.entry["vedette-hiragana"] = "【" + vedette.stringValue + "】"
                        if index == 1 {
                            break
                        }
                    }
                    print("vedr: " + (self.entry["vedette-romaji"] as! String))
                    print("vedj: " + (self.entry["vedette-jpn"] as! String))
                    print("vedh: " + (self.entry["vedette-hiragana"] as! String))
                    self.entries.add(self.entry)
               }
                DispatchQueue.main.async { [unowned self] in
                    self.myTableView.reloadData()
                }
                
            } catch  {
                print("error trying to convert data to JSON")
                return
            }
        }
        task.resume()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        print("Hello world")
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    func numberOfSections(in: UITableView) -> Int {
        return 1
    }
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return entries.count
    }
    
    // ne marche pas
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell,
                   forRowAt indexPath: IndexPath) {
        
        if (indexPath.row % 2 == 0)
        {
            cell.backgroundColor = UIColor.gray
        }
        else
        {
            cell.backgroundColor = UIColor.white
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath as IndexPath) as! TableViewCell
        let entry = self.entries[indexPath.row] as! NSMutableDictionary
        cell.romaji.text = entry.object(forKey: "vedette-romaji") as! String?
        cell.jpn.text = entry.object(forKey: "vedette-jpn") as! String?
        cell.hiragana.text = entry.object(forKey: "vedette-hiragana") as! String?
        
        return cell
    }

}

