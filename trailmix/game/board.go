package game

import (
	"bytes"
	"errors"
	"fmt"
	"strings"
	"text/template"
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
}

type SVGParameters struct {
	ViewBoxWidth  string
	ViewBoxHeight string
}

type HexagonalStripParameters struct {
	Horizontal float32
	Vertical   float32
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

var SVGEnd string = "</svg>"

func SingleHex(x, y float32, red, green, blue uint, alpha float32, strokeRed, strokeGreen, strokeBlue uint, strokeWidth float32) (string, error) {
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

	params := HexagonParameters{}
	params.Fill = fmt.Sprintf("#%02x%02x%02x", red, green, blue)
	params.Opacity = fmt.Sprintf("%f", alpha)
	params.Stroke = fmt.Sprintf("#%02x%02x%02x", strokeRed, strokeGreen, strokeBlue)
	params.StrokeWidth = fmt.Sprintf("%f", strokeWidth)

	pointsStr := make([]string, 6)
	for i, point := range points {
		pointsStr[i] = fmt.Sprintf("%f,%f", point.X+x, point.Y+y)
	}
	params.Vertices = strings.Join(pointsStr, " ")

	var b bytes.Buffer
	err := HexagonTemplate.Execute(&b, []HexagonParameters{params})

	return b.String(), err
}

func HexagonalGrid(horizontalStrips uint, hexesPerStrip uint, red, green, blue uint, alpha float32, strokeRed, strokeGreen, strokeBlue uint, strokeWidth float32) (string, error) {
	hexagonParameters := make([]HexagonParameters, hexesPerStrip)
	for i := 0; i < int(hexesPerStrip); i++ {
		hexagonParameters[i] = HexagonParameters{
			Fill:        fmt.Sprintf("#%02x%02x%02x", red, green, blue),
			Opacity:     fmt.Sprintf("%f", alpha),
			Stroke:      fmt.Sprintf("#%02x%02x%02x", strokeRed, strokeGreen, strokeBlue),
			StrokeWidth: fmt.Sprintf("%f", strokeWidth),
		}

		pointsStr := make([]string, 6)
		for j, point := range points {
			pointsStr[j] = fmt.Sprintf("%f,%f", point.X+float32(i)*3, point.Y)
		}
		hexagonParameters[i].Vertices = strings.Join(pointsStr, " ")
	}

	var b bytes.Buffer
	stripErr := HexagonTemplate.Execute(&b, hexagonParameters)
	if stripErr != nil {
		return "", stripErr
	}
	stripDefinition := b.String()

	result := ""

	for i := 0; i < int(horizontalStrips); i++ {
		horizontalOffset := 0.0
		if i%2 == 1 {
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

		result += gb.String() + stripDefinition + GEnd
	}

	return result, nil
}

var SVGStartTemplateDefinition string = `<svg viewBox="0 0 {{.ViewBoxWidth}} {{.ViewBoxHeight}}" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">
`

var SVGStartTemplate *template.Template = template.Must(template.New("svg").Parse(SVGStartTemplateDefinition))

var GHexagonHorizontalStripTemplateDefinition string = `<g class="hexagonalstrip" transform="translate({{.Horizontal}}, {{.Vertical}})">
`

var GHexagonHorizontalStripTemplate *template.Template = template.Must(template.New("hexagonalstripg").Parse(GHexagonHorizontalStripTemplateDefinition))

var GEnd string = `</g>
`

var HexagonTemplateDefinition string = `{{range .}}
<polygon class="hexagon" fill="{{.Fill}}" opacity="{{.Opacity}}" stroke="{{.Stroke}}" stroke-width="{{.StrokeWidth}}" points="{{.Vertices}}"></polygon>
{{end}}
`

var HexagonTemplate *template.Template = template.Must(template.New("hexagon").Parse(HexagonTemplateDefinition))
