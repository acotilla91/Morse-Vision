# Morse Vision
More Vision is a simple app that utilizes ARKit to interpret blinks as morse code which are then transcribed to text. Alternatively, touch input can be used as well.

![Demo](https://github.com/acotilla91/Morse-Vision/blob/master/more_vision_demo.gif)


## Requirements

- iOS device with a TrueDepth camera. *(A device with no TrueDepth camera can be used, but it will only support touch as the input mode)*
- Some morse code basis:
	- https://morse.withgoogle.com/learn/
	- https://en.wikipedia.org/wiki/Morse_code
- Comprehensive understanding of the morse code tree:
![Demo](https://upload.wikimedia.org/wikipedia/commons/1/19/Morse-code-tree.svg)


## How to use

1. Run the app.
2. Blink away (or tap, depending on the input mode).
	- "short" blink: dot.
	- "long" blink: dash.
3. To reset the transcribed text, tap on the transcription label.

## Configuration

- To adjust timing, see the `Timing` struct in `ViewController`.
- To use touch as the preferred input mode, update the `preferredInputMode` constant in `ViewController`.

## Author

Alejandro Cotilla, [@acotilla91](https://twitter.com/acotilla91)

## License

Morse Vision is available under the MIT license. See the LICENSE file for more info.
