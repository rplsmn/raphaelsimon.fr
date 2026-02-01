#!/usr/bin/env python3
"""
Obsidian Vault Analyzer - Detects blog-ready topics

This script analyzes an Obsidian vault to find topic clusters mature enough
for blog posts. It uses Claude to assess coherence and readiness.

Usage:
    # Local mode (for Obsidian Sync users)
    python analyze_vault.py --vault ~/Documents/Obsidian/MyVault

    # GitHub Actions mode (vault already checked out)
    python analyze_vault.py --vault ./vault

Environment variables:
    ANTHROPIC_API_KEY - Required for Claude API
    TELEGRAM_BOT_TOKEN - Optional, for Telegram notifications
    TELEGRAM_CHAT_ID - Optional, for Telegram notifications
    DISCORD_WEBHOOK_URL - Optional, for Discord notifications
    NOTIFICATION_EMAIL - Optional, for email (requires SENDGRID_API_KEY)
"""

import argparse
import json
import os
import re
import sys
from collections import defaultdict
from dataclasses import dataclass
from datetime import datetime, timedelta
from pathlib import Path

try:
    import anthropic
except ImportError:
    print("Missing anthropic package. Install with: pip install anthropic")
    sys.exit(1)


@dataclass
class Note:
    path: Path
    title: str
    content: str
    tags: list[str]
    links: list[str]
    word_count: int
    modified: datetime


@dataclass
class TopicCluster:
    name: str
    notes: list[Note]
    total_words: int
    tags: set[str]
    recent_activity: bool


def parse_frontmatter(content: str) -> tuple[dict, str]:
    """Extract YAML frontmatter from markdown content."""
    if not content.startswith("---"):
        return {}, content

    try:
        end = content.index("---", 3)
        frontmatter_str = content[3:end].strip()
        body = content[end + 3:].strip()

        # Simple YAML parsing (avoids pyyaml dependency)
        frontmatter = {}
        for line in frontmatter_str.split("\n"):
            if ":" in line:
                key, value = line.split(":", 1)
                frontmatter[key.strip()] = value.strip().strip('"').strip("'")
        return frontmatter, body
    except ValueError:
        return {}, content


def extract_tags(content: str, frontmatter: dict) -> list[str]:
    """Extract tags from content and frontmatter."""
    tags = []

    # Frontmatter tags
    if "tags" in frontmatter:
        fm_tags = frontmatter["tags"]
        if isinstance(fm_tags, str):
            tags.extend(t.strip() for t in fm_tags.split(","))

    # Inline tags (#tag)
    inline_tags = re.findall(r"(?<!\w)#([a-zA-Z][a-zA-Z0-9_-]*)", content)
    tags.extend(inline_tags)

    return list(set(tags))


def extract_links(content: str) -> list[str]:
    """Extract wiki-style links [[note]] from content."""
    return re.findall(r"\[\[([^\]|]+)", content)


def load_vault(vault_path: Path, folders: list[str] | None = None) -> list[Note]:
    """Load and parse all markdown files from the vault."""
    notes = []

    # Determine which paths to scan
    if folders:
        paths_to_scan = [vault_path / f for f in folders]
    else:
        paths_to_scan = [vault_path]

    for scan_path in paths_to_scan:
        if not scan_path.exists():
            continue

        for md_file in scan_path.rglob("*.md"):
            # Skip hidden files and folders
            if any(part.startswith(".") for part in md_file.parts):
                continue

            try:
                content = md_file.read_text(encoding="utf-8")
            except Exception:
                continue

            frontmatter, body = parse_frontmatter(content)
            tags = extract_tags(content, frontmatter)
            links = extract_links(content)

            # Use frontmatter title or filename
            title = frontmatter.get("title", md_file.stem)

            notes.append(Note(
                path=md_file,
                title=title,
                content=body,
                tags=tags,
                links=links,
                word_count=len(body.split()),
                modified=datetime.fromtimestamp(md_file.stat().st_mtime),
            ))

    return notes


