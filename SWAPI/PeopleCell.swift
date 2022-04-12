//
//  PeopleCell.swift
//  SWAPI
//
//  Created by Александр Фомин on 10.04.2022.
//

import UIKit

class PeopleCell: UITableViewCell {
    
    static let reuseIdentifier = "peopleCell"
    
    @IBOutlet var nameLabel: UILabel?
    @IBOutlet var homeWorldLabel: UILabel?
    @IBOutlet var specieLabel: UILabel?
    
    func configure(with viewModel: PeopleViewModel) {
        nameLabel?.text = viewModel.name
        specieLabel?.text = viewModel.species
        homeWorldLabel?.text = viewModel.homeworld
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        nameLabel?.text = nil
        specieLabel?.text = nil
        homeWorldLabel?.text = nil
    }
}
