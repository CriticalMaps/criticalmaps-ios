import SnapshotTesting
import SwiftUI
import XCTest

private let operatingSystemVersion = ProcessInfo().operatingSystemVersion

public extension XCTestCase {
  private func enforceSnapshotDevice() {
    let is2XDevice = UIScreen.main.scale >= 2
    let isMinVersion16 = operatingSystemVersion.majorVersion >= 16
    
    guard is2XDevice, isMinVersion16 else {
      fatalError("Screenshot test device should use @2x screen scale and iOS 14.4")
    }
  }
  
  private static let sloppyPrecision: Float = 0.95
  
  func assertScreenSnapshot(
    _ view: some View,
    sloppy: Bool = false,
    file: StaticString = #file,
    testName: String = #function,
    line: UInt = #line
  ) {
    enforceSnapshotDevice()
    
    let precision: Float = (sloppy ? XCTestCase.sloppyPrecision : 1)
    
    withSnapshotTesting(diffTool: .ksdiff) {
      assertSnapshots(
        of: view,
        as: [
          .image(
            precision: precision,
            perceptualPrecision: precision,
            layout: .device(config: .iPhone13),
            traits: .iPhone13(.portrait)
          )
        ],
        file: file,
        testName: testName,
        line: line
      )
    }
  }
  
  func assertViewSnapshot(
    _ view: some View,
    height: CGFloat? = nil,
    width: CGFloat = 375,
    sloppy: Bool = false,
    file: StaticString = #file,
    testName: String = #function,
    line: UInt = #line
  ) {
    enforceSnapshotDevice()
    
    var layout = SwiftUISnapshotLayout.device(config: .iPhone8)
    if let height {
      layout = .fixed(width: width, height: height)
    }
    let precision: Float = (sloppy ? XCTestCase.sloppyPrecision : 1)
    
    withSnapshotTesting(diffTool: .ksdiff) {
      assertSnapshot(
        of: view,
        as: .image(precision: precision, layout: layout),
        file: file,
        testName: testName,
        line: line
      )
    }
  }
}