def cluster_notes(notes: list[Note]) -> list[TopicCluster]:
    """Group notes into topic clusters based on tags and links."""
    # Build link graph
    note_by_name = {n.path.stem.lower(): n for n in notes}

    # Cluster by tags first
    tag_clusters: dict[str, list[Note]] = defaultdict(list)
    for note in notes:
        for tag in note.tags:
            tag_clusters[tag.lower()].append(note)

    # Merge clusters that share notes
    clusters = []
    seen_notes = set()

    for tag, tag_notes in sorted(tag_clusters.items(), key=lambda x: -len(x[1])):
        # Skip if all notes already clustered
        new_notes = [n for n in tag_notes if n.path not in seen_notes]
        if len(new_notes) < 2:
            continue

        # Expand cluster via links
        cluster_notes_set = set(new_notes)
        for note in list(cluster_notes_set):
            for link in note.links:
                linked = note_by_name.get(link.lower())
                if linked and linked not in cluster_notes_set:
                    cluster_notes_set.add(linked)

        cluster_notes_list = list(cluster_notes_set)
        total_words = sum(n.word_count for n in cluster_notes_list)

        # Check for recent activity (within last 30 days)
        recent = any(
            n.modified > datetime.now() - timedelta(days=30)
            for n in cluster_notes_list
        )

        all_tags = set()
        for n in cluster_notes_list:
            all_tags.update(n.tags)

        clusters.append(TopicCluster(
            name=tag,
            notes=cluster_notes_list,
            total_words=total_words,
            tags=all_tags,
            recent_activity=recent,
        ))

        for n in cluster_notes_list:
            seen_notes.add(n.path)

    return clusters


def analyze_with_claude(clusters: list[TopicCluster]) -> str:
    """Use Claude to analyze clusters and identify blog-ready topics."""
    if not clusters:
        return "No topic clusters found. Try adding more notes with tags or links."

    # Prepare context for Claude
    cluster_summaries = []
    for i, cluster in enumerate(clusters[:10], 1):  # Limit to top 10
        note_excerpts = []
        for note in cluster.notes[:5]:  # Limit excerpts
            excerpt = note.content[:500] + "..." if len(note.content) > 500 else note.content
            note_excerpts.append(f"  - {note.title}: {excerpt[:200]}...")

        cluster_summaries.append(f"""
Cluster {i}: "{cluster.name}"
- Notes: {len(cluster.notes)} ({', '.join(n.title for n in cluster.notes[:5])})
- Total words: {cluster.total_words}
- Tags: {', '.join(cluster.tags)}
- Recent activity: {'Yes' if cluster.recent_activity else 'No'}
- Excerpts:
{chr(10).join(note_excerpts)}
""")

    prompt = f"""You are analyzing a personal knowledge base to identify topics mature enough for blog posts.

A topic is "mature" and blog-ready when:
- There are 3+ substantive notes on the topic
- Combined content exceeds 1000 words
- There's a clear perspective, argument, or narrative emerging
- The writing shows depth (examples, nuance, not just bullet points)
- Ideally has recent activity (but strong older clusters can qualify)

Here are the topic clusters found:

{"".join(cluster_summaries)}

For each TRULY blog-ready topic (be selective, only the best), provide:
1. Topic title (catchy, blog-appropriate)
2. Number of related notes and word count
3. Why it's ready (1 sentence)
4. Suggested angle or hook for the blog post
5. What's missing (if anything) to make it even stronger

If no topics are truly ready, say so honestly and suggest what would help.

Format your response as a clear, actionable summary the user can act on immediately.
"""

    client = anthropic.Anthropic()
    response = client.messages.create(
        model="claude-sonnet-4-20250514",  # Good balance of quality/cost
        max_tokens=1500,
        messages=[{"role": "user", "content": prompt}],
    )

    return response.content[0].text


