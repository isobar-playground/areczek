import { tool, type Plugin } from "@opencode-ai/plugin"

export const AreczekTools: Plugin = async () => {
  return {
    tool: {
      areczek_echo: tool({
        description: "Echo a message (sanity check tool wiring)",
        args: {
          message: tool.schema.string().describe("Message to echo back"),
        },
        async execute(args) {
          return args.message
        },
      }),

      areczek_now: tool({
        description: "Return current ISO timestamp",
        args: {},
        async execute() {
          return new Date().toISOString()
        },
      }),
    },
  }
}
