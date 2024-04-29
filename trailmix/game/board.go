package game

import (
	"bytes"
	"errors"
	"fmt"
	"math/rand"
	"strings"
	"text/template"
	"time"
)

var ErrInvalidColor error = errors.New("invalid color")
var ErrInvalidOpacity error = errors.New("invalid opacity")
var ErrInvalidParameter error = errors.New("invalid parameter")

type Coordinates struct {
	X float32
	Y float32
}

type HexagonParameters struct {
	Fill        string
	Opacity     string
	Stroke      string
	StrokeWidth string
	Vertices    string
	TextX       string
	TextY       string
	Text        string
	TextColor   string
	TextSize    string
	TextDY      string
	TerrainType uint
}

type SVGParameters struct {
	ViewBoxWidth  string
	ViewBoxHeight string
}

type HexagonalStripParameters struct {
	Horizontal float32
	Vertical   float32
}

type HexColor struct {
	Red   uint    `json:"red"`
	Green uint    `json:"green"`
	Blue  uint    `json:"blue"`
	Alpha float32 `json:"alpha"`
}

// Default color palette for the game board
// Colors and opacities for the following terrain types:
// 0. Plain
// 1. Forest
// 2. Swamp
// 3. Water
// 4. Mountain
// 5. Desert
// 6. Ice
var DefaultColors []HexColor = []HexColor{
	HexColor{Red: 166,
		Green: 237,
		Blue:  185,
		Alpha: 0.8,
	},
	HexColor{Red: 42,
		Green: 130,
		Blue:  22,
		Alpha: 0.8,
	},
	HexColor{Red: 81,
		Green: 89,
		Blue:  8,
		Alpha: 0.8,
	},
	HexColor{Red: 69,
		Green: 215,
		Blue:  245,
		Alpha: 0.8,
	},
	HexColor{Red: 83,
		Green: 92,
		Blue:  84,
		Alpha: 0.8,
	},
	HexColor{Red: 176,
		Green: 164,
		Blue:  111,
		Alpha: 0.8,
	},
	HexColor{Red: 170,
		Green: 228,
		Blue:  250,
		Alpha: 0.8,
	},
}

// 0. Forest
// 1. Prairie
// 2. River
// 3. Arctic
// 4. Marsh
// 5. Badlands
// 6. Hills
var Environments [7][7]uint = [7][7]uint{
	{0, 90, 8, 25, 5, 0, 0},
	{90, 5, 5, 20, 0, 8, 0},
	{0, 0, 8, 120, 0, 0, 0},
	{0, 8, 0, 0, 20, 0, 100},
	{5, 5, 98, 20, 0, 0, 0},
	{18, 0, 0, 0, 10, 100, 0},
	{0, 43, 0, 5, 80, 0, 0},
}

var point1 Coordinates = Coordinates{2, 0.86602540378}
var point2 Coordinates = Coordinates{1.5, 0}
var point3 Coordinates = Coordinates{0.5, 0}
var point4 Coordinates = Coordinates{0, 0.86602540378}
var point5 Coordinates = Coordinates{0.5, 1.73205080756}
var point6 Coordinates = Coordinates{1.5, 1.73205080756}

var points []Coordinates = []Coordinates{point1, point2, point3, point4, point5, point6}

var Boundary Coordinates = Coordinates{2, 1.73205080756}

func Preamble(width, height float32) (string, error) {
	params := SVGParameters{
		ViewBoxWidth:  fmt.Sprintf("%f", width),
		ViewBoxHeight: fmt.Sprintf("%f", height),
	}

	var b bytes.Buffer
	err := SVGStartTemplate.Execute(&b, params)
	return b.String(), err
}

func SingleHex(text string, x, y float32, red, green, blue uint, alpha float32, strokeRed, strokeGreen, strokeBlue uint, strokeWidth float32, textRed, textGreen, textBlue uint, textSize float32) (string, error) {
	if red > 255 || green > 255 || blue > 255 {
		return "", ErrInvalidColor
	}

	if alpha < 0 || alpha > 1 {
		return "", ErrInvalidOpacity
	}

	if strokeRed > 255 || strokeGreen > 255 || strokeBlue > 255 {
		return "", ErrInvalidColor
	}

	if strokeWidth < 0 {
		return "", ErrInvalidParameter
	}

	if textRed > 255 || textGreen > 255 || textBlue > 255 {
		return "", ErrInvalidColor
	}

	params := HexagonParameters{}
	params.Fill = fmt.Sprintf("#%02x%02x%02x", red, green, blue)
	params.Opacity = fmt.Sprintf("%f", alpha)
	params.Stroke = fmt.Sprintf("#%02x%02x%02x", strokeRed, strokeGreen, strokeBlue)
	params.StrokeWidth = fmt.Sprintf("%f", strokeWidth)
	params.Text = text
	params.TextX = fmt.Sprintf("%f", x+1.0)
	params.TextY = fmt.Sprintf("%f", y+point1.Y)
	params.TextColor = fmt.Sprintf("#%02x%02x%02x", textRed, textGreen, textBlue)
	params.TextSize = fmt.Sprintf("%f", textSize)
	params.TextDY = fmt.Sprintf("%f", textSize/3)

	pointsStr := make([]string, 6)
	for i, point := range points {
		pointsStr[i] = fmt.Sprintf("%f,%f", point.X+x, point.Y+y)
	}
	params.Vertices = strings.Join(pointsStr, " ")

	var b bytes.Buffer
	err := HexagonTemplate.Execute(&b, []HexagonParameters{params})

	return b.String(), err
}