def send_telegram(message: str) -> None:
    """Send notification via Telegram."""
    import urllib.request

    token = os.environ.get("TELEGRAM_BOT_TOKEN")
    chat_id = os.environ.get("TELEGRAM_CHAT_ID")

    if not token or not chat_id:
        return

    url = f"https://api.telegram.org/bot{token}/sendMessage"
    data = {
        "chat_id": chat_id,
        "text": message[:4000],  # Telegram limit
        "parse_mode": "Markdown",
    }

    req = urllib.request.Request(
        url,
        data=json.dumps(data).encode(),
        headers={"Content-Type": "application/json"},
    )
    try:
        urllib.request.urlopen(req)
        print("Telegram notification sent.")
    except Exception as e:
        print(f"Failed to send Telegram notification: {e}")


def send_discord(message: str) -> None:
    """Send notification via Discord webhook."""
    import urllib.request

    webhook_url = os.environ.get("DISCORD_WEBHOOK_URL")
    if not webhook_url:
        return

    data = {"content": message[:2000]}  # Discord limit

    req = urllib.request.Request(
        webhook_url,
        data=json.dumps(data).encode(),
        headers={"Content-Type": "application/json"},
    )
    try:
        urllib.request.urlopen(req)
        print("Discord notification sent.")
    except Exception as e:
        print(f"Failed to send Discord notification: {e}")


def main():
    parser = argparse.ArgumentParser(description="Analyze Obsidian vault for blog-ready topics")
    parser.add_argument("--vault", required=True, help="Path to Obsidian vault")
    parser.add_argument("--folders", nargs="+", help="Specific folders to analyze (e.g., thoughts ideas)")
    parser.add_argument("--min-notes", type=int, default=3, help="Minimum notes for a cluster")
    parser.add_argument("--min-words", type=int, default=500, help="Minimum words for a cluster")
    parser.add_argument("--notify", action="store_true", help="Send notifications")
    parser.add_argument("--dry-run", action="store_true", help="Show clusters without Claude analysis")
    args = parser.parse_args()

    vault_path = Path(args.vault).expanduser().resolve()
    if not vault_path.exists():
        print(f"Error: Vault path does not exist: {vault_path}")
        sys.exit(1)

    print(f"Loading vault from: {vault_path}")
    notes = load_vault(vault_path, args.folders)
    print(f"Found {len(notes)} notes")

    if not notes:
        print("No notes found. Check vault path and folders.")
        sys.exit(0)

    print("Clustering notes by tags and links...")
    clusters = cluster_notes(notes)

    # Filter by minimums
    clusters = [
        c for c in clusters
        if len(c.notes) >= args.min_notes and c.total_words >= args.min_words
    ]

    print(f"Found {len(clusters)} significant clusters")

    if not clusters:
        print("No significant topic clusters found.")
        print("Tips: Add more tags to your notes, or link related notes together.")
        sys.exit(0)

    if args.dry_run:
        for c in clusters:
            print(f"\n{c.name}: {len(c.notes)} notes, {c.total_words} words")
            for n in c.notes:
                print(f"  - {n.title}")
        sys.exit(0)

    print("\nAnalyzing with Claude...")
    analysis = analyze_with_claude(clusters)

    print("\n" + "=" * 60)
    print("BLOG READINESS ANALYSIS")
    print("=" * 60)
    print(analysis)
    print("=" * 60)

    if args.notify:
        header = "📝 *Blog Topic Analysis*\n\n"
        send_telegram(header + analysis)
        send_discord("📝 **Blog Topic Analysis**\n\n" + analysis)

    # Set GitHub Actions output
    if os.environ.get("GITHUB_OUTPUT"):
        with open(os.environ["GITHUB_OUTPUT"], "a") as f:
            # Escape for GH Actions
            escaped = analysis.replace("%", "%25").replace("\n", "%0A").replace("\r", "%0D")
            f.write(f"analysis={escaped}\n")


if __name__ == "__main__":
    main()
