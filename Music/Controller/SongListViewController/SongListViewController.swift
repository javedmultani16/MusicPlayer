//
//  SongListViewController.swift
//  Music
//
//  Created by Javed Multani on 12/01/21.
//

import UIKit
import CoreData

class SongListViewController: UIViewController,UITableViewDelegate,UITableViewDataSource,XMLParserDelegate {
    
    @IBOutlet weak var songTableView: UITableView!
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    
    
    let recordKey = "entry"
    let dictionaryKeys = ["title","im:name","im:artist","im:price","im:image"]
    var results: [[String: String]]? = [[String: String]]()// the whole array of dictionaries
    var currentDictionary: [String: String]? = [String: String]()// the current dictionary
    var currentValue: String?
    
    var links = [String]()
    var songsArray:[Songs] = [Songs]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Music List"
        if (UserDefaults.standard.bool(forKey: "HasLaunchedOnce")) {
            // App already launched
            self.fetchData()
        } else {
            // This is the first launch ever
            UserDefaults.standard.set(true, forKey: "HasLaunchedOnce")
            UserDefaults.standard.synchronize()
            self.getData()
        }
        
        songTableView.backgroundColor = .clear
        songTableView.delegate = self
        songTableView.dataSource = self
        songTableView.reloadData()
        
        songTableView.register(UINib(nibName: "SongTableViewCell", bundle: nil), forCellReuseIdentifier: "SongTableViewCell")
    }
   
    //MARK: ======== Add Data =================
    func getData(){
        let task = URLSession.shared.dataTask(with: URL(string: "http://ax.itunes.apple.com/WebObjects/MZStoreServices.woa/ws/RSS/topsongs/limit=20/xml")!) { data, response, error in
            guard let data = data, error == nil else {
                print(error ?? "Unknown error")
                return
            }
            
            let parser = XMLParser(data: data)
            parser.delegate = self
            if parser.parse() {
                //  print(self.results ?? "No results")
            }
        }
        task.resume()
        
        runOnAfterTime(afterTime: 1.0) {
            
            self.links.remove(at: 0)
            let filteredLinks = self.links.filter { $0.contains("https://audio-ssl.itunes.appl") }
            print(filteredLinks.count)
            for i in 0..<self.results!.count{
                let result = self.results![i]
                let link = filteredLinks[i]
                self.addData(title: result["title"]!, link: link, price: result["im:price"]!, thumbImage: result["im:image"]!, artist: result["im:artist"]!)
            }
            self.fetchData()
        }
    }
    //MARK: ======== UITableViewDataSource ==============
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
        
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.songsArray.count
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat
    {
        return 70.0
        
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "SongTableViewCell", for: indexPath) as! SongTableViewCell
        
        let song = songsArray[indexPath.row]
        cell.titleLabel.text = song.title ?? ""
        
        let url = URL(string: song.thumbImage!)
        let data = try? Data(contentsOf: url!)
        
        if let imageData = data {
            let image = UIImage(data: imageData)
            cell.thumbImageView.image = image
        }
        
        
        cell.backgroundColor = .clear
        cell.contentView.backgroundColor = .clear
        cell.selectionStyle = .none
        return cell 
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let detailViewController = storyBoard.instantiateViewController(withIdentifier: "DetailViewController") as! DetailViewController
        detailViewController.song = songsArray[indexPath.row]
        self.navigationController?.pushViewController(detailViewController, animated: true)
        
    }
    //MARK: ======== XML Parsing ==============
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        
        if elementName == recordKey {
            
            currentDictionary = [String : String]()
        }else if elementName == "link" {
            
            if let linkName = attributeDict["href"] as String? {
                
                links.append(linkName)
            }
        } else if dictionaryKeys.contains(elementName) {
            
            currentValue = String()
            
        }
    }
    
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        
        currentValue? += string
        
    }
    
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        
        if elementName == recordKey {
            
            results?.append(currentDictionary!)
            currentDictionary = nil
            print(results!)
        }else if elementName == "link"{
            
        } else if dictionaryKeys.contains(elementName) {
            
            currentDictionary?[elementName] = currentValue
            currentValue = nil
            
        }
    }
    
    // Just in case, if there's an error, report it. (We don't want to fly blind here.)
    
    func parser(_ parser: XMLParser, parseErrorOccurred parseError: Error) {
        
        print(parseError)
        
        currentValue = nil
        currentDictionary = nil
        //results = nil
        
    }
    //MARK: ======== CoreData Operation ==============
    func addData(title:String,link:String,price:String,thumbImage:String,artist:String){
        let manageContent = appDelegate.persistentContainer.viewContext
        let userEntity = NSEntityDescription.entity(forEntityName: "Song", in: manageContent)!
        let song = NSManagedObject(entity: userEntity, insertInto: manageContent)
        
        song.setValue(title, forKeyPath: "title")
        song.setValue(link, forKeyPath: "link")
        song.setValue(price, forKeyPath: "price")
        song.setValue(thumbImage, forKeyPath: "thumbImage")
        song.setValue(artist, forKey: "artist")
        
        do{
            try manageContent.save()
            
        }catch let error as NSError {
            print("could not save . \(error), \(error.userInfo)")
            
        }
    }
    func fetchData(){
        
        let manageContent = appDelegate.persistentContainer.viewContext
        let fetchData = NSFetchRequest<NSFetchRequestResult>(entityName: "Song")
        
        do {
            let result = try manageContent.fetch(fetchData)
            let allData = result as! [NSManagedObject]
            for obj in allData{
                //let obj = allData[1]
                let song = Songs()
                song.title = (obj.value(forKey: "title") as! String)
                song.artist = (obj.value(forKey: "artist") as! String)
                song.price = (obj.value(forKey: "price") as! String)
                song.link = (obj.value(forKey: "link") as! String)
                song.thumbImage = (obj.value(forKey: "thumbImage") as! String)
                self.songsArray.append(song)
            }
            self.songTableView.reloadData()
            
        }catch {
            print("err")
        }
    }
}
