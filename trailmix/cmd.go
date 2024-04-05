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
	rootCmd.AddCommand(completionCmd, versionCmd, boardCmd)

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

func CreateBoardCommand() *cobra.Command {
	var outfile string
	var strips, hexesPerStrip, red, green, blue, strokeRed, strokeGreen, strokeBlue uint
	var alpha, strokeWidth float32
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

			hex, err := game.HexagonalGrid(strips, hexesPerStrip, red, green, blue, alpha, strokeRed, strokeGreen, strokeBlue, strokeWidth)
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
	boardCmd.Flags().UintVarP(&strips, "strips", "s", 1, "The number of horizontal strips to display")
	boardCmd.Flags().UintVarP(&hexesPerStrip, "hexes-per-strip", "p", 1, "The number of hexes to display per strip")
	boardCmd.Flags().UintVarP(&red, "red", "r", 0, "The red component of the fill color")
	boardCmd.Flags().UintVarP(&green, "green", "g", 0, "The green component of the fill color")
	boardCmd.Flags().UintVarP(&blue, "blue", "b", 0, "The blue component of the fill color")
	boardCmd.Flags().Float32VarP(&alpha, "alpha", "a", 1.0, "The opacity of the fill color")
	boardCmd.Flags().UintVarP(&strokeRed, "stroke-red", "R", 0, "The red component of the stroke color")
	boardCmd.Flags().UintVarP(&strokeGreen, "stroke-green", "G", 0, "The green component of the stroke color")
	boardCmd.Flags().UintVarP(&strokeBlue, "stroke-blue", "B", 0, "The blue component of the stroke color")
	boardCmd.Flags().Float32VarP(&strokeWidth, "stroke-width", "w", 0.1, "The width of the stroke")

	return boardCmd
}
