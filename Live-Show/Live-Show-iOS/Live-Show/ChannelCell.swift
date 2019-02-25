//
//  ChannelCell.swift
//  Live-Show
//
//  Created by GongYuhua on 2019/2/25.
//  Copyright © 2019 Agora. All rights reserved.
//

import UIKit

class ChannelCell: UITableViewCell {
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var countLabel: UILabel!
    
    func updateCell(with channel: Channel) {
        nameLabel.text = "\(channel.channelName)"
        countLabel.text = "\(channel.count)"
    }
}
