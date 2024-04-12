package main

import (
	"os"

	"github.com/spf13/cobra"

	"github.com/moonstream-to/degen-trail/trailmix/game"
	"github.com/moonstream-to/degen-trail/trailmix/version"
)

func CreateRootCommand() *cobra.Command {
	// rootCmd represents the base command when called without any subcommands
	rootCmd := &cobra.Command{
		Use:   "trailmix",
		Short: "trailmix: The Degen Trail CLI",
		Run: func(cmd *cobra.Command, args []string) {
			cmd.Help()
		},
	}

	completionCmd := CreateCompletionCommand(rootCmd)
	versionCmd := CreateVersionCommand()
	boardCmd := CreateBoardCommand()
	hexCmd := CreateHexCommand()
	rootCmd.AddCommand(completionCmd, versionCmd, boardCmd, hexCmd)

	// By default, cobra Command objects write to stderr. We have to forcibly set them to output to
	// stdout.
	rootCmd.SetOut(os.Stdout)

	return rootCmd
}

func CreateCompletionCommand(rootCmd *cobra.Command) *cobra.Command {
	completionCmd := &cobra.Command{
		Use:   "completion",
		Short: "Generate shell completion scripts for trailmix",
		Long: `Generate shell completion scripts for trailmix.

The command for each shell will print a completion script to stdout. You can source this script to get
completions in your current shell session. You can add this script to the completion directory for your
shell to get completions for all future sessions.

For example, to activate bash completions in your current shell:
		$ . <(trailmix completion bash)

To add trailmix completions for all bash sessions:
		$ trailmix completion bash > /etc/bash_completion.d/trailmix_completions`,
	}

	bashCompletionCmd := &cobra.Command{
		Use:   "bash",
		Short: "bash completions for trailmix",
		Run: func(cmd *cobra.Command, args []string) {
			rootCmd.GenBashCompletion(cmd.OutOrStdout())
		},
	}

	zshCompletionCmd := &cobra.Command{
		Use:   "zsh",
		Short: "zsh completions for trailmix",
		Run: func(cmd *cobra.Command, args []string) {
			rootCmd.GenZshCompletion(cmd.OutOrStdout())
		},
	}

	fishCompletionCmd := &cobra.Command{
		Use:   "fish",
		Short: "fish completions for trailmix",
		Run: func(cmd *cobra.Command, args []string) {
			rootCmd.GenFishCompletion(cmd.OutOrStdout(), true)
		},
	}

	powershellCompletionCmd := &cobra.Command{
		Use:   "powershell",
		Short: "powershell completions for trailmix",
		Run: func(cmd *cobra.Command, args []string) {
			rootCmd.GenPowerShellCompletion(cmd.OutOrStdout())
		},
	}

	completionCmd.AddCommand(bashCompletionCmd, zshCompletionCmd, fishCompletionCmd, powershellCompletionCmd)

	return completionCmd
}

func CreateVersionCommand() *cobra.Command {
	versionCmd := &cobra.Command{
		Use:   "version",
		Short: "Print the version of trailmix that you are currently using",
		Run: func(cmd *cobra.Command, args []string) {
			cmd.Println(version.TrailmixVersion)
		},
	}

	return versionCmd
}

