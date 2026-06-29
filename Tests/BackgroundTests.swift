import XCTest
import UIKit
// BackgroundService.swift compiled into this test target.

final class BackgroundTests: XCTestCase {
    /// A clear subject (dark circle) on a white field.
    private func subjectImage(_ s: CGFloat = 400) -> UIImage {
        let f = UIGraphicsImageRendererFormat.default(); f.scale = 1
        return UIGraphicsImageRenderer(size: CGSize(width: s, height: s), format: f).image { ctx in
            UIColor.white.setFill(); ctx.fill(CGRect(x: 0, y: 0, width: s, height: s))
            UIColor.black.setFill(); ctx.cgContext.fillEllipse(in: CGRect(x: s*0.25, y: s*0.25, width: s*0.5, height: s*0.5))
        }
    }

    func testOptionCatalog() {
        XCTAssertGreaterThanOrEqual(BGOption.all.count, 2)
        XCTAssertNil(BGOption.all[0].color)          // first option is transparent
    }

    func testRemoveBackgroundRunsGracefully() async {
        do {
            let out = try await BackgroundRemoverService().removeBackground(from: subjectImage(), option: BGOption.all[1])
            XCTAssertNotNil(out.cgImage)
        } catch BGError.noSubject {
            // acceptable if the synthetic shape isn't classified as a salient subject
        } catch {
            XCTFail("unexpected error: \(error)")
        }
    }
}
