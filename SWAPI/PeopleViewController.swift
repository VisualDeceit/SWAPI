//
//  PeopleViewController.swift
//  SWAPI
//
//  Created by Александр Фомин on 10.04.2022.
//

import UIKit

class PeopleViewController: UIViewController {
    
    @IBOutlet var peopleTableView: UITableView?
    
    var SWAPI: WebService?
    var people = [PeopleViewModel]()
    var nextPage: URL?
    var isLoading = false
    
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        peopleTableView?.prefetchDataSource = self
        peopleTableView?.register(UINib(nibName: "PeopleCell", bundle: nil),
                                  forCellReuseIdentifier: PeopleCell.reuseIdentifier)
        
        SWAPI = SWAPIService()
        SWAPI?.getPeople { [weak self] (people, nextPage) in
            guard let self = self else { return }
            self.people.append(contentsOf: people)
            self.nextPage = nextPage
            self.peopleTableView?.reloadData()
        }
    }
}

extension PeopleViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        people.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: PeopleCell.reuseIdentifier, for: indexPath) as? PeopleCell else {
            return UITableViewCell()
        }
       
        cell.configure(with: people[indexPath.row])
        return cell
    }
}

extension PeopleViewController: UITableViewDataSourcePrefetching {
    func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath]) {
            guard let maxItem = indexPaths.max()?.row else { return }
            
            if maxItem > self.people.count - 4, !self.isLoading  {
                self.isLoading = true
                
                SWAPI?.getPeople(page: self.nextPage) { [weak self] (people, nextPage) in
                    guard let self = self else { return }
                    
                    let indexPath = (self.people.count..<self.people.count + people.count).map { IndexPath(row: $0, section: 0) }
                    
                    self.people.append(contentsOf: people)
                    self.peopleTableView?.insertRows(at: indexPath, with: .bottom)
                    
                    self.nextPage = nextPage
                    
                    self.isLoading = false
            }
        }

    }
}