func CreateHexCommand() *cobra.Command {
	var outfile, text string
	var red, green, blue, strokeRed, strokeGreen, strokeBlue, textRed, textGreen, textBlue uint
	var alpha, strokeWidth, textSize float32
	hexCmd := &cobra.Command{
		Use:   "hex",
		Short: "SVG rendering of a single hexagon",
		RunE: func(cmd *cobra.Command, args []string) error {
			preamble, err := game.Preamble(game.Boundary.X, game.Boundary.Y)
			if err != nil {
				return err
			}

			hex, err := game.SingleHex(text, 0, 0, red, green, blue, alpha, strokeRed, strokeGreen, strokeBlue, strokeWidth, textRed, textGreen, textBlue, textSize)
			if err != nil {
				return err
			}

			result := preamble + hex + game.SVGEnd

			if outfile != "" {
				writeErr := os.WriteFile(outfile, []byte(result), 0644)
				if writeErr != nil {
					return writeErr
				}
			} else {
				cmd.Println(result)
			}

			return nil
		},
	}

	hexCmd.Flags().StringVarP(&outfile, "outfile", "o", "", "The file to write the SVG output to")
	hexCmd.Flags().UintVarP(&red, "red", "r", 0, "The red component of the fill color")
	hexCmd.Flags().UintVarP(&green, "green", "g", 0, "The green component of the fill color")
	hexCmd.Flags().UintVarP(&blue, "blue", "b", 0, "The blue component of the fill color")
	hexCmd.Flags().Float32VarP(&alpha, "alpha", "a", 1.0, "The opacity of the fill color")
	hexCmd.Flags().UintVar(&strokeRed, "stroke-red", 0, "The red component of the stroke color")
	hexCmd.Flags().UintVar(&strokeGreen, "stroke-green", 0, "The green component of the stroke color")
	hexCmd.Flags().UintVar(&strokeBlue, "stroke-blue", 0, "The blue component of the stroke color")
	hexCmd.Flags().Float32VarP(&strokeWidth, "stroke-width", "w", 0.1, "The width of the stroke")
	hexCmd.Flags().StringVarP(&text, "text", "t", "", "The text to display on the hexagon")
	hexCmd.Flags().UintVarP(&textRed, "text-red", "R", 0, "The red component of the text color")
	hexCmd.Flags().UintVarP(&textGreen, "text-green", "G", 0, "The green component of the text color")
	hexCmd.Flags().UintVarP(&textBlue, "text-blue", "B", 0, "The blue component of the text color")
	hexCmd.Flags().Float32VarP(&textSize, "text-size", "T", 0.5, "The size of the text")

	return hexCmd
}

func CreateBoardCommand() *cobra.Command {
	var outfile string
	var strips, hexesPerStrip, strokeRed, strokeGreen, strokeBlue, start uint
	var strokeWidth float32
	var seed int64
	boardCmd := &cobra.Command{
		Use:   "board",
		Short: "View a portion of the game board for The Degen Trail",
		RunE: func(cmd *cobra.Command, args []string) error {
			yMultiplier := int(strips/2) + 1
			if strips%2 == 0 {
				yMultiplier = int(strips) / 2
			}
			preamble, err := game.Preamble((3*float32(hexesPerStrip)*game.Boundary.X+1)/2, float32(yMultiplier)*game.Boundary.Y)
			if err != nil {
				return err
			}

			hex, err := game.HexagonalGrid(seed, strips, hexesPerStrip, start, strokeRed, strokeGreen, strokeBlue, strokeWidth)
			if err != nil {
				return err
			}

			result := preamble + hex + game.SVGEnd

			if outfile != "" {
				writeErr := os.WriteFile(outfile, []byte(result), 0644)
				if writeErr != nil {
					return writeErr
				}
			} else {
				cmd.Println(result)
			}

			return nil
		},
	}

	boardCmd.Flags().StringVarP(&outfile, "outfile", "o", "", "The file to write the SVG output to")
	boardCmd.Flags().Int64Var(&seed, "seed", 0, "The seed for procedural generation of the grid")
	boardCmd.Flags().UintVarP(&strips, "strips", "s", 1, "The number of horizontal strips to display")
	boardCmd.Flags().UintVarP(&hexesPerStrip, "hexes-per-strip", "p", 1, "The number of hexes to display per strip")
	boardCmd.Flags().UintVarP(&strokeRed, "stroke-red", "R", 0, "The red component of the stroke color")
	boardCmd.Flags().UintVarP(&strokeGreen, "stroke-green", "G", 0, "The green component of the stroke color")
	boardCmd.Flags().UintVarP(&strokeBlue, "stroke-blue", "B", 0, "The blue component of the stroke color")
	boardCmd.Flags().Float32VarP(&strokeWidth, "stroke-width", "w", 0.1, "The width of the stroke")
	boardCmd.Flags().UintVar(&start, "start", 0, "The vertical position of the easternmost hexes")

	return boardCmd
}
