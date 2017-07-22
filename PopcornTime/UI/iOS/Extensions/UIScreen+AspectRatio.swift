

import Foundation


extension UIScreen {
    
    var aspectRatio: String {
        let numbers = [bounds.width, bounds.height]
        
        // Normalize the input vector to that the maximum is 1.0,
        // and compute rational approximations of all components:
        let maximum = numbers.max()!
        let rats = numbers.map({($0/maximum).rationalApproximation})
        
        // Multiply all rational numbers by the LCM of the denominators:
        let commonDenominator = lcm(rats.map({$0.denominator}))
        let numerators = rats.map({$0.numerator * commonDenominator / $0.denominator})
        
        // Divide the numerators by the GCD of all numerators:
        let commonNumerator = gcd(numerators)
        return numerators.map({ String($0 / commonNumerator) }).joined(separator: ":")
    }
}
