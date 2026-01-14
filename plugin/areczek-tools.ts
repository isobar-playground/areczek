import { type Plugin } from "@opencode-ai/plugin"
import jiraSummary from "../tool/jira-summary.ts"

const AreczekTools: Plugin = async () => {
  return {
    tool: {
      areczek_jira_summary: jiraSummary,
    },
  }
}

export default AreczekTools