func hexes(rng *rand.Rand, horizontalStrips uint, hexesPerStrip uint, start uint, palette []HexColor, strokeRed, strokeGreen, strokeBlue uint, strokeWidth float32) ([][]HexagonParameters, error) {
	strips := make([][]HexagonParameters, horizontalStrips)
	for i := 0; i < int(horizontalStrips); i++ {
		strips[i] = make([]HexagonParameters, hexesPerStrip)
	}

	for j := 0; j < int(hexesPerStrip); j++ {
		for i := 0; i < int(horizontalStrips); i++ {
			realJ := (int(hexesPerStrip) - 1 - j + int(start))
			environment := (3 * (realJ >> 5)) % 7

			if realJ%32 >= 28 {
				flip := rng.Intn(4)
				if flip != 0 {
					environment = (environment + 3) % 7
				}
			} else if realJ%32 >= 24 {
				flip := rng.Intn(2)
				if flip != 0 {
					environment = (environment + 3) % 7
				}
			} else if realJ%32 >= 16 {
				flip := rng.Intn(4)
				if flip == 3 {
					environment = (environment + 3) % 7
				}
			}

			terrainEntropy := rng.Intn(128)

			var terrainType uint = 6

			accumulator := 0
			for k := 0; k < 7; k++ {
				accumulator += int(Environments[environment][k])
				if terrainEntropy < accumulator {
					terrainType = uint(k)
					break
				}
			}

			colors := palette[terrainType]
			strips[i][j] = HexagonParameters{
				Fill:        fmt.Sprintf("#%02x%02x%02x", colors.Red, colors.Green, colors.Blue),
				Opacity:     fmt.Sprintf("%f", colors.Alpha),
				Stroke:      fmt.Sprintf("#%02x%02x%02x", strokeRed, strokeGreen, strokeBlue),
				StrokeWidth: fmt.Sprintf("%f", strokeWidth),
				TerrainType: terrainType,
			}

			pointsStr := make([]string, 6)
			for k, point := range points {
				pointsStr[k] = fmt.Sprintf("%f,%f", point.X+float32(j)*3, point.Y)
			}
			strips[i][j].Vertices = strings.Join(pointsStr, " ")
		}
	}

	return strips, nil
}

func HexagonalGrid(seed int64, horizontalStrips uint, hexesPerStrip uint, start uint, strokeRed, strokeGreen, strokeBlue uint, strokeWidth float32) (string, error) {
	if strokeRed > 255 || strokeGreen > 255 || strokeBlue > 255 {
		return "", ErrInvalidColor
	}

	if strokeWidth < 0 {
		return "", ErrInvalidParameter
	}

	if seed == 0 {
		seed = time.Now().UnixNano()
	}
	rng := rand.New(rand.NewSource(seed))

	result := ""

	strips, stripsErr := hexes(rng, horizontalStrips, hexesPerStrip, start, DefaultColors, strokeRed, strokeGreen, strokeBlue, strokeWidth)
	if stripsErr != nil {
		return result, stripsErr
	}

	for i := 0; i < int(horizontalStrips); i++ {
		horizontalOffset := 0.0
		if i%2 == 0 {
			horizontalOffset = 1.5
		}
		stripParams := HexagonalStripParameters{
			Horizontal: float32(horizontalOffset),
			Vertical:   float32(i) * point1.Y,
		}

		var gb bytes.Buffer
		gErr := GHexagonHorizontalStripTemplate.Execute(&gb, stripParams)
		if gErr != nil {
			return "", gErr
		}

		var sb bytes.Buffer
		stripErr := HexagonTemplate.Execute(&sb, strips[i])
		if stripErr != nil {
			return result, stripErr
		}

		result += gb.String() + sb.String() + GEnd
	}

	return result, nil
}

var SVGStartTemplateDefinition string = `<svg viewBox="0 0 {{.ViewBoxWidth}} {{.ViewBoxHeight}}" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">
`

var SVGStartTemplate *template.Template = template.Must(template.New("svg").Parse(SVGStartTemplateDefinition))

var SVGEnd string = "</svg>"

var GHexagonHorizontalStripTemplateDefinition string = `<g class="hexagonalstrip" transform="translate({{.Horizontal}}, {{.Vertical}})">
`

var GHexagonHorizontalStripTemplate *template.Template = template.Must(template.New("hexagonalstripg").Parse(GHexagonHorizontalStripTemplateDefinition))

var GEnd string = `</g>
`

var HexagonTemplateDefinition string = `{{range .}}
<polygon class="hexagon" fill="{{.Fill}}" opacity="{{.Opacity}}" stroke="{{.Stroke}}" stroke-width="{{.StrokeWidth}}" points="{{.Vertices}}"></polygon>
{{if .Text}}<text x="{{.TextX}}" y="{{.TextY}}" text-anchor="middle" fill="{{.TextColor}}" font-size="{{.TextSize}}" dy="{{.TextDY}}">{{.Text}}</text>{{end}}
{{end}}
`

var HexagonTemplate *template.Template = template.Must(template.New("hexagon").Parse(HexagonTemplateDefinition))
