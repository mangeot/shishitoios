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
    //var entries = [Dictionary]()
    
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
        let entry = self.entries[indexPath.row] as? Dictionary<String, String>
        let romajiString = entry?["vedette-romaji"]
        let jpnString = (entry?["vedette-jpn"])! + " "
        let vedetteString = romajiString! + "　" + jpnString + (entry?["vedette-hiragana"])!
        
        let romajiRange = NSMakeRange(0, (romajiString?.characters.count)!)
        let jpnRange = NSMakeRange((romajiString?.characters.count)!, jpnString.characters.count)
        cell.vedette.attributedText = attributedString(from: vedetteString, romajiRange: romajiRange, jpnRange: jpnRange)
        cell.pos.text = entry?["pos"]
        
        return cell
    }

    func callURL () {
        var queryWord = searchField.text
        let scalars = queryWord?.unicodeScalars
        var cdmkey = "cdm-writing"
        let firstChar = scalars?[(scalars?.startIndex)!].value
        print ("un:", firstChar)
        //hiragana : 12352-12447
        if (firstChar!>12447 || queryWord == "??") {
            cdmkey = "cdm-headword"
        }
        else if (firstChar!>12352 && firstChar!<12447) {
            cdmkey = "cdm-reading"
        }
        queryWord = queryWord?.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)
        let queryUrl: String = "https://jibiki.imag.fr/jibiki/api/Cesselin/jpn/" + cdmkey + "/" + queryWord! + "/entries/?strategy=equal"
        
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
                    var entry:Dictionary<String, String> = [:]
                    for (index, vedette) in article.xpath("./forme/vedette/vedette-jpn/text()").enumerated() {
                        entry["vedette-jpn"] = vedette.stringValue
                        if index == 1 {
                            break
                        }
                    }
                    for (index, vedette) in article.xpath("./forme/vedette/vedette-romaji/text()").enumerated() {
                        entry["vedette-romaji"] = vedette.stringValue
                        if index == 1 {
                            break
                        }
                    }
                    for (index, vedette) in article.xpath("./forme/vedette/vedette-hiragana/text()").enumerated() {
                        entry["vedette-hiragana"] = "【" + vedette.stringValue + "】"
                        if index == 1 {
                            break
                        }
                    }
                    for (index, pos) in article.xpath("./sémantique/bloc-gram/étiquettes/gram/text()").enumerated() {
                        entry["pos"] = "[" + pos.stringValue + "]"
                        if index == 1 {
                            break
                        }
                    }
                    print("vedr: " + entry["vedette-romaji"]!)
                    print("vedj: " + entry["vedette-jpn"]!)
                    print("vedh: " + entry["vedette-hiragana"]!)
                    print("pos: " + entry["pos"]!)
                    self.entries.add(entry)
                }
                DispatchQueue.main.async { [unowned self] in
                    self.myTableView.reloadData()
                }
                
            } catch  {
                print("error trying to convert data to XML")
                return
            }
        }
        task.resume()
    }
    
    func attributedString(from string: String, romajiRange: NSRange?, jpnRange: NSRange?) -> NSAttributedString {
        let fontSize = UIFont.systemFontSize
        let romajiColor = UIColor(
            red: 0xd4/255,
            green: 0x54/255,
            blue: 0x55/255,
            alpha: 1.0)
        let attrs = [
            NSFontAttributeName: UIFont.systemFont(ofSize: fontSize),
        ]
        let romajiAttrs = [
            NSForegroundColorAttributeName: romajiColor
        ]
        let jpnAttrs = [
            NSFontAttributeName: UIFont.boldSystemFont(ofSize: fontSize),
           ]
        let attrStr = NSMutableAttributedString(string: string, attributes: attrs)
        attrStr.setAttributes(romajiAttrs, range: romajiRange!)
        attrStr.setAttributes(jpnAttrs, range: jpnRange!)
        return attrStr
    }
    
    
}

