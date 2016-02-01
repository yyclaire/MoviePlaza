//
//  MoviesViewController.swift
//  MoviePlaza
//
//  Created by Lily on 1/10/16.
//  Copyright © 2016 yyclaire. All rights reserved.
//

import UIKit
import AFNetworking
import PKHUD
import Foundation
import SystemConfiguration

class MoviesViewController: UIViewController,UICollectionViewDataSource,UICollectionViewDelegate,UISearchBarDelegate,UIScrollViewDelegate {

    @IBOutlet weak var moviesCollectionView: UICollectionView!
    var movies: [NSDictionary]?
    var refreshControl: UIRefreshControl!
    
    @IBOutlet weak var searchBar: UISearchBar!
    //search bar
    var filteredData:[NSDictionary]?
    var data: [NSDictionary]?
    
    @IBOutlet weak var networkFailureLabel: UILabel!
   
    @IBOutlet weak var scrollView: UIScrollView!
    var endpoint: String!
    
     var isMoreDataLoading = false
     var loadingMoreView:InfiniteScrollViewActivityView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //navigation bar decoration
       // self.title = "Movie Plaza"
        
        moviesCollectionView.dataSource = self
        moviesCollectionView.delegate = self
        self.navigationItem.title = "Movie Plaza"
        // Do any additional setup after loading the view.
        let apiKey = "a07e22bc18f5cb106bfe4cc1f83ad8ed"
        let url = NSURL(string:"https://api.themoviedb.org/3/movie/\(endpoint)?api_key=\(apiKey)")
        let request = NSURLRequest(URL: url!)
        let session = NSURLSession(
            configuration: NSURLSessionConfiguration.defaultSessionConfiguration(),
            delegate:nil,
            delegateQueue:NSOperationQueue.mainQueue()
        )
        
        let task : NSURLSessionDataTask = session.dataTaskWithRequest(request,
            completionHandler: { (dataOrNil, response, error) in
                if let data = dataOrNil {
                    if let responseDictionary = try! NSJSONSerialization.JSONObjectWithData(
                        data, options:[]) as? NSDictionary {
                            NSLog("response: \(responseDictionary)")
                            self.movies = responseDictionary["results"] as? [NSDictionary]
                            self.filteredData = self.movies //????
                            self.moviesCollectionView.reloadData()
                    }
                }
        });
        task.resume()
        
