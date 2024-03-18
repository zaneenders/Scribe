//
//  AnsiCode.swift
//
//
//  Created by Zane Enders on 11/17/21.
//

/// Ansi Codes
/// This is only used as a output translation.
/// [](https://gist.github.com/fnky/458719343aabd01cfb17a3a4f7296797)
//!!!: Can we turn this into a DSL
enum AnsiCode: String {

    case esc = "\u{001b}["
    case reset = "\u{001b}[0m"
    case home = "\u{001b}[H"  // moves cursor to home position (0, 0)
    case eraseScreen = "\u{001b}[2J"
    case eraseSaved = "\u{001b}[3J"
    case defaultColor = "\u{001b}[1;39m"
    //    ESC[{line};{column}H
    //    ESC[{line};{column}f    moves cursor to line #, column #
    //    ESC[J    erase in display (same as ESC[0J)
    //    ESC[0J    erase from cursor until end of screen
    //    ESC[1J    erase from cursor to beginning of screen
    //    ESC[2J    erase entire screen
    //    ESC[3J    erase saved lines
    //    ESC[K    erase in line (same as ESC[0K)
    //    ESC[0K    erase from cursor to end of line
    //    ESC[1K    erase start of line to the cursor
    //    ESC[2K    erase the entire line

    enum Border: String {
        case topLeft = "\u{250F}"
        case topRight = "\u{2513}"
        case bottomLeft = "\u{2517}"
        case bottomRight = "\u{251B}"
        case horizontal = "\u{2501}"
        case vertical = "\u{2503}"
    }

    enum Cursor: String {
        case hide = "\u{001b}[?25l"
        case show = "\u{001b}[?25h"

        enum Move: String {
            case up = "\u{001b}[A"
            case down = "\u{001b}[B"
            case right = "\u{001b}[C"
            case left = "\u{001b}[D"
        }
        /// Cursor Specific Ansi Codes
        ///
        /// 1  blinking block (default).
        /// 2  steady block.
        /// 3  blinking underline.
        /// 4  steady underline.
        /// 5  blinking bar, xterm.
        /// 6  steady bar, xterm.

        enum Style {
            enum Block: String {
                case blinking = "\u{001b}[1 q"
                case steady = "\u{001b}[2 q"
            }
            enum Underline: String {
                case blinking = "\u{001b}[3 q"
                case steady = "\u{001b}[4 q"
            }
            enum Bar: String {
                case blinking = "\u{001b}[5 q"
                case steady = "\u{001b}[6 q"
            }
        }
    }

    enum Style: String {
        case bold = "\u{001b}[1m"
        case underline = "\u{001b}[4m"
        case reversed = "\u{001b}[7m"
    }

    //TODO: add more colors
    ///[](https://www.lihaoyi.com/post/BuildyourownCommandLinewithANSIescapecodes.html
    enum Color: String {
        case lightBlue = "\u{001b}[38;5;122m"
        case red = "\u{001b}[31m"
        case black = "\u{001b}[30m"
        case green = "\u{001b}[32m"
        case yellow = "\u{001b}[33m"
        case lightYellow = "\u{0016}[33;1m"
        case blue = "\u{001b}[34m"
        case magenta = "\u{001b}[35m"
        case cyan = "\u{001b}[36m"
        case white = "\u{001b}[38;5;15m"
        case orange = "\u{001b}[31;1m"
    }

    enum Charter: String {
        case arrowRight = "\u{2192}"
    }

    static func foregroundColor(_ value: Int) -> String {
        "\u{001b}[38;5;\(value)m"
    }

    static func backgroundColor(_ value: Int) -> String {
        "\u{001b}[48;5;\(value)m"
    }

    static func goTo(_ x: Int = 0, _ y: Int = 0) -> String {
        // I don't understand why this off by one
        // top left seems to be off by one vertically
        return "\u{001b}[\(y);\(x)H"
    }
}
