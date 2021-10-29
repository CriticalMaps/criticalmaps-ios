import Foundation
import SharedModels

public struct SendLocationAndChatMessagesPostBody: Encodable {
  public init(
    device: String,
    location: Location? = nil,
    messages: [SendChatMessage]? = nil
  ) {
    self.device = device
    self.location = location
    self.messages = messages
  }
  
  public let device: String
  public let location: Location?
  public var messages: [SendChatMessage]?
}