        //refresh Control
        refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: "onRefresh", forControlEvents: UIControlEvents.ValueChanged)
        moviesCollectionView.insertSubview(refreshControl, atIndex: 0)
        
        //search
        print(filteredData)
        searchBar.delegate = self
        
        //network failure
        self.view.bringSubviewToFront(networkFailureLabel)
        checkNetwork()
        
        // Set up Infinite Scroll loading indicator
        let frame = CGRectMake(0, moviesCollectionView.contentSize.height, moviesCollectionView.bounds.size.width, InfiniteScrollViewActivityView.defaultHeight)
        loadingMoreView = InfiniteScrollViewActivityView(frame: frame)
        loadingMoreView!.hidden = true
        moviesCollectionView.addSubview(loadingMoreView!)
        
        var insets = moviesCollectionView.contentInset;
        insets.bottom += InfiniteScrollViewActivityView.defaultHeight;
        moviesCollectionView.contentInset = insets
        
    }
    
    override func viewWillAppear(animated: Bool) {
        PKHUD.sharedHUD.contentView = PKHUDProgressView()
        PKHUD.sharedHUD.show()
        
        let delayTime = dispatch_time(DISPATCH_TIME_NOW, Int64(2.0 * Double(NSEC_PER_SEC)))
        dispatch_after(delayTime, dispatch_get_main_queue()) {
            PKHUD.sharedHUD.contentView = PKHUDSuccessView()
            PKHUD.sharedHUD.hide(afterDelay: 2.0)
        }
        
    }


    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int{
        if let filteredData = filteredData{
            return filteredData.count
        }else{
            return 0
       }
    }
    
    // The cell that is returned must be retrieved from a call to -dequeueReusableCellWithReuseIdentifier:forIndexPath:
  
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell{
        let cell = moviesCollectionView.dequeueReusableCellWithReuseIdentifier("MovieCell", forIndexPath: indexPath) as! MovieCell
        let movie = filteredData![indexPath.row]
        let title = movie["title"] as! String
        //image url
        let baseUrl = "https://image.tmdb.org/t/p/w342"
        let posterUrl = movie["poster_path"] as! String
        let imageUrl = NSURL(string:baseUrl + posterUrl)
        cell.titleButton.setTitle(title, forState: .Normal)
        getPoster(imageUrl!, cell:cell)
        print(indexPath.row)
        return cell

    
    }
    func getPoster(imageURL:NSURL,cell:MovieCell)->Void{
        let imageRequest = NSURLRequest(URL:imageURL)
        cell.posterView.setImageWithURLRequest(
            imageRequest,
            placeholderImage:nil,
            success:{ (imageRequest,imageResponse,image) -> Void in
                if imageResponse != nil{
                    print("image was not cached,fade in image")
                    cell.posterView.alpha = 0.0
                    cell.posterView.image = image
                    UIView.animateWithDuration(3, animations: {()-> Void in
                        cell.posterView.alpha = 1.0
                    })
                }else{
                    print("image was cached so just update the image")
                    cell.posterView.image = image
                }
            
            },
            failure:{(imageRequest,imageResponse,error)->Void in
                //do something
            })
    }
    
    func delay(delay:Double, closure:()->()) {
        dispatch_after(
            dispatch_time(
                DISPATCH_TIME_NOW,
                Int64(delay * Double(NSEC_PER_SEC))
            ),
            dispatch_get_main_queue(), closure)
    }
    //func for refreshControl
    func onRefresh() {
        delay(2, closure: {
            self.refreshControl.endRefreshing()
        })
    }
    
    func loadMoreData() {
        
        // ... Create the NSURLRequest (myRequest) ...
        let apiKey = "a07e22bc18f5cb106bfe4cc1f83ad8ed"
        let url = NSURL(string:"https://api.themoviedb.org/3/movie/\(endpoint)?api_key=\(apiKey)")
        let myRequest = NSURLRequest(URL: url!)
        
        // Configure session so that completion handler is executed on main UI thread
        let session = NSURLSession(
            configuration: NSURLSessionConfiguration.defaultSessionConfiguration(),
            delegate:nil,
            delegateQueue:NSOperationQueue.mainQueue()
        )
        let task : NSURLSessionDataTask = session.dataTaskWithRequest(myRequest,
            completionHandler: { (dataOrNil, response, error) in
                self.isMoreDataLoading = false
                self.loadingMoreView!.stopAnimating()
                if let data = dataOrNil {
                    
                    if let responseDictionary = try! NSJSONSerialization.JSONObjectWithData(
                        data, options:[]) as? NSDictionary {
                            NSLog("response: \(responseDictionary)")
                            self.movies = responseDictionary["results"] as? [NSDictionary]
                            self.filteredData = self.movies //????
                            self.moviesCollectionView.reloadData()
                    }
                }
        });
        task.resume()
    }

    func scrollViewDidScroll(scrollView: UIScrollView) {
        // Handle scroll behavior here
        if (!isMoreDataLoading) {
            // Calculate the position of one screen length before the bottom of the results
            let scrollViewContentHeight = moviesCollectionView.contentSize.height
            let scrollOffsetThreshold = scrollViewContentHeight - moviesCollectionView.bounds.size.height
            
            // When the user has scrolled past the threshold, start requesting
            if(scrollView.contentOffset.y > scrollOffsetThreshold && moviesCollectionView.dragging) {
                isMoreDataLoading = true
                
                // Update position of loadingMoreView, and start loading indicator
                let frame = CGRectMake(0,moviesCollectionView.contentSize.height, moviesCollectionView.bounds.size.width, InfiniteScrollViewActivityView.defaultHeight)
                loadingMoreView?.frame = frame
                loadingMoreView!.startAnimating()
                
                // Code to load more results
                loadMoreData()		
            }
        }
    }
   
     //func for search
    func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {
        filteredData = searchText.isEmpty ? movies: movies!.filter({(movie:NSDictionary)->Bool in
            let title = movie["title"] as? String
            return title!.rangeOfString(searchText, options: .CaseInsensitiveSearch) != nil
        })
        moviesCollectionView.reloadData()
    }
    func searchBarTextDidBeginEditing(searchBar: UISearchBar){
        self.searchBar.showsCancelButton = true
    }
    
    func searchBarCancelButtonClicked(searchBar: UISearchBar) {
        self.searchBar.showsCancelButton = false
        searchBar.text = ""
        searchBar.resignFirstResponder()
    }
    
    
    @IBAction func onTap(sender: AnyObject) {
        view.endEditing(true)
    }
    //functions for network failure alert
//    func alert(){
//        let networkAlert = UIAlertController(title: "Network_Error", message: "!Network Error", preferredStyle:.Alert)
//        let delayTime = dispatch_time(DISPATCH_TIME_NOW,
//            Int64(3 * Double(NSEC_PER_SEC)))
//        dispatch_after(delayTime, dispatch_get_main_queue()) {
//             self.presentViewController(networkAlert, animated: true, completion: nil)
//        }
//       
    
    
    func isConnected()->Bool{
        return Reachability.isConnectedToNetwork()
    }

    func checkNetwork(){
        if !isConnected(){
            networkFailureLabel.hidden = false
        }else{
             networkFailureLabel.hidden = true
        }
    }
    
     override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "toDetailView"{
            //get movie data
            let movieCell = sender!.superview!!.superview as! MovieCell
            let indexPath = moviesCollectionView.indexPathForCell(movieCell)
            let movie = movies![indexPath!.row]
            print("indexPath:\(movie["title"])")
            //send data
            let DestVC: DetailViewController = segue.destinationViewController as! DetailViewController
            DestVC.movie = movie
        }
        
    }
    



    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */


}