//
//  DetailViewController.swift
//  MoviePlaza
//
//  Created by Lily on 1/17/16.
//  Copyright © 2016 yyclaire. All rights reserved.
//

import UIKit

class DetailViewController: UIViewController {
    
    @IBOutlet weak var posterImageView: UIImageView!
    
    @IBOutlet weak var movieTitle: UILabel!
    
    @IBOutlet weak var releaseDate: UILabel!
    
    @IBOutlet weak var movieOverview: UILabel!
    
    @IBOutlet weak var scrollView: UIScrollView!
    
    @IBOutlet weak var infoView: UIView!
    
    var movie: NSDictionary?
    override func viewDidLoad(){
         super.viewDidLoad()
         setUp()
    }
    
    func setUp(){
        //scrollView
        scrollView.contentSize = CGSize(width: scrollView.frame.size.width, height: infoView.frame.origin.y+infoView.frame.size.height)
        //set view title
        self.title = movie!["title"] as? String
        //set image
        let baseUrl = "https://image.tmdb.org/t/p/w342"
        let posterUrl = movie!["poster_path"] as! String
        let imageUrl = NSURL(string:baseUrl + posterUrl)
        self.posterImageView.setImageWithURL(imageUrl!)
        //set title
        self.movieTitle.text = " Title: \(movie!["title"] as! String)"
        //set releaseDate
        self.releaseDate.text = " Release date: \(movie!["release_date"] as! String)"
        //set overview
        
        self.movieOverview.text = " Synopsis: \(movie!["overview"] as! String)"
        self.movieOverview.sizeToFit()
        
        
    }
}
