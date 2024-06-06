package main

import (
	"errors"
	"net/http"
	"os"

	"github.com/spf13/cobra"

	"github.com/moonstream-to/degen-trail/bindings/JackpotJunction"
	"github.com/moonstream-to/degen-trail/jj/entropy"
	"github.com/moonstream-to/degen-trail/jj/version"
)

func CreateRootCommand() *cobra.Command {
	// rootCmd represents the base command when called without any subcommands
	rootCmd := &cobra.Command{
		Use:   "jj",
		Short: "jj: The Jackpot Junction CLI",
		Run: func(cmd *cobra.Command, args []string) {
			cmd.Help()
		},
	}

	completionCmd := CreateCompletionCommand(rootCmd)
	versionCmd := CreateVersionCommand()
	entropyCmd := CreateEntropycommand()
	contractCmd := JackpotJunction.CreateJackpotJunctionCommand()
	contractCmd.Use = "contract"
	rootCmd.AddCommand(completionCmd, versionCmd, entropyCmd, contractCmd)

	// By default, cobra Command objects write to stderr. We have to forcibly set them to output to
	// stdout.
	rootCmd.SetOut(os.Stdout)

	return rootCmd
}

func CreateCompletionCommand(rootCmd *cobra.Command) *cobra.Command {
	completionCmd := &cobra.Command{
		Use:   "completion",
		Short: "Generate shell completion scripts for jj",
		Long: `Generate shell completion scripts for jj.

The command for each shell will print a completion script to stdout. You can source this script to get
completions in your current shell session. You can add this script to the completion directory for your
shell to get completions for all future sessions.

For example, to activate bash completions in your current shell:
		$ . <(jj completion bash)

To add jj completions for all bash sessions:
		$ jj completion bash > /etc/bash_completion.d/jj_completions`,
	}

	bashCompletionCmd := &cobra.Command{
		Use:   "bash",
		Short: "bash completions for jj",
		Run: func(cmd *cobra.Command, args []string) {
			rootCmd.GenBashCompletion(cmd.OutOrStdout())
		},
	}

	zshCompletionCmd := &cobra.Command{
		Use:   "zsh",
		Short: "zsh completions for jj",
		Run: func(cmd *cobra.Command, args []string) {
			rootCmd.GenZshCompletion(cmd.OutOrStdout())
		},
	}

	fishCompletionCmd := &cobra.Command{
		Use:   "fish",
		Short: "fish completions for jj",
		Run: func(cmd *cobra.Command, args []string) {
			rootCmd.GenFishCompletion(cmd.OutOrStdout(), true)
		},
	}

	powershellCompletionCmd := &cobra.Command{
		Use:   "powershell",
		Short: "powershell completions for jj",
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
		Short: "Print the version of jj that you are currently using",
		Run: func(cmd *cobra.Command, args []string) {
			cmd.Println(version.JJVersion)
		},
	}

	return versionCmd
}

func CreateEntropycommand() *cobra.Command {
	var rpc, player string
	var samples int

	entropyCmd := &cobra.Command{
		Use:   "entropy",
		Short: "Calculate the entropy of the blockhashes modulo N of a random sample of blocks",
		PreRunE: func(cmd *cobra.Command, args []string) error {
			if rpc == "" {
				return errors.New("--rpc/-r is required")
			}
			if player == "" {
				return errors.New("--player/-p is required")
			}
			if samples == 0 {
				return errors.New("--samples/-s is required")
			}
			return nil
		},
		RunE: func(cmd *cobra.Command, args []string) error {
			client := &http.Client{}
			blocks, blocksErr := entropy.GetRandomBlocks(client, rpc, nil, samples)
			if blocksErr != nil {
				return blocksErr
			}

			itemEntropy, terrainEntropy, outcomeEntropy := entropy.Entropies(blocks, player)

			cmd.Printf("Item entropy: %f\nTerrain entropy: %f\nOutcome entropy: %f\n", itemEntropy, terrainEntropy, outcomeEntropy)

			return nil
		},
	}

	entropyCmd.Flags().StringVarP(&rpc, "rpc", "r", "", "JSON-RPC API URL for the blockchain to sample from")
	entropyCmd.Flags().StringVarP(&player, "player", "p", "", "Player address")
	entropyCmd.Flags().IntVarP(&samples, "samples", "s", 0, "Number of blocks to sample")

	return entropyCmd
}
