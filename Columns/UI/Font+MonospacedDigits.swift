import UIKit

extension UIFont {
    var monospacedDigitFont: UIFont
    {
        return UIFont(descriptor: fontDescriptor.addingAttributes([UIFontDescriptor.AttributeName.featureSettings: [[UIFontDescriptor.FeatureKey.featureIdentifier: kNumberSpacingType, UIFontDescriptor.FeatureKey.typeIdentifier: kMonospacedNumbersSelector]]]), size: 0)
    }
}
