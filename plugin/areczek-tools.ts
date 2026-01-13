import { type Plugin } from "@opencode-ai/plugin"
import jiraSummary from "./jira-summary.ts"

export const AreczekTools: Plugin = async () => {
  return {
    tool: {
      areczek_jira_summary: jiraSummary,
    },
  }
}
