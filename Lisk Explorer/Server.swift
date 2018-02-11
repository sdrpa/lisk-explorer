// Created by Sinisa Drpa on 2/10/18.

import Foundation
import SocketIO

struct Block: Decodable {
   let height: Int
   let totalAmount: Int
}

protocol ServerDelegate: class {
   func blocksDidChange(_ block: Block)
}

final class Server {
   weak var delegate: ServerDelegate?

   private let path = "https://node08.lisk.io:443"
   private let manager: SocketManager
   private let socket: SocketIOClient

   init() {
      guard let url = URL(string: path) else {
         fatalError()
      }
      self.manager = SocketManager(socketURL: url, config: [.log(false), .compress])
      self.socket = manager.defaultSocket
      self.run()
   }

   func run() {
      socket.on(clientEvent: .connect) { data, ack in
         print("socket connected")
      }
      socket.on(clientEvent: .disconnect) { data, ack in
         print("socket disconnected")
      }
      socket.on(clientEvent: .error) { data, ack in
         print("socket error")
      }
      socket.on(clientEvent: .statusChange) { data, ack in
         print("socket status changed")
      }

      socket.on("blocks/change") { data, ack in
         //print("----- \(Date()) -----")
         //print(data.first, ack)
         //print(String(repeatElement("-", count: 30)) + "\n")

         if let data = try? JSONSerialization.data(withJSONObject: data, options: .prettyPrinted) {
            do {
               let array = try JSONDecoder().decode(Array<Block>.self, from: data)
               guard let first = array.first else {
                  return
               }
               self.delegate?.blocksDidChange(first)
            } catch let e {
               print(e.localizedDescription)
            }
         } else {
            print("data is nil.")
         }


      }

      socket.connect()
   }
}
