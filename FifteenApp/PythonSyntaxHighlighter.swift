//
//  PythonSyntaxHighlighter.swift
//  FifteenApp
//
//  Created by sophie on 2026-05-13.
//

//
//  PythonSyntaxHighlighter.swift
//  FifteenApp
//
//  Created by sophie on 2026-05-13.
//

import UIKit

// MARK: - Python Syntax Highlighter
class PythonSyntaxHighlighter {
    static func highlight(_ code: String) -> NSAttributedString {
        let attributedString = NSMutableAttributedString(string: code)
        
        // Define color scheme
        let keywordColor = UIColor(red: 0.85, green: 0.26, blue: 0.85, alpha: 1.0) // Magenta
        let stringColor = UIColor(red: 0.25, green: 0.68, blue: 0.34, alpha: 1.0)   // Green
        let numberColor = UIColor(red: 1.0, green: 0.63, blue: 0.0, alpha: 1.0)     // Orange
        let commentColor = UIColor(red: 0.63, green: 0.63, blue: 0.63, alpha: 1.0)  // Gray
        let functionColor = UIColor(red: 0.0, green: 0.62, blue: 0.89, alpha: 1.0)  // Blue
        let defaultColor = UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)     // White
        
        // Python keywords
        let keywords = [
            "def", "class", "if", "else", "elif", "for", "while", "return", "import",
            "from", "as", "try", "except", "finally", "with", "lambda", "yield",
            "pass", "break", "continue", "raise", "assert", "del", "in", "is",
            "and", "or", "not", "True", "False", "None", "self", "async", "await"
        ]
        
        let baseFont = UIFont(name: "Menlo", size: 11) ?? UIFont.monospacedSystemFont(ofSize: 11, weight: .regular)
        
        // First, set default color for entire string
        attributedString.addAttribute(.foregroundColor, value: defaultColor, range: NSRange(location: 0, length: attributedString.length))
        attributedString.addAttribute(.font, value: baseFont, range: NSRange(location: 0, length: attributedString.length))
        
        // Highlight comments
        highlightPattern(attributedString, pattern: "#.*?(?=\\n|$)", color: commentColor, font: baseFont)
        
        // Highlight strings (both single and double quoted, including triple quotes)
        highlightPattern(attributedString, pattern: "\"\"\"(?:[^\\\\]|\\\\.)*?\"\"\"", color: stringColor, font: baseFont)
        highlightPattern(attributedString, pattern: "'''(?:[^\\\\]|\\\\.)*?'''", color: stringColor, font: baseFont)
        highlightPattern(attributedString, pattern: "\"(?:[^\"\\\\]|\\\\.)*\"", color: stringColor, font: baseFont)
        highlightPattern(attributedString, pattern: "'(?:[^'\\\\]|\\\\.)*'", color: stringColor, font: baseFont)
        
        // Highlight numbers (integers, floats, hex, binary, octal)
        highlightPattern(attributedString, pattern: "\\b(0[xX][0-9a-fA-F]+|0[bB][01]+|0[oO][0-7]+|\\d+\\.\\d*|\\.\\d+|\\d+[jJ]?)\\b", color: numberColor, font: baseFont)
        
        // Highlight keywords
        for keyword in keywords {
            let pattern = "\\b\(keyword)\\b"
            highlightPattern(attributedString, pattern: pattern, color: keywordColor, font: baseFont)
        }
        
        // Highlight function definitions
        highlightPattern(attributedString, pattern: "(?<=def )\\w+", color: functionColor, font: baseFont)
        highlightPattern(attributedString, pattern: "(?<=class )\\w+", color: functionColor, font: baseFont)
        
        // Highlight built-in functions
        let builtins = ["print", "len", "range", "str", "int", "float", "list", "dict", "set", "tuple", "open", "enumerate", "zip", "map", "filter"]
        for builtin in builtins {
            let pattern = "\\b\(builtin)\\s*(?=\\()"
            highlightPattern(attributedString, pattern: pattern, color: functionColor, font: baseFont)
        }
        
        return attributedString
    }
    
    private static func highlightPattern(_ attributedString: NSMutableAttributedString, pattern: String, color: UIColor, font: UIFont) {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else { return }
        
        let range = NSRange(location: 0, length: attributedString.length)
        let matches = regex.matches(in: attributedString.string, options: [], range: range)
        
        for match in matches {
            attributedString.addAttribute(.foregroundColor, value: color, range: match.range)
            attributedString.addAttribute(.font, value: font, range: match.range)
        }
    }
}
