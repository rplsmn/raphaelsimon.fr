#!/bin/bash
set -e

# Only provision in web VM
if [ -z "$CLAUDE_CODE_REMOTE" ]; then
  echo "💻 Local environment detected - VM provisioning not needed"
  echo "✅ Hook completed successfully (no action required)"
else
  echo "🚀 Provisioning Claude Code web VM..."

  # ============================================================================
  # 1. GH CONFIGURATION
  # ============================================================================

  bun x gh-setup-hooks

  # ============================================================================
  # 1. GIT CONFIGURATION
  # ============================================================================
  echo ""
  echo "📝 Configuring git for web VM..."
  git config --global user.name "rplsmn (CC)"
  git config --global user.email "74007913+rplsmn@users.noreply.github.com"
  echo "✓ Git configured as: $(git config --global user.name) <$(git config --global user.email)>"

  # ============================================================================
  # 2. FETCH PERSONAL CLAUDE CONFIGURATION
  # ============================================================================
  echo ""
  echo "📥 Fetching personal Claude configuration..."

  CLAUDE_CONFIG_REPO="https://github.com/rplsmn/agent-global-config.git"
  TEMP_CONFIG="/tmp/agent-global-config"

  # Clone personal config repo (shallow clone for speed)
  if git clone --depth 1 "$CLAUDE_CONFIG_REPO" "$TEMP_CONFIG" 2>/dev/null; then
    echo "✓ Personal config fetched"

    # ============================================================================
    # 3. INSTALL SKILLS
    # ============================================================================
    if [ -d "$TEMP_CONFIG/skills" ]; then
      echo ""
      echo "🔧 Installing personal skills..."
      mkdir -p ~/.claude/skills
      cp -r "$TEMP_CONFIG/skills/"* ~/.claude/skills/ 2>/dev/null || true

      INSTALLED_SKILLS=$(ls ~/.claude/skills/ 2>/dev/null | tr '\n' ', ' | sed 's/,$//')
      if [ -n "$INSTALLED_SKILLS" ]; then
        echo "✓ Installed skills: $INSTALLED_SKILLS"
      fi
    fi

    # ============================================================================
    # 4. LOAD GLOBAL INSTRUCTIONS
    # ============================================================================
    if [ -f "$TEMP_CONFIG/docs/global-claude.md" ]; then
      echo ""
      echo "📚 Loading global instructions..."
      # Copy to ~/.claude/ for reference
      mkdir -p ~/.claude/docs
      cp "$TEMP_CONFIG/docs/global-claude.md" ~/.claude/docs/
      echo "✓ Global instructions available at: ~/.claude/docs/global-claude.md"

      # Make available via environment variable
      if [ -n "$CLAUDE_ENV_FILE" ]; then
        echo "export CLAUDE_GLOBAL_DOCS='$HOME/.claude/docs/global-claude.md'" >> "$CLAUDE_ENV_FILE"
      fi
    fi

    # ============================================================================
    # 5. INSTALL BASH TOOLS & ALIASES (optional)
    # ============================================================================
    if [ -f "$TEMP_CONFIG/bash/tools.sh" ]; then
      echo ""
      echo "🛠️  Setting up bash tools..."
      source "$TEMP_CONFIG/bash/tools.sh"
      echo "✓ Bash tools loaded"
    fi

    # Cleanup
    rm -rf "$TEMP_CONFIG"
  else
    echo "⚠️  Could not fetch personal config repo - continuing without personal configs"
    echo "   (Repo may not exist yet or is private without auth)"
  fi

  # ============================================================================
  # 6. INSTALL GLOBAL TOOLS (optional - uncomment what you need)
  # ============================================================================
  # echo ""
  # echo "📦 Installing global tools..."
  # npm install -g prettier eslint typescript
  # pip install --user ruff black mypy

  # ============================================================================
  # 7. SET UP ENVIRONMENT VARIABLES
  # ============================================================================
  if [ -n "$CLAUDE_ENV_FILE" ]; then
    echo ""
    echo "🌍 Configuring environment variables..."
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$CLAUDE_ENV_FILE"
    echo "export GIT_CONFIG_VM_APPLIED=true" >> "$CLAUDE_ENV_FILE"
    echo "✓ Environment configured"
  fi

  echo ""
  echo "✅ VM provisioning complete!"
fi

exit 0
