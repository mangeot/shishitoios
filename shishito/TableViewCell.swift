//
//  TableViewCell.swift
//  shishito
//
//  Created by Mathieu Mangeot on 06/12/2016.
//  Copyright © 2016 Université Savoie Mont Blanc. All rights reserved.
//

import UIKit

class TableViewCell: UITableViewCell {

    @IBOutlet weak var jpn: UILabel!
    @IBOutlet weak var hiragana: UILabel!
    @IBOutlet weak var romaji: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
