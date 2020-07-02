import Flutter
import TwilioVideo

public protocol OnDidSubscribeToVideoTrackListener: NSObjectProtocol, FlutterStreamHandler {
  func onDidSubscribeToVideoTrack(room: Room)
}

public class OnDidSubscribeToVideoTrackListenerImpl: NSObject, OnDidSubscribeToVideoTrackListener {
  public static let CHANNEL_NAME: String = "com.example/did_subscribe_to_video_track"
  public var eventSink: FlutterEventSink?

  public func onDidSubscribeToVideoTrack(room: Room) {
    eventSink?(room)
  }

  public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    eventSink = events
    return nil
  }

  public func onCancel(withArguments arguments: Any?) -> FlutterError? {
    eventSink = nil
    return nil
  }
}
