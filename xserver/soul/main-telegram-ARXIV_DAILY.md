# ARXIV_DAILY.md - Daily arXiv Paper Recommendation

## Trigger

System timer runs the wrapper script every day at 7:00 AM JST.

## Topics Covered

The daily report includes papers from these research areas:

- **🤖 LLM Multi-Agent Ecology** - Multi-agent systems, open-endedness, collective intelligence, governance, norms
- **🎭 AI Characters & Personas** - Character AI, personas, virtual characters, NPCs, role-playing systems
- **🧠 AI Memory Design** - Memory architectures, long-term memory, episodic memory, memory-augmented models
- **🧬 Artificial Life (Alife)** - Evolutionary algorithms, self-organization, complex systems, emergence
- **📚 RAG (Retrieval-Augmented Generation)** - Retrieval-augmented LLMs, knowledge retrieval, vector databases

## Action

The systemd timer runs the wrapper script which:

1. Executes: `python3 scripts/arxiv_daily_simple.py`
2. Extracts the JSON message
3. Sends to Telegram using: `openclaw --channel telegram message`

## System Setup

- **Timer:** `/root/.config/systemd/user/arxiv-daily.timer` (runs daily at 7:00 AM JST)
- **Service:** `/root/.config/systemd/user/arxiv-daily.service`
- **Script:** `/root/.openclaw/workspace-telegram/scripts/arxiv_daily_wrapper.sh`
- **Main Script:** `/root/.openclaw/workspace-telegram/scripts/arxiv_daily_simple.py`

## Testing

To test manually:
```bash
python3 /root/.openclaw/workspace-telegram/scripts/arxiv_daily_simple.py 3
```
(The argument specifies number of days to look back)

## Schedule

Every day at 7:00 AM JST (via systemd timer)

```bash
# Check timer status
systemctl --user status arxiv-daily.timer

# View next run time
systemctl --user list-timers arxiv-daily

# Run now (for testing)
systemctl --user start arxiv-daily.service
```
