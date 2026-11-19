# mojo-ui

mojo-ui is a small software rendering and UI library built from scratch in
Mojo. It draws into memory and writes PNGs, so examples and pixel tests can run
headlessly without a window server, GPU, or image codec dependency.

## Build and run

Install [Pixi](https://pixi.sh/latest/installation/), then run these commands from
the repository root. Pixi installs the locked Mojo 1.2 toolchain from Modular's
stable channel.

```sh
pixi install --locked
pixi run build
pixi run test
pixi run example
```

The build produces `build/mojo_ui.mojoc`. To run a Mojo program that imports the
package, use `pixi run mojo run -I build path/to/program.mojo`. Use `-I src` to
import the package directly from source.

The [demo](examples/demo.mojo) draws a rounded panel, a title, and two buttons
and writes `examples/out/demo.png`. Open that file in any PNG viewer.

## Learn the architecture

The [mojo-ui field guide](https://amirhosseindavoody.github.io/mojo-ui/) follows
a frame through the source and includes exercises on rendering and performance.
Open [docs/index.html](docs/index.html) to read the same pages locally.

## Architecture

- `geometry.mojo` defines integer points, sizes, padding, and half-open
  rectangles. Pixel coordinates start at the upper-left corner.
- `color.mojo` defines straight-alpha RGBA colors and source-over blending.
- `raster.mojo` owns the framebuffer and clips filled and stroked rectangles,
  lines, rounded rectangles, and text to its bounds. `clear` replaces all pixels.
- `font.mojo` provides a 5×7 bitmap font. It supports uppercase letters,
  digits, and basic punctuation, maps lowercase to uppercase, and uses a
  question mark for unsupported characters.
- `png.mojo` encodes straight-alpha RGBA PNGs with stored DEFLATE blocks.
- `ui.mojo` provides immediate-mode layout. A horizontal or vertical `Stack`
  allocates rectangles in order with optional padding and spacing. `Label` and
  `Button` report their preferred sizes and draw into their assigned rectangles.

For example, measure a label and draw it in a padded vertical stack.

```mojo
from mojo_ui import Color, Framebuffer, Insets, Label, Stack


def main() raises:
    var frame = Framebuffer(160, 60)
    frame.clear(Color.rgb(17, 23, 36))
    var layout = Stack.vertical(frame.bounds(), padding=Insets.uniform(8))
    var title = Label("HELLO MOJO", scale=2)
    title.draw(frame, layout.place(title.size()))
    frame.write_png("hello.png")
```

## Roadmap

- Add a window host through SDL or GLFW C FFI. It would handle the window,
  input, and frame presentation while the software rasterizer draws the pixels.
- Connect pointer and keyboard events to widgets. Buttons currently draw their
  background and label.
- Explore a GPU backend once the window host and drawing API are in place.

Released under the [MIT License](LICENSE).
