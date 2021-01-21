//
//  DetailViewController.swift
//  Music
//
//  Created by Javed Multani on 12/01/21.
//

import UIKit
import AVFoundation
class DetailViewController: UIViewController {
    
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var artistLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var priceLabel: UILabel!
    @IBOutlet weak var thumbImage: UIImageView!
    @IBOutlet weak var volumeSlider: UISlider!
    @IBOutlet weak var songImage: UIImageView!
    
    var player = AVAudioPlayer()
    
    var song:Songs = Songs()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Music Preview"
        let gifImage = UIImage.gifImageWithName("equalizer2")
        self.songImage.image = gifImage
        
        thumbImage.layer.borderWidth = 2.0
        thumbImage.layer.borderColor = UIColor.white.cgColor
        
        self.artistLabel.text = song.artist
        self.titleLabel.text = song.title
        self.priceLabel.text = song.price
        let url = URL(string: song.thumbImage!)
        let data = try? Data(contentsOf: url!)
        
        if let imageData = data {
            let image = UIImage(data: imageData)
            self.thumbImage.image = image
        }
        
        // Do any additional setup after loading the view.
        
        self.downloadSound(url: URL(string:song.link!)!)
      
    }
    
    @IBAction func playPauseButtonHandlker(_ sender: Any) {
        if player.isPlaying{
            self.songImage.image = UIImage(named: "music")
            playButton.setBackgroundImage(UIImage(named: "playing"), for: .normal)
            player.pause()
        }else{
            let gifImage = UIImage.gifImageWithName("equalizer2")
            self.songImage.image = gifImage
            playButton.setBackgroundImage(UIImage(named: "pause"), for: .normal)
            player.play()
        }
        
    }
    @IBAction func setSongVolume(_ sender: Any) {
       
        player.setVolume(volumeSlider.value, fadeDuration: 0.01)
    }
  
    func downloadSound(url:URL){
        let docUrl:URL = (FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first as URL?)!
        let desURL = docUrl.appendingPathComponent("tmpsong.m4a")
        var downloadTask:URLSessionDownloadTask
        downloadTask = URLSession.shared.downloadTask(with: url, completionHandler: { [weak self](URLData, response, error) -> Void in
            do{
                let isFileFound:Bool? = FileManager.default.fileExists(atPath: desURL.path)
                if isFileFound == true{
                    
                    try FileManager.default.removeItem(atPath: desURL.path)
                    try FileManager.default.copyItem(at: URLData!, to: desURL)
                } else {
                    
                    try FileManager.default.copyItem(at: URLData!, to: desURL)
                }
                let sPlayer = try AVAudioPlayer(contentsOf: desURL)
                self?.player = sPlayer
                self?.player.prepareToPlay()
                self?.player.play()
                
            }catch let err {
                print(err.localizedDescription)
            }
            
        })
        downloadTask.resume()
    }
    
}
